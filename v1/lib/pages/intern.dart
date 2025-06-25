import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import 'dart:convert';

import 'package:v1/services/llm.dart';
import 'package:v1/services/tools.dart' as tools;

class InternPage extends StatefulWidget {
  @override
  _InternPageState createState() => _InternPageState();
}

class _InternPageState extends State<InternPage> {
  // Utility to extract first JSON object containing a given key from text
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
  final ChatUser _user = ChatUser(id: 'user');
  final ChatUser _assistant = ChatUser(id: 'intern', firstName: 'Intern');

  final List<ChatMessage> _messages = [];
  final LlmService _llm = LlmService();
  Stopwatch? _reqSW; // stopwatch for current request

  // Keep track of which message indexes hold the transient "thinking" and answer chunks.
  int? _thinkingIdx;
  int? _runningIdx; // index of current running tool status bubble
  int? _answerIdx;
  int? _reflectionAnswerIdx;
  StreamSubscription<LlmStreamEvent>? _llmSub;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intern Agent'),
      ),
      body: DashChat(
        currentUser: _user,
        messages: _messages,
        onSend: _onSend,
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            hintText: 'Ask Intern to do something…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
        ),
        messageOptions: MessageOptions(
          messageTextBuilder: (msg, prev, next) {
            if (msg.customProperties?['thinking'] == true) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planning / Executing…', style: TextStyle(fontWeight: FontWeight.bold)),
                  MarkdownBody(data: msg.text, selectable: true),
                ],
              );
            }
            return MarkdownBody(data: msg.text, selectable: true);
          },
          messageDecorationBuilder: (msg, prev, next) {
            if (msg.customProperties?['thinking'] == true) {
              return BoxDecoration(color: Theme.of(context).colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(18));
            }
            return BoxDecoration(
              color: msg.user.id == _user.id ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSend(ChatMessage userMsg) async {
    _reqSW = Stopwatch()..start();
    print('[Intern] User prompt: \\${userMsg.text}');
    setState(() => _messages.insert(0, userMsg));

    // cancel previous stream if exists
    await _llmSub?.cancel();

    // Step-1: create planning prompt
    final system = {
      'role': 'system',
      'content': _buildSystemPrompt(),
    };

    final msgsForPlan = [system, {'role': 'user', 'content': userMsg.text}];

    final planStart = DateTime.now();
    _llmSub = _llm.getAIResponse(msgsForPlan).listen((event) {
      setState(() {
        switch (event.type) {
          case LlmStreamEventType.thinking:
            _updateThinking(event.content);
            break;
          case LlmStreamEventType.response:
            _updateAnswerChunk(event.content);
            break;
          case LlmStreamEventType.fullResponse:
            print('[Intern][TIMING] Plan generation took: ${DateTime.now().difference(planStart).inMilliseconds} ms');
            _completePlan(event.content, userMsg.text);
            break;
          case LlmStreamEventType.error:
            _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: 'Error: ${event.content}'));
            break;
        }
      });
    });
  }

  // BUILD SYSTEM PROMPT WITH TOOLS
  String _buildSystemPrompt() {
    return '''You are Intern, a task-oriented AI agent that can execute tools to help the user.
Available tools (Dart functions you can call):
1. search(query: String) -> String : Performs a web search and returns the top result.
2. sendEmail(recipient: String (email address of recipient), subject: String, body: String) -> void : Sends an email.
3. getTodayDate() -> String : Returns today's date.

Follow the "Luna Agent: Spec v5 (Reactive Workflow)". First generate a plan as JSON {"plan": [<tool names>]}. Then for each step, reply with {"params":{...}} for the current tool. Wrap ANY free-form explanation inside <think>...</think> tags so the UI can show it separately.''';
  }

  // Helper to show planning / thinking content
  void _updateThinking(String chunk) {
    if (_thinkingIdx == null) {
      print('[Intern] Thinking chunk: $chunk');
      _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: chunk, customProperties: {'thinking': true}));
      _thinkingIdx = 0;
    } else {
      final old = _messages[_thinkingIdx!];
      _messages[_thinkingIdx!] = ChatMessage(user: _assistant, createdAt: old.createdAt, text: chunk, customProperties: {'thinking': true});
    }
  }

  // Helper to show response chunk
  void _updateAnswerChunk(String chunk) {
    if (_answerIdx == null) {
      print('[Intern] Assistant chunk: $chunk');
      _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: chunk));
      _answerIdx = 0;
    } else {
      final old = _messages[_answerIdx!];
      _messages[_answerIdx!] = ChatMessage(user: _assistant, createdAt: old.createdAt, text: chunk);
    }
  }

  void _updateReflectionAnswerChunk(String chunk) {
    if (_reflectionAnswerIdx == null) {
      // First chunk, create new message
      _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: chunk));
      _reflectionAnswerIdx = 0;
    } else {
      // Subsequent chunks, update existing message
      final old = _messages[_reflectionAnswerIdx!];
      _messages[_reflectionAnswerIdx!] = ChatMessage(
        user: old.user,
        createdAt: old.createdAt,
        text: old.text + chunk,
        customProperties: old.customProperties,
      );
    }
  }

  void _completePlan(String fullJson, String originalUserText) async {
    // Convert planning bubble to normal assistant message instead of removing it
    if (_thinkingIdx != null) {
      final oldPlanMsg = _messages[_thinkingIdx!];
      _messages[_thinkingIdx!] = ChatMessage(user: _assistant, createdAt: oldPlanMsg.createdAt, text: oldPlanMsg.text);
    }

    // Parse plan JSON (may arrive multi-line)
    Map<String, dynamic>? decoded = _extractJsonWithKey(fullJson, 'plan');

    if (decoded != null) {
      print('[Intern] Plan decoded: \\${jsonEncode(decoded['plan'])}');
    }

    if (decoded == null || decoded['plan'] == null) {
      // Not JSON plan, just treat as regular answer
      _updateAnswerChunk(fullJson);
      return;
    }

    final List<dynamic> plan = decoded['plan'];
    dynamic prevResult;
    final List<Map<String, String>> toolOutputs = [];
    for (final step in plan) {
      final toolName = step.toString();
      // Ask for params
      final paramPrompt = [
        {
          'role': 'system',
          'content': _buildSystemPrompt(),
        },
        {
          'role': 'user',
          'content': originalUserText,
        },
        {
          'role': 'assistant',
          'content': jsonEncode({'plan': plan}),
        },
        if (prevResult != null)
          {
            'role': 'system',
            'content': 'Previous Step Result ($toolName): $prevResult',
          },
        {
          'role': 'system',
          'content': 'Current Tool: $toolName',
        }
      ];

      // --- Generate parameters for this tool ---
      final paramStart = DateTime.now();
      print('[Intern] Requesting params for $toolName with prompt:');
      for (var m in paramPrompt) {
        print('  ' + m['role']! + ': ' + (m['content'] as String).replaceAll('\n', ' '));
      }
      // synchronous request for params (still uses streaming endpoint but we wait until done)
      final paramResp = await _llm.getAIResponse(paramPrompt).lastWhere((e) => e.type == LlmStreamEventType.fullResponse);
      final paramDuration = DateTime.now().difference(paramStart).inMilliseconds;
      print('[Intern][TIMING] Param generation for $toolName took: ${paramDuration} ms');
      print('[Intern] raw param response: '+paramResp.content);
      final paramJson = _extractJsonWithKey(paramResp.content, 'params');
      if (paramJson == null) {
        _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: 'Failed to parse params for $toolName.'));
        continue;
      }
      final params = paramJson['params'] as Map<String, dynamic>?;
      if (params == null) {
        _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: 'No params for $toolName.'));
        return;
      }

      // log tool execution
      final paramStr = jsonEncode(params);
      print('[Intern] Running $toolName with params: $paramStr');
      _messages.insert(0, ChatMessage(
        user: _assistant,
        createdAt: DateTime.now(),
        text: '▶️ **Running `$toolName`**\n```json\n$paramStr\n```',
        customProperties: {'thinking': true},
      ));
      _runningIdx = 0; // newly inserted at index 0

      // execute tool
      final toolStartMs = DateTime.now().millisecondsSinceEpoch;
      try {
        switch (toolName) {
          case 'search':
            print('tool activate - search');
            prevResult = await tools.search(params['query'] as String);
            print('tool finished - search');
            break;
          case 'send_email':
          case 'sendEmail':
            await tools.sendEmail(
              recipient: params['recipient'],
              subject: params['subject'],
              body: params['body'],
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
        prevResult = 'Error while executing $toolName: $e';
      }

      final toolDur = DateTime.now().millisecondsSinceEpoch - toolStartMs;
      print('[Intern][TIMING] $toolName execution took ${toolDur} ms');

      // Update running status bubble to finished
      if (_runningIdx != null) {
        final oldRun = _messages[_runningIdx!];
        _messages[_runningIdx!] = ChatMessage(user: _assistant, createdAt: oldRun.createdAt, text: '✅ **$toolName** executed.');
        _runningIdx = null;
      }

      print('[Intern] Result of $toolName: $prevResult');
      // record output
      toolOutputs.add({'tool': toolName, 'result': prevResult.toString()});
      // show intermediate result in chat
      _messages.insert(0, ChatMessage(user: _assistant, createdAt: DateTime.now(), text: '**[$toolName]** $prevResult'));
    }

    // --- Ask LLM to reflect and craft final answer (streaming) ---
    final reflectStart = DateTime.now();
    final reflectionPrompt = [
      {'role': 'system', 'content': _buildSystemPrompt()},
      {'role': 'user', 'content': originalUserText},
      {
        'role': 'assistant',
        'content': jsonEncode({'plan': plan})
      },
      ...toolOutputs.map((e) => {'role': 'system', 'content': jsonEncode(e)}),
      {
        'role': 'system',
        'content': 'All tools have finished. Provide a concise final answer to the user based on the tool outputs.'
      }
    ];

    // Stream reflection answer
    _llm.getAIResponse(reflectionPrompt).listen((event) {
      setState(() {
        switch (event.type) {
          case LlmStreamEventType.response:
            _updateReflectionAnswerChunk(event.content);
            break;
          case LlmStreamEventType.fullResponse:
            print('[Intern][TIMING] Reflection (stream) took: ${DateTime.now().difference(reflectStart).inMilliseconds} ms');
            if (_reqSW != null) {
              _reqSW!.stop();
              print('[Intern][TIMING] Full request took: ${_reqSW!.elapsed.inMilliseconds} ms');
              _reqSW = null;
            }
            break;
          case LlmStreamEventType.thinking:
            // Not shown for reflection
            break;
          case LlmStreamEventType.error:
            _updateReflectionAnswerChunk('Error: ${event.content}');
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _llmSub?.cancel();
    super.dispose();
  }
}
