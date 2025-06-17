import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../widgets/chat_history_sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For Timer
// flutter_chat_ui re-exports types from flutter_chat_types, so direct import is not needed.

class LunaChat extends StatefulWidget {
  const LunaChat({super.key});

  @override
  LunaChatState createState() => LunaChatState();
}

class LunaChatState extends State<LunaChat> {
  final _user = const User(id: 'user1', name: 'Thomas');
  final _assistant = const User(id: 'assistantLuna', name: 'Luna');
  final _systemUser = const User(id: 'system', name: 'System');

  final _chatController = InMemoryChatController();
  List<Map<String, String>> _apiMessages = [];

  String _serverStatus = 'Checking...';
  String _generationStatus = '';
  String _promptEvalSpeedWps = '-';
  String _generationSpeedWps = '-';
  Timer? _healthCheckTimer;

  @override
  void initState() {
    super.initState();
    _apiMessages = [
      {'role': 'system', 'content': 'You are a helpful assistant.'}
    ];
    _fetchServerHealth(); // Initial health check
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchServerHealth();
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _healthCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchServerHealth() async {
    try {
      final response = await http.get(Uri.parse('http://100.76.203.80:8080/health'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _serverStatus = data['status'] ?? 'Unknown';
            _generationStatus = data['generation_status'] ?? 'N/A';
            _promptEvalSpeedWps = data['prompt_eval_speed_wps']?.toString() ?? '-';
            _generationSpeedWps = data['generation_speed_wps']?.toString() ?? '-';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _serverStatus = 'Error: ${response.statusCode}';
            _generationStatus = '';
            _promptEvalSpeedWps = '-';
            _generationSpeedWps = '-';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverStatus = 'Offline';
          _generationStatus = '';
          _promptEvalSpeedWps = '-';
          _generationSpeedWps = '-';
        });
      }
    }
  }

  Future<void> _getAIResponse() async {
    final url = Uri.parse('http://100.76.203.80:8080/v1/chat/completions');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'luna-large',
      'messages': _apiMessages,
      'stream': true, // Enable streaming
    });

    final client = http.Client();
    http.Request request = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = body;

    TextMessage? thinkingMessage;
    TextMessage? assistantMessage;
    StringBuffer thinkingContentBuffer = StringBuffer();
    StringBuffer responseContentBuffer = StringBuffer();
    bool inThinkBlock = false;

    StringBuffer streamBuffer = StringBuffer(); // Buffer for incoming stream data before line splitting

    try {
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode == 200) {
        await for (var chunkData in streamedResponse.stream.transform(utf8.decoder)) {
          streamBuffer.write(chunkData);
          String currentData = streamBuffer.toString();
          List<String> lines = currentData.split('\n');
          streamBuffer.clear();
          if (lines.isNotEmpty && !currentData.endsWith('\n')) {
            streamBuffer.write(lines.removeLast()); // Keep partial line
          }

          for (var line in lines) {
            line = line.trim();
            if (line.isEmpty) continue;
            if (line.startsWith('data:')) {
              line = line.substring(5).trim();
            }
            if (line == '[DONE]') continue;

            try {
              final Map<String, dynamic> data = jsonDecode(line);
              final String deltaContent = data['choices'][0]['delta']?['content'] ?? data['choices'][0]['message']?['content'] ?? '';
              if (deltaContent.isEmpty) continue;

              String remainingDeltaContent = deltaContent;
              while (remainingDeltaContent.isNotEmpty) {
                if (inThinkBlock) {
                  int endTagIndex = remainingDeltaContent.indexOf('</think>');
                  if (endTagIndex != -1) {
                    thinkingContentBuffer.write(remainingDeltaContent.substring(0, endTagIndex));
                    remainingDeltaContent = remainingDeltaContent.substring(endTagIndex + '</think>'.length);
                    inThinkBlock = false;
                  } else {
                    thinkingContentBuffer.write(remainingDeltaContent);
                    remainingDeltaContent = '';
                  }
                } else {
                  int startTagIndex = remainingDeltaContent.indexOf('<think>');
                  if (startTagIndex != -1) {
                    String textForResponse = remainingDeltaContent.substring(0, startTagIndex);
                    if (textForResponse.isNotEmpty) {
                      responseContentBuffer.write(textForResponse);
                    }
                    remainingDeltaContent = remainingDeltaContent.substring(startTagIndex + '<think>'.length);
                    inThinkBlock = true;
                  } else {
                    responseContentBuffer.write(remainingDeltaContent);
                    remainingDeltaContent = '';
                  }
                }
              }

              // Update Thinking Message UI
              if (thinkingContentBuffer.isNotEmpty) {
                String currentThinkingText = thinkingContentBuffer.toString();
                if (thinkingMessage == null) {
                  thinkingMessage = TextMessage(
                    authorId: _assistant.id,
                    createdAt: DateTime.now(), 
                    id: 'thinking_${Random().nextInt(1000000)}',
                    text: currentThinkingText,
                    metadata: {'isThinkingBlock': true},
                  );
                  if (mounted) _chatController.insertMessage(thinkingMessage);
                } else if (thinkingMessage.text != currentThinkingText) { // Removed redundant null check for thinkingMessage
                  TextMessage oldThinkingMsg = thinkingMessage;
                  thinkingMessage = thinkingMessage.copyWith(text: currentThinkingText);
                  if (mounted) _chatController.updateMessage(oldThinkingMsg, thinkingMessage);
                }
              }

              // Update Assistant Response Message UI
              if (responseContentBuffer.isNotEmpty) {
                String currentResponseText = responseContentBuffer.toString();
                if (assistantMessage == null) {
                  assistantMessage = TextMessage(
                    authorId: _assistant.id,
                    createdAt: DateTime.now(), 
                    id: 'response_${Random().nextInt(1000000)}',
                    text: currentResponseText,
                  );
                  if (mounted) _chatController.insertMessage(assistantMessage);
                } else if (assistantMessage.text != currentResponseText) { // Removed redundant null check for assistantMessage
                  TextMessage oldAssistantMsg = assistantMessage;
                  assistantMessage = assistantMessage.copyWith(text: currentResponseText);
                  if (mounted) _chatController.updateMessage(oldAssistantMsg, assistantMessage);
                }
              }

            } catch (e) {
              // Potentially incomplete JSON, ignore and wait for more data
              // print('JSON parse error in stream: $e, line: $line');
              continue;
            }
          }
        }
        // After stream processing, _apiMessages will be updated in the finally block
      } else {
        final errorMessage = TextMessage(
          authorId: _systemUser.id,
          createdAt: DateTime.now(),
          id: '${Random().nextInt(100000) + 1}',
          text: 'Error: Failed to get response from AI. Status: ${streamedResponse.statusCode}',
        );
        _chatController.insertMessage(errorMessage);
        print('API Error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      final errorMessage = TextMessage(
        authorId: _systemUser.id,
        createdAt: DateTime.now(),
        id: '${Random().nextInt(100000) + 1}',
        text: 'Error: Could not connect to AI. ${e.toString()}',
      );
      _chatController.insertMessage(errorMessage);
      print('Network/Request Error: $e');
    } finally {
      client.close();
      // Finalize messages status or content if needed, though primary updates are in stream
      if (assistantMessage != null && responseContentBuffer.isNotEmpty) {
        // Ensure the full response is captured in _apiMessages
        // Check if the last entry is already this assistant's message to avoid duplicates if stream ends abruptly
        bool alreadyAdded = _apiMessages.isNotEmpty && 
                            _apiMessages.last['role'] == 'assistant' && 
                            _apiMessages.last['content'] == responseContentBuffer.toString();
        if (!alreadyAdded) {
             _apiMessages.removeWhere((msg) => msg['role'] == 'assistant' && msg['content'] != null && responseContentBuffer.toString().startsWith(msg['content']!)); // Remove partials
             _apiMessages.add({'role': 'assistant', 'content': responseContentBuffer.toString()});
        }
      }
    }
  }

  // Custom Bubble Builder
  Widget _customBubbleBuilder(
    Widget child, // This is the default bubble built by the library
    {required Message message, required bool nextMessageInGroup}
  ) {
    // Ensure the message is a TextMessage before proceeding
    if (message is! TextMessage) {
      return child; // Return default for non-text messages
    }
    // final textMessage = message as TextMessage; // Linter flags as unnecessary cast, message is already TextMessage here.

    final colorScheme = Theme.of(context).colorScheme;
    final isThinkingBlock = message.metadata?['isThinkingBlock'] == true;

    if (isThinkingBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3), // Subtle background
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Luna's thinking process...",
              style: TextStyle(
                fontWeight: FontWeight.w500, // Medium weight
                color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                fontSize: 13, // Slightly smaller
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              message.text, // Use message directly as it's now confirmed to be TextMessage
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      // For standard messages, return the default bubble provided by the child parameter.
      // The `child` already contains the correctly styled bubble for user vs. assistant messages.
      return child;
    }
  }

  void _handleMessageSend(String text) {
    final userMessage = TextMessage(
      authorId: _user.id,
      createdAt: DateTime.now(),
      id: '${Random().nextInt(100000) + 1}', // Use a better ID generation in production
      text: text,
    );

    _chatController.insertMessage(userMessage);
    _apiMessages.add({'role': 'user', 'content': text});
    _getAIResponse();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme's color scheme
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna Chat'),
      ),
      drawer: const ChatHistorySidebar(),
      body: Stack(
        children: [
          Chat(
        chatController: _chatController,
        currentUserId: _user.id,
        onMessageSend: _handleMessageSend,
        resolveUser: (id) async {
          if (id == _user.id) return _user;
          if (id == _assistant.id) return _assistant;
          if (id == _systemUser.id) return _systemUser;
          return const User(id: 'unknown'); // Fallback for unknown users
        },
        /*theme: ChatTheme(
          colors: ChatColors(
            primary: colorScheme.primary,
            onPrimary: colorScheme.onPrimary,
            surface: colorScheme.surface,
            onSurface: colorScheme.onSurface,
            surfaceContainer: colorScheme.surfaceVariant,
            surfaceContainerLow: colorScheme.surfaceVariant.withOpacity(0.5),
            surfaceContainerHigh: colorScheme.surfaceVariant.withOpacity(0.8),
            // TODO: Add other colors as needed from your theme
          ), typography: ChatTypography(bodyLarge: bodyLarge, bodyMedium: bodyMedium, bodySmall: bodySmall, labelLarge: labelLarge, labelMedium: labelMedium, labelSmall: labelSmall),


        ),*/
        //bubbleBuilder: _customBubbleBuilder, // Use the custom bubble builder
      ),
      Positioned(
        top: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S: $_serverStatus | G: $_generationStatus',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
              ),
              Text(
                'Prefill: $_promptEvalSpeedWps wps | Gen: $_generationSpeedWps wps',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }
}