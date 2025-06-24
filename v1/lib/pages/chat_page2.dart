import 'dart:async';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import '../services/llm.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class Basic extends StatefulWidget {
  @override
  _BasicState createState() => _BasicState();
}

class _BasicState extends State<Basic> {
  final LlmService _llmService = LlmService();

  final ChatUser _user = ChatUser(
    id: '1',
    firstName: 'User',
  );

  final ChatUser _assistant = ChatUser(
    id: 'assistant',
    firstName: 'Luna',
  );

  List<ChatMessage> _messages = <ChatMessage>[];
  final List<Map<String, String>> _apiMessages = [];

  // Stream handling
  ChatMessage? _assistantMessage;
  ChatMessage? _thinkingMessage;
  String? _assistantMessageKey;
  String? _thinkingMessageKey;

  @override
  void initState() {
    super.initState();
    // Add a system message to initialize the conversation
    _apiMessages.add({
      'role': 'system',
      'content': 'You are a helpful assistant named Luna.'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna Chat'),
      ),
      body: DashChat(
        currentUser: _user,
        onSend: _handleMessageSend,
        messages: _messages,
        messageListOptions: MessageListOptions(
        ),
        messageOptions: MessageOptions(
          messageRowBuilder: (message, previousMessage, nextMessage, isOwnMessage, isPreviousMessageFromSameUser) =>
              _buildCustomMessage(message, isOwnMessage, context),
        ),
      ),
    );
  }

  /// Handle sending a new message
  void _handleMessageSend(ChatMessage message) {
    // Add the new user message.
    setState(() {
      _messages.insert(0, message);
      print('user is:');
      print(message.user.id);
      print(message.text);
    });

    // Add to API messages format for backend.
    _apiMessages.add({'role': 'user', 'content': message.text});

    // Reset message state completely for this turn
    _thinkingMessage = null;
    _thinkingMessageKey = null;
    _assistantMessage = null;
    _assistantMessageKey = null;

    // Get AI response.
    _getAIResponse();
  }

  void _getAIResponse() {
    _llmService.getAIResponse(_apiMessages).listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case LlmStreamEventType.thinking:
        // If this is the first thinking event for the current turn, create the message.
          if (_thinkingMessage == null) {
            _thinkingMessageKey =
            'thinking_${DateTime.now().millisecondsSinceEpoch}';

            _thinkingMessage = ChatMessage(
              user: _assistant,
              createdAt: DateTime.now(),
              text: event.content,
              customProperties: {
                'isThinkingBlock': true,
                'messageKey': _thinkingMessageKey
              },
            );

            // Insert thinking message at the top (index 0)
            setState(() {
              _messages.insert(0, _thinkingMessage!);
            });
          } else {
            // Update the existing thinking message content
            setState(() {
              final idx = _messages.indexWhere((msg) =>
              msg.customProperties != null &&
                  msg.customProperties!['messageKey'] == _thinkingMessageKey);
              if (idx != -1) {
                _thinkingMessage = ChatMessage(
                  user: _assistant,
                  createdAt: _thinkingMessage!.createdAt,
                  text: event.content,
                  customProperties: {
                    'isThinkingBlock': true,
                    'messageKey': _thinkingMessageKey
                  },
                );
                _messages[idx] = _thinkingMessage!;
              }
            });
          }
          break;

        case LlmStreamEventType.response:
        // If this is the first response chunk, create the message.
          if (_assistantMessage == null) {
            // If the backend mistakenly echoes the user's prompt as the first
            // response chunk, ignore it so it doesn't render as an assistant
            // message aligned to the left.
            final Map<String, String> lastUser = _apiMessages.lastWhere(
              (m) => m['role'] == 'user',
              orElse: () => {'role': '', 'content': ''},
            );
            if (event.content.trim() == lastUser['content']!.trim()) {
              break; // Skip this chunk and wait for the real assistant content
            }
            _assistantMessageKey =
            'response_${DateTime.now().millisecondsSinceEpoch}';
            _assistantMessage = ChatMessage(
              user: _assistant,
              createdAt: DateTime.now(),
              text: event.content,
              customProperties: {'messageKey': _assistantMessageKey},
            );

            setState(() {
              // Find the thinking block and insert the response right after it
              final thinkingIndex = _messages.indexWhere((msg) =>
              msg.customProperties != null &&
                  msg.customProperties!['messageKey'] == _thinkingMessageKey);

              if (thinkingIndex != -1) {
                // Insert the response message right after the thinking block
                _messages.insert(thinkingIndex + 1, _assistantMessage!);
              } else {
                // If no thinking block exists, insert at the top
                _messages.insert(0, _assistantMessage!);
              }
            });
          } else {
            // Update the existing response message content
            setState(() {
              final idx = _messages.indexWhere((msg) =>
              msg.customProperties != null &&
                  msg.customProperties!['messageKey'] == _assistantMessageKey);
              if (idx != -1) {
                _assistantMessage = ChatMessage(
                  user: _assistant,
                  createdAt: _assistantMessage!.createdAt,
                  text: event.content,
                  customProperties: {'messageKey': _assistantMessageKey},
                );
                _messages[idx] = _assistantMessage!;
              }
            });
          }
          break;

        case LlmStreamEventType.fullResponse:
        case LlmStreamEventType.error:
        // The turn is complete (either successfully or with an error).
          if (event.type == LlmStreamEventType.error) {
            final errorMessage = ChatMessage(
              user: _assistant,
              createdAt: DateTime.now(),
              text: "Sorry, I encountered an error: ${event.content}",
            );
            setState(() {
              _messages.insert(0, errorMessage);
            });
          } else if (_assistantMessage != null) {
            // For a successful response, add the final message to the API history
            _apiMessages.add({'role': 'assistant', 'content': event.content});

            // Update the assistant message with final content and remove temporary properties
            final idx = _messages.indexWhere((msg) =>
            msg.customProperties != null &&
                msg.customProperties!['messageKey'] == _assistantMessageKey);
            if (idx != -1) {
              setState(() {
                _messages[idx] = ChatMessage(
                  user: _assistant,
                  createdAt: _assistantMessage!.createdAt,
                  text: event.content,
                  // Remove custom properties so it displays as a normal message
                );
              });
            }
          }

          // Remove ONLY the specific thinking block for this turn
          if (_thinkingMessageKey != null) {
            setState(() {
              _messages.removeWhere((msg) =>
              msg.customProperties != null &&
                  msg.customProperties!['messageKey'] == _thinkingMessageKey);
            });
          }

          // Reset state for the next turn.
          _assistantMessage = null;
          _assistantMessageKey = null;
          _thinkingMessage = null;
          _thinkingMessageKey = null;
          break;
      }
    });
  }

  Widget _buildCustomMessage(
      ChatMessage message, bool isOwnMessage, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isThinkingBlock =
        message.customProperties?['isThinkingBlock'] == true;

    Widget messageWidget;

    if (isThinkingBlock) {
      messageWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer.withOpacity(0.5),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 0.5,
            )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Luna's thinking process...",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withOpacity(0.9),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              message.text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (!isOwnMessage) {
      // AI message
      messageWidget = _buildMarkdownMessage(message, context);
    } else {
      // User message
      messageWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: colorScheme.onPrimary,
          ),
        ),
      );
    }

    return Align(
      alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: messageWidget,
      ),
    );
  }

  Widget _buildMarkdownMessage(ChatMessage message, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: MarkdownBody(
        data: message.text,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: colorScheme.onSurface),
          h1: TextStyle(
              color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          h2: TextStyle(
              color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          h3: TextStyle(
              color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          code: TextStyle(
            backgroundColor: colorScheme.surfaceVariant,
            color: colorScheme.onSurfaceVariant,
            fontFamily: 'monospace',
          ),
          codeblockDecoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        selectable: true,
      ),
    );
  }
}