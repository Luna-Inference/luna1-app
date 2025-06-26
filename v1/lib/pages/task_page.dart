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

  // Persist conversation history across tasks to give the LLM "memory"
  final List<Map<String, String>> _convHistory = [];

  /// Extracts a JSON object with a given key from text (legacy, for plan).
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

  /// Extracts a tool call JSON of the form {"name": ..., "parameters": {...}} from text.
  Map<String, dynamic>? _extractToolCallJson(String text) {
    // Try to find the first valid tool call JSON in the text
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final obj = jsonDecode(trimmed) as Map<String, dynamic>;
        if (obj.containsKey('name') && obj.containsKey('parameters')) {
          return obj;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Same system prompt that InternPage currently builds.
  String _buildSystemPrompt() {
    return '''# Tool Call Test Prompt

## Available Tools
You are Luna, a seductive assistant.
You have access to the following tools:

**search(query)**
- Performs a web search and returns the top result
- Parameters: `query` (String) - The search term
- Returns: String content from search results

**sendEmail(recipient, subject, body)**  
- Sends an email to a specified recipient
- Parameters: 
  - `recipient` (String) - Email address to send to
  - `subject` (String) - Email subject line (optional, defaults to "Message from Luna")
  - `body` (String) - Email content
- Returns: None (confirms email sent)

**getTodayDate()**
- Returns today's date in YYYY-MM-DD format
- Parameters: None
- Returns: String date in YYYY-MM-DD format

## Output Format

When you need to use a tool, you MUST format your response exactly as follows:

```
[Brief explanation of what you're doing]

{"name": "toolName", "parameters": {"param1": "value1", "param2": "value2"}}
```
''';
  }

  Future<void> _runTask(String userText) async {
    if (userText.trim().isEmpty) return;

    setState(() {
      _outputs.clear();
      _outputs.add('User: $userText');
    });

    // Build / update persistent conversation memory
    if (_convHistory.isEmpty) {
      _convHistory.add({'role': 'user', 'content': _buildSystemPrompt()});
    }
    _convHistory.add({'role': 'user', 'content': _buildSystemPrompt()});
    _convHistory.add({'role': 'user', 'content': userText});

    final reqSW = Stopwatch()..start();

    // Use a copy of persisted history so we don't add internal metadata back into memory
    final List<Map<String, String>> conversationHistory = List<Map<String, String>>.from(_convHistory);

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
      setState(
        () => _outputs.add('[Error] Could not parse plan. Raw: $planRespStr'),
      );
      return;
    }
    final List<dynamic> plan = planJson['plan'];
    setState(() => _outputs.add('Plan (${planDur}ms): ${jsonEncode(plan)}'));

    // Add plan response to conversation history
    conversationHistory.add({'role': 'assistant', 'content': planRespStr});

    // ============= STEP 2 – EXECUTE EACH TOOL =============
    // Collect results for reflection summary
    final List<String> _toolResults = [];
    dynamic prevResult;

    for (final step in plan) {
      final toolName = step.toString();

      // ---- params (streaming) ----
      final paramPrompt = List<Map<String, String>>.from(conversationHistory);
      if (prevResult != null) {
        paramPrompt.add({
          'role': 'system',
          'content': 'Previous Step Result: $prevResult',
        });
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
                _outputs[paramThinkingIdx!] =
                    '[Params $toolName thinking] ${event.content}';
              }
              break;
            case LlmStreamEventType.response:
              paramBuf.write(event.content);
              break;
            case LlmStreamEventType.fullResponse:
              paramBuf.write(event.content);
              final toolCall = _extractToolCallJson(paramBuf.toString());
              if (toolCall == null || toolCall['name'] != toolName) {
                _outputs.add('[Error] Failed to parse tool call for $toolName.');
                paramCompleter.complete(null);
              } else {
                paramCompleter.complete(toolCall['parameters'] as Map<String, dynamic>?);
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
      setState(
        () => _outputs.add(
          'Params for $toolName (${paramDur}ms): ${jsonEncode(params)}',
        ),
      );

      // Add params assistant response only to THIS run's history copy, not global memory
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
      setState(() {
        // Show generic result line
        _outputs.add('Result of $toolName (${execSW.elapsedMilliseconds}ms): $prevResult');
        // Also surface as a Computer message so the user sees the raw output distinctly
        _outputs.add('Computer: $prevResult');
      });

      // Save for reflection summary
      _toolResults.add('$toolName => $prevResult');

      // Add tool result to conversation history as a system message
      conversationHistory.add({
        'role': 'system',
        'content': 'Tool result for $toolName: $prevResult',
      });
    }

    // ============= STEP 3 – REFLECT & ANSWER (streaming) =============
    // Now ask the LLM to provide a final answer based on all the tool results
    final reflectPrompt = List<Map<String, String>>.from(conversationHistory);
    // Provide explicit summary of tool outputs for better reflection
    reflectPrompt.add({
      'role': 'system',
      'content':
          'All tools have been executed. Here is a summary of each tool\'s output:\n${_toolResults.join('\n')}\n\nNow provide a comprehensive final answer or status updates to the user\'s original question based on these results.',
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
              _outputs[_reflectionIdx!] =
                  'Final Answer: ${reflectBuf.toString()}';
            }
            break;
          case LlmStreamEventType.fullResponse:
            reflectBuf.write(event.content);
            if (_reflectionIdx == null) {
              _outputs.add('Final Answer: ${event.content}');
            } else {
              _outputs[_reflectionIdx!] =
                  'Final Answer: ${reflectBuf.toString()}';
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

    // Save assistant reflection to memory
    _convHistory.add({'role': 'assistant', 'content': reflectBuf.toString()});

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
                itemBuilder:
                    (context, idx) => Padding(
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
