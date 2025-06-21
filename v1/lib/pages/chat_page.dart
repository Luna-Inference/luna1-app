import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../widgets/chat_history_sidebar.dart';
import 'dart:async';
import '../services/llm.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';

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
  final _llmService = LlmService();

  String _serverStatus = 'Checking...';
  String _generationStatus = '';
  String _promptEvalSpeedWps = '-';
  String _generationSpeedWps = '-';
  Timer? _healthCheckTimer;

  @override
  void initState() {
    super.initState();
    _apiMessages = [
      {'role': 'system', 'content': 'You are Luna, a sexy lady.'}
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
    final health = await _llmService.fetchServerHealth();
    if (mounted) {
      setState(() {
        _serverStatus = health.status;
        _generationStatus = health.generationStatus;
        _promptEvalSpeedWps = health.promptEvalSpeedWps;
        _generationSpeedWps = health.generationSpeedWps;
      });
    }
  }

    void _getAIResponse() {
    TextMessage? thinkingMessage;
    TextMessage? assistantMessage;

    _llmService.getAIResponse(_apiMessages).listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case LlmStreamEventType.thinking:
          if (thinkingMessage == null) {
            thinkingMessage = TextMessage(
              authorId: _assistant.id,
              createdAt: DateTime.now(),
              id: 'thinking_${Random().nextInt(1000000)}',
              text: event.content,
              metadata: const {'isThinkingBlock': true},
            );
            _chatController.insertMessage(thinkingMessage!);
          } else {
            final oldMsg = thinkingMessage!;
            thinkingMessage = oldMsg.copyWith(text: event.content);
            _chatController.updateMessage(oldMsg, thinkingMessage!);
          }
          break;
        case LlmStreamEventType.response:
          if (assistantMessage == null) {
            assistantMessage = TextMessage(
              authorId: _assistant.id,
              createdAt: DateTime.now(),
              id: 'response_${Random().nextInt(1000000)}',
              text: event.content,
            );
            _chatController.insertMessage(assistantMessage!);
          } else {
            final oldMsg = assistantMessage!;
            assistantMessage = oldMsg.copyWith(text: event.content);
            _chatController.updateMessage(oldMsg, assistantMessage!);
          }
          break;
        case LlmStreamEventType.fullResponse:
          _apiMessages.add({'role': 'assistant', 'content': event.content});
          break;
        case LlmStreamEventType.error:
          final errorMessage = TextMessage(
            authorId: _systemUser.id,
            createdAt: DateTime.now(),
            id: 'error_${Random().nextInt(1000000)}',
            text: event.content,
          );
          _chatController.insertMessage(errorMessage);
          break;
      }
    });
  }

  // Custom Message Builder
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
          color: colorScheme.tertiaryContainer.withOpacity(0.5), // Different color for thinking
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
    // Get the current theme's color scheme and text theme
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna Chat'),
      ),
      drawer: const ChatHistorySidebar(),
      body: Stack(
        children: [
          Chat(
            /*builders: Builders(
      textMessageBuilder: (context, message, index, {
        required bool isSentByMe,
        MessageGroupStatus? groupStatus,
      }) =>
        FlyerChatTextMessage(message: message, index: index),
    ),*/
        chatController: _chatController,
        currentUserId: _user.id,
        onMessageSend: _handleMessageSend,
        resolveUser: (id) async {
          if (id == _user.id) return _user;
          if (id == _assistant.id) return _assistant;
          if (id == _systemUser.id) return _systemUser;
          return const User(id: 'unknown'); // Fallback for unknown users
        },
        theme: ChatTheme(
          colors: ChatColors(
            primary: colorScheme.primary,
            onPrimary: colorScheme.onPrimary,
            surface: colorScheme.surface,
            onSurface: colorScheme.onSurface,
            surfaceContainer: colorScheme.surfaceVariant,
            surfaceContainerLow: colorScheme.surfaceVariant.withOpacity(0.5),
            surfaceContainerHigh: colorScheme.surfaceVariant.withOpacity(0.8),
          ),
          typography: ChatTypography(
            bodyLarge: textTheme.bodyLarge!,
            bodyMedium: textTheme.bodyMedium!,
            bodySmall: textTheme.bodySmall!,
            labelLarge: textTheme.labelLarge!,
            labelMedium: textTheme.labelMedium!,
            labelSmall: textTheme.labelSmall!,
          ),
          shape: BorderRadius.circular(20),
        ),
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