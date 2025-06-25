import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:v1/services/llm.dart';
import 'package:v1/services/tools.dart' as tools;

/// A very small UI to run a single task through the same
/// plan->params->tool->reflect algorithm that `InternPage` uses, but
/// without the chat interface – just a text field and a button.
class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final List<String> _outputs = [];
  final LlmService _llm = LlmService();

  // Indexes to keep track of in-progress streaming entries
  int? _thinkingIdx;
  int? _reflectionIdx;

  StreamSubscription<LlmStreamEvent>? _planSub;
  StreamSubscription<LlmStreamEvent>? _reflectSub;

  /// Convenience util used by InternPage – copies here verbatim.
  Map<String, dynamic>? _extractJsonWithKey(String text, String key) {
    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final obj = jsonDecode(trimmed) as Map<String, dynamic>;
        if (obj.containsKey(key)) return obj;
      } catch (_) {}
    }
    return null;
  }

  /// Same system prompt that InternPage currently builds.
  String _buildSystemPrompt() {
    return '''You are Intern, a task-oriented AI agent that can execute tools to help the user.
Available tools (Dart functions you can call):
1. search(query: String) -> String : Performs a web search and returns the top result.
2. sendEmail(recipient: String (email address of recipient), subject: String, body: String) -> void : Sends an email.
3. getTodayDate() -> String : Returns today's date.

Follow the "Luna Agent: Spec v5 (Reactive Workflow)". First generate a plan as JSON {"plan": [<tool names>]}. Then for each step, reply with {"params":{...}} for the current tool. Wrap ANY free-form explanation inside <think>...</think> tags so the UI can show it separately.''';
  }

  Future<void> _runTask(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      _outputs.clear();
      _outputs.add('User: $userText');
    });

    final reqSW = Stopwatch()..start();

    // Build conversation history for proper reflection
    final List<Map<String, String>> conversationHistory = [
      {'role': 'system', 'content': _buildSystemPrompt()},
      {'role': 'user', 'content': userText},
    ];

    // ============= STEP 1 – PLAN (streaming) =============
    final planStart = DateTime.now();
    final planPrompt = List<Map<String, String>>.from(conversationHistory);
    
    // Listen to plan stream so we can surface thinking / JSON chunks live
    final planCompleter = Completer<String>();
    final StringBuffer planBuf = StringBuffer();
    _planSub = _llm.getAIResponse(planPrompt).listen((event) {
      setState(() {
        switch (event.type) {
          case LlmStreamEventType.thinking:
            if (_thinkingIdx == null) {
              _outputs.add('[Planning…] ${event.content}');
              _thinkingIdx = _outputs.length - 1;
            } else {
              _outputs[_thinkingIdx!] = '[Planning…] ${event.content}';
            }
            break;
          case LlmStreamEventType.response:
            // Accumulate chunks without spamming UI
            planBuf.write(event.content);
            break;
          case LlmStreamEventType.fullResponse:
            planBuf.write(event.content);
            planCompleter.complete(planBuf.toString());
            break;
          case LlmStreamEventType.error:
            _outputs.add('[Error] ${event.content}');
            planCompleter.completeError(event.content);
            break;
        }
      });
    });

    final planRespStr = await planCompleter.future;
    await _planSub?.cancel();
    final planJson = _extractJsonWithKey(planRespStr, 'plan');
    final planDur = DateTime.now().difference(planStart).inMilliseconds;
    if (planJson == null || planJson['plan'] == null) {
      setState(() => _outputs.add('[Error] Could not parse plan. Raw: $planRespStr'));
      return;
    }
    final List<dynamic> plan = planJson['plan'];
    setState(() => _outputs.add('Plan (${planDur}ms): ${jsonEncode(plan)}'));

    // Add plan response to conversation history
    conversationHistory.add({'role': 'assistant', 'content': planRespStr});

    // ============= STEP 2 – EXECUTE EACH TOOL =============
    dynamic prevResult;

    for (final step in plan) {
      final toolName = step.toString();

      // ---- params (streaming) ----
      final paramPrompt = List<Map<String, String>>.from(conversationHistory);
      if (prevResult != null) {
        paramPrompt.add({'role': 'system', 'content': 'Previous Step Result: $prevResult'});
      }
      paramPrompt.add({'role': 'system', 'content': 'Current Tool: $toolName'});
      
      final paramStart = DateTime.now();
      final Completer<Map<String, dynamic>?> paramCompleter = Completer();
      final StringBuffer paramBuf = StringBuffer();
      int? paramThinkingIdx;
      _llm.getAIResponse(paramPrompt).listen((event) {
        setState(() {
          switch (event.type) {
            case LlmStreamEventType.thinking:
              if (paramThinkingIdx == null) {
                _outputs.add('[Params $toolName thinking] ${event.content}');
                paramThinkingIdx = _outputs.length - 1;
              } else {
                _outputs[paramThinkingIdx!] = '[Params $toolName thinking] ${event.content}';
              }
              break;
            case LlmStreamEventType.response:
              paramBuf.write(event.content);
              break;
            case LlmStreamEventType.fullResponse:
              paramBuf.write(event.content);
              final paramJson = _extractJsonWithKey(paramBuf.toString(), 'params');
              if (paramJson == null) {
                _outputs.add('[Error] Failed to parse params for $toolName.');
                paramCompleter.complete(null);
              } else {
                paramCompleter.complete(paramJson['params'] as Map<String, dynamic>?);
              }
              break;
            case LlmStreamEventType.error:
              _outputs.add('[Error] ${event.content}');
              paramCompleter.complete(null);
              break;
          }
        });
      });

      final params = await paramCompleter.future;
      final paramDur = DateTime.now().difference(paramStart).inMilliseconds;
      if (params == null) return;
      setState(() => _outputs.add('Params for $toolName (${paramDur}ms): ${jsonEncode(params)}'));

      // Add params response to conversation history
      final paramResponse = paramBuf.toString();
      conversationHistory.add({'role': 'assistant', 'content': paramResponse});

      // ---- execute ----
      final execSW = Stopwatch()..start();
      try {
        switch (toolName) {
          case 'search':
            prevResult = await tools.search(params?['query'] as String);
            break;
          case 'sendEmail':
          case 'send_email':
            await tools.sendEmail(
              recipient: params?['recipient'],
              subject: params?['subject'],
              body: params?['body'],
            );
            prevResult = 'Email sent successfully.';
            break;
          case 'getTodayDate':
            prevResult = tools.getTodayDate();
            break;
          default:
            prevResult = 'Unknown tool $toolName';
        }
      } catch (e) {
        prevResult = 'Error executing $toolName: $e';
      }
      execSW.stop();
      setState(() => _outputs.add('Result of $toolName (${execSW.elapsedMilliseconds}ms): $prevResult'));

      // Add tool result to conversation history as a system message
      conversationHistory.add({'role': 'system', 'content': 'Tool result for $toolName: $prevResult'});
    }

    // ============= STEP 3 – REFLECT & ANSWER (streaming) =============
    // Now ask the LLM to provide a final answer based on all the tool results
    final reflectPrompt = List<Map<String, String>>.from(conversationHistory);
    reflectPrompt.add({
      'role': 'system', 
      'content': 'All tools have been executed. Now provide a comprehensive final answer to the user\'s original question based on all the tool results you received.'
    });

    final reflectStart = DateTime.now();
    final reflectBuf = StringBuffer();
    final reflectCompleter = Completer<void>();
    _reflectionIdx = null;
    _reflectSub = _llm.getAIResponse(reflectPrompt).listen((event) {
      setState(() {
        switch (event.type) {
          case LlmStreamEventType.thinking:
            // We don't expect thinking during reflection, but handle it if it occurs
            if (_reflectionIdx == null) {
              _outputs.add('[Reflecting…] ${event.content}');
              _reflectionIdx = _outputs.length - 1;
            } else {
              _outputs[_reflectionIdx!] = '[Reflecting…] ${event.content}';
            }
            break;
          case LlmStreamEventType.response:
            reflectBuf.write(event.content);
            if (_reflectionIdx == null) {
              _outputs.add('Final Answer: ${event.content}');
              _reflectionIdx = _outputs.length - 1;
            } else {
              _outputs[_reflectionIdx!] = 'Final Answer: ${reflectBuf.toString()}';
            }
            break;
          case LlmStreamEventType.fullResponse:
            reflectBuf.write(event.content);
            if (_reflectionIdx == null) {
              _outputs.add('Final Answer: ${event.content}');
            } else {
              _outputs[_reflectionIdx!] = 'Final Answer: ${reflectBuf.toString()}';
            }
            final dur = DateTime.now().difference(reflectStart).inMilliseconds;
            _outputs.add('Final answer ready (${dur}ms)');
            reflectCompleter.complete();
            break;
          case LlmStreamEventType.error:
            _outputs.add('[Error] ${event.content}');
            reflectCompleter.complete();
            break;
        }
      });
    });

    await reflectCompleter.future;
    await _reflectSub?.cancel();

    reqSW.stop();
    setState(() => _outputs.add('Total time: ${reqSW.elapsedMilliseconds}ms'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Runner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _inputCtrl,
              decoration: const InputDecoration(labelText: 'Enter task...'),
              onSubmitted: _runTask,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _runTask(_inputCtrl.text),
              child: const Text('Submit'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _outputs.length,
                itemBuilder: (context, idx) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(_outputs[idx]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _planSub?.cancel();
    _reflectSub?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }
}