import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:v1/services/chat_persona.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:v1/services/llm.dart';
import 'package:v1/services/files.dart';
import 'package:v1/services/tools.dart';
import 'package:v1/widgets/setting_appbar.dart';

class AgentPage extends StatefulWidget {
  @override
  _AgentPageState createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {

  late final LlmService _llmService;

  @override
  void initState() {
    super.initState();
    _llmService = LlmService();

  }



  @override
  void dispose() {
    _llmSubscription?.cancel();
    super.dispose();
  }

  /// Same system prompt as TaskPage for tool calling.
  String _buildSystemPrompt() {
    return '''# Tool Call Test Prompt

## Available Tools

You have access to the following tools:

**search(query)**
- Performs a web search and returns the top result
- Parameters: 
  - `query` (String) - The search term
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

**addNote(content)**
- Adds a new line of text to a specified Notion page.
- Parameters:
  - `content` (String) - The text content to add.
- Returns: String confirmation message.

## Output Format

When you need to use a tool, you MUST format your response exactly as follows:

```
[Brief explanation of what you're doing]

{"name": "toolName", "parameters": {"param1": "value1", "param2": "value2"}}

## Examples

**Example 1: Using the search tool**

```
Looking up the current weather in Paris.

{"name": "search", "parameters": {"query": "current weather in Paris"}}
```

**Example 2: Using the sendEmail tool**

```
Sending your requested email.

{"name": "sendEmail", "parameters": {"recipient": "jane@example.com", "subject": "Hello from Luna", "body": "Hi Jane, just checking in!"}}
```

**Example 3: Using the getTodayDate tool**

```
Getting today's date.

{"name": "getTodayDate", "parameters": {}}
```

```
''';
  }

  List<ChatMessage> messages = [];

  StreamSubscription<LlmStreamEvent>? _llmSubscription;
  int? _thinkingMsgIndex;
  int? _answerMsgIndex;
  final FileService _fileService = FileService();
  final List<String> _pdfContexts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SettingAppBar(title: 'Luna Agent'),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: DashChat(
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: 'Type a message...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2.0,
              ),
            ),
            prefixIcon: IconButton(
              icon: Icon(
                Icons.attach_file,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _attachPdf,
            ),
          ),
          sendButtonBuilder: (void Function()? onPressed) {
            return IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: onPressed,
            );
          },
        ),
        
        messageOptions: MessageOptions(
          messageTextBuilder: (message, previous, next) {
            if (message.customProperties?['thinking'] == true) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'Thinking...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  MarkdownBody(data: message.text, selectable: true),
                ],
              );
            }
            return MarkdownBody(data: message.text, selectable: true);
          },
          messageDecorationBuilder: (message, previous, next) {
            if (message.customProperties != null &&
                message.customProperties!['thinking'] == true) {
              return BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              );
            }
            return BoxDecoration(
              color:
                  message.user.id == user.id
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            );
          },
        ),
        currentUser: user,
        onSend: (ChatMessage m) async {
          setState(() {
            messages.insert(0, m);
            _thinkingMsgIndex = null;
            _answerMsgIndex = null;
          });

          // Cancel any existing LLM stream subscription
          // _llmSubscription?.cancel();

          final apiMessages = _convertMessagesToApi(messages);
          // Debug log
          print(
            '[LLM] Sending first messages: \\${jsonEncode(apiMessages.take(3).toList())}',
          );

          _llmSubscription = _llmService.getAIResponse(apiMessages).listen((
            event,
          ) {
            setState(() {
              switch (event.type) {
                case LlmStreamEventType.thinking:
                  if (_thinkingMsgIndex == null) {
                    messages.insert(
                      0,
                      ChatMessage(
                        user: luna,
                        createdAt: DateTime.now(),
                        text: event.content,
                        customProperties: {'thinking': true},
                      ),
                    );
                    _thinkingMsgIndex = 0;
                  } else {
                    final oldMsg = messages[_thinkingMsgIndex!];
                    messages[_thinkingMsgIndex!] = ChatMessage(
                      user: luna,
                      createdAt: oldMsg.createdAt,
                      text: event.content,
                      customProperties: {'thinking': true},
                    );
                  }
                  break;
                case LlmStreamEventType.response:
                  if (_answerMsgIndex == null) {
                    messages.insert(
                      0,
                      ChatMessage(
                        user: luna,
                        createdAt: DateTime.now(),
                        text: event.content,
                      ),
                    );
                    _answerMsgIndex = 0;
                  } else {
                    final oldMsg = messages[_answerMsgIndex!];
                    messages[_answerMsgIndex!] = ChatMessage(
                      user: luna,
                      createdAt: oldMsg.createdAt,
                      text: event.content,
                    );
                  }
                  break;
                case LlmStreamEventType.fullResponse:
                  if (_answerMsgIndex != null) {
                    final oldMsg = messages[_answerMsgIndex!];
                    messages[_answerMsgIndex!] = ChatMessage(
                      user: luna,
                      createdAt: oldMsg.createdAt,
                      text: event.content,
                    );

                    final hasTool = _hasToolTag(event.content);
                    if (hasTool) {
                      final toolCall = _extractToolCallJson(event.content);
                      if (toolCall != null) {
                        _executeTool(toolCall).then((toolOutput) {
                          setState(() {
                            messages.insert(
                              0,
                              ChatMessage(
                                user: computer,
                                createdAt: DateTime.now(),
                                text:
                                    toolOutput ??
                                    'Tool executed with no output.',
                              ),
                            );
                          });
                        });
                      } else {
                        messages.insert(
                          0,
                          ChatMessage(
                            user: computer,
                            createdAt: DateTime.now(),
                            text:
                                'Tool call detected but could not parse JSON.',
                          ),
                        );
                      }
                    } else {
                      messages.insert(
                        0,
                        ChatMessage(
                          user: computer,
                          createdAt: DateTime.now(),
                          text: 'No tool tag found',
                        ),
                      );
                    }
                  }
                  break;
                case LlmStreamEventType.error:
                  messages.insert(
                    0,
                    ChatMessage(
                      user: luna,
                      createdAt: DateTime.now(),
                      text: 'Error: ${event.content}',
                    ),
                  );
                  break;
              }
            });
          });
        },
        messages: messages,
      ),
    );
  }

  bool _hasToolTag(String str) {
    // Detects a JSON object with both 'name' and 'parameters' keys anywhere in the string
    final regex = RegExp(
      r'\{[^\}]*"name"\s*:\s*"[^"]+"[^\}]*"parameters"\s*:\s*\{[^\}]*\}[^"]*\}',
      dotAll: true,
    );
    return regex.hasMatch(str);
  }

  // Extracts the first tool call JSON object from a string
  Map<String, dynamic>? _extractToolCallJson(String text) {
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

  // Executes the tool call and returns the output as a Future<String?>
  Future<String?> _executeTool(Map<String, dynamic> toolCall) async {
    try {
      final name = toolCall['name'] as String;
      final params = toolCall['parameters'] as Map<String, dynamic>;
      if (name == 'search') {
        final query = params['query'] as String?;
        if (query == null) return 'Missing query parameter for search.';
        final result = await search(query);
        return 'Search result: $result';
      } else if (name == 'sendEmail') {
        final recipient = params['recipient'] as String?;
        final subject = params['subject'] as String? ?? 'Message from Luna';
        final body = params['body'] as String?;
        if (recipient == null || body == null)
          return 'Missing recipient or body for sendEmail.';
        await sendEmail(recipient: recipient, subject: subject, body: body);
        return 'Email sent to $recipient.';
      } else if (name == 'getTodayDate') {
        final date = await getTodayDate();
        return 'Today\'s date: $date';
      } else if (name == 'addNote') {
        final content = params['content'] as String?;
        if (content == null) return 'Missing content parameter for addNote.';
        final result = await addNote(content);
        return 'Notion result: $result';
      } else {
        return 'Unknown tool: $name';
      }
    } catch (e) {
      return 'Tool execution error: $e';
    }
  }

  List<Map<String, String>> _convertMessagesToApi(
    List<ChatMessage> chatMessages,
  ) {
    final List<Map<String, String>> api = [];
    // Always inject the canonical system prompt as the first message
    api.add({'role': 'system', 'content': _buildSystemPrompt()});
    for (final ctx in _pdfContexts) {
      api.add({'role': 'system', 'content': ctx});
    }
    api.addAll(
      chatMessages.reversed.map((msg) {
        final role = msg.user.id == user.id ? 'user' : 'assistant';
        return {'role': role, 'content': msg.text};
      }),
    );
    return api;
  }

  Future<void> _attachPdf() async {
    final result = await _fileService.pickPdfFile();
    if (result != null) {
      Uint8List? bytes = result.files.single.bytes;
      String text;
      if (bytes != null) {
        // Web or if we already have the bytes
        text = await _fileService.extractTextFromPdfBytes(bytes);
      } else if (result.files.single.path != null) {
        // Desktop / mobile with file path
        final file = File(result.files.single.path!);
        text = await _fileService.extractTextFromPdf(file);
      } else {
        print('[PDF] No bytes or path found.');
        return;
      }
      // text resolved above
      // Debug log
      print(
        '[PDF] Extracted text length: ${text.length}. Preview: ${text.substring(0, text.length > 200 ? 200 : text.length)}',
      );
      
      // Create a preview of the PDF content
      final String previewText = text.length > 300
          ? '${text.substring(0, 1000)}...'
          : text;
      
      setState(() {
        // Add the PDF content to the contexts that will be sent to the API
        _pdfContexts.add(text);
        
        // Show the filename and preview in the chat UI
        messages.insert(
          0,
          ChatMessage(
            user: user,
            createdAt: DateTime.now(),
            text: '''[PDF Attached] 📄 ${result.files.single.name}

**Preview of PDF content:**
```
$previewText
```''',
          ),
        );
      });
    }
  }
}
