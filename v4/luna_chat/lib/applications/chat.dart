import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/data/user_name.dart';
import 'package:luna_chat/functions/luna_health_check.dart';
import 'package:luna_chat/functions/llm.dart';
import 'dart:async';

class LunaChatApp extends StatefulWidget {
  const LunaChatApp({super.key});

  @override
  State<LunaChatApp> createState() => _LunaChatAppState();
}

class _LunaChatAppState extends State<LunaChatApp> {
  final _chatController = InMemoryChatController();
  final String _currentUserId = 'user1';
  final String _aiUserId = 'ai_assistant';
  bool _isLunaOnline = false;
  bool _isWaitingForResponse = false;
  bool _hasShownWelcome = false;
  Timer? _healthCheckTimer;
  final LlmService _llmService = LlmService();
  StreamSubscription<LlmStreamEvent>? _llmSubscription;

  // Store conversation history for multi-turn conversations
  List<Map<String, String>> _conversationHistory = [];
  String? _cachedUserName;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startHealthCheck();
  }

  Future<void> _initializeChat() async {
    // Cache the user name
    _cachedUserName = await getUserName();
    
    // Initialize conversation history with dynamic system message
    await _initializeSystemMessage();
    
    // Show welcome message
    await _showWelcomeMessage();
  }

  Future<void> _initializeSystemMessage() async {
    final userName = _cachedUserName ?? '';
    
    // Simple, concise system prompt
    String systemPrompt = 'You are Luna, a helpful AI assistant running on a Luna device.';
    
    if (userName.isNotEmpty) {
      systemPrompt += ' The user you are interacting with is $userName.';
    }

    // Initialize conversation history with system message
    _conversationHistory = [
      {'role': 'system', 'content': systemPrompt}
    ];
  }

  Future<void> _showWelcomeMessage() async {
    if (_hasShownWelcome) return;
    
    // Wait a moment to ensure the chat UI is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final userName = _cachedUserName ?? '';
    String welcomeText;
    
    if (userName.isNotEmpty) {
      welcomeText = 'Hello $userName! 👋\n\nWelcome to Luna Chat. I\'m Luna, your AI assistant running locally on your Luna device. I\'m here to help with questions, creative tasks, coding, analysis, and more.\n\nHow can I assist you today?';
    } else {
      welcomeText = 'Hello there! 👋\n\nWelcome to Luna Chat. I\'m Luna, your AI assistant running locally on your Luna device. I\'m here to help with questions, creative tasks, coding, analysis, and more.\n\nHow can I assist you today?';
    }

    final welcomeMessage = TextMessage(
      id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
      authorId: _aiUserId,
      createdAt: DateTime.now(),
      text: welcomeText,
    );
    
    if (mounted) {
      _chatController.insertMessage(welcomeMessage);
      _hasShownWelcome = true;
    }
  }

  Future<List<Map<String, String>>> _buildMessageContext(String userText) async {
    // Add user message to conversation history
    _conversationHistory.add({'role': 'user', 'content': userText});
    
    // Manage conversation history length to prevent context overflow
    // Keep system message + last 10 exchanges (20 messages)
    const maxMessages = 21; // 1 system + 20 conversation messages
    
    if (_conversationHistory.length > maxMessages) {
      _conversationHistory = [
        _conversationHistory.first, // Always keep system message
        ..._conversationHistory.skip(_conversationHistory.length - (maxMessages - 1))
      ];
    }
    
    return List<Map<String, String>>.from(_conversationHistory);
  }

  void _addAssistantResponseToHistory(String response) {
    // Add assistant response to conversation history
    _conversationHistory.add({'role': 'assistant', 'content': response});
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    _llmSubscription?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _startHealthCheck() async {
    // Initial check
    final isOnline = await checkLunaHealth();
    if (mounted) {
      setState(() {
        _isLunaOnline = isOnline;
      });
    }

    // Set up periodic check every 5 seconds
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final isOnline = await checkLunaHealth();
      if (mounted && isOnline != _isLunaOnline) {
        setState(() {
          _isLunaOnline = isOnline;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      ),
      home: Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(),
        body: Container(
          color: backgroundColor,
          child: Chat(
            chatController: _chatController,
            currentUserId: _currentUserId,
            theme: _buildChatTheme(),
            onMessageSend: _handleMessageSend,
            resolveUser: _resolveUser,
            builders: _buildCustomBuilders(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      title: FutureBuilder<String>(
        future: getUserName(),
        builder: (context, snapshot) {
          final userName = snapshot.data ?? '';
          final displayName = userName.isNotEmpty ? 'Luna & $userName' : 'Luna Assistant';
          
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smart_toy_outlined,
                  color: backgroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: headingText.copyWith(
                      color: whiteAccent,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _isLunaOnline ? 'Online' : 'Offline',
                    style: smallText.copyWith(
                      color: _isLunaOnline 
                          ? const Color(0xFF4ADE80) // Green for online
                          : const Color(0xFFEF4444), // Red for offline
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.more_vert,
            color: textColor,
          ),
        ),
      ],
    );
  }

  ChatTheme _buildChatTheme() {
    return ChatTheme(
      colors: ChatColors(
        primary: buttonColor,
        onPrimary: backgroundColor,
        surface: backgroundColor,
        onSurface: whiteAccent,
        surfaceContainer: const Color(0xFF2A2A2A),
        surfaceContainerLow: const Color(0xFF1F1F1F),
        surfaceContainerHigh: const Color(0xFF333333),
      ),
      typography: ChatTypography.standard(
        fontFamily: 'Roboto',
      ).copyWith(
        bodyMedium: mainText.copyWith(
          color: whiteAccent,
          height: 1.4,
        ),
        bodySmall: smallText.copyWith(
          color: textColor,
        ),
      ),
      shape: const BorderRadius.all(Radius.circular(18)),
    );
  }

  Builders _buildCustomBuilders() {
    return Builders(
      textMessageBuilder: (context, message, index, {required isSentByMe, groupStatus}) {
        return _buildCustomTextMessage(context, message as TextMessage, isSentByMe);
      },
    );
  }

  Widget _buildCustomTextMessage(BuildContext context, TextMessage message, bool isSentByMe) {
    return Container(
      margin: EdgeInsets.only(
        left: isSentByMe ? 60 : 16,
        right: isSentByMe ? 16 : 60,
        bottom: 8,
        top: 4,
      ),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSentByMe ? buttonColor : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isSentByMe ? 18 : 4),
              bottomRight: Radius.circular(isSentByMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: isSentByMe 
                    ? buttonColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: mainText.copyWith(
                  color: isSentByMe ? backgroundColor : whiteAccent,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: smallText.copyWith(
                  color: isSentByMe ? whiteAccent.withOpacity(0.8) : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomComposer(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF404040),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 5,
                        minLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.trim().isNotEmpty) {
                            _sendMessage(text.trim());
                            controller.clear();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildSendButton(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF404040),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: () {},
        icon: const Icon(
          Icons.add,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildSendButton(TextEditingController controller) {
    final isDisabled = _isWaitingForResponse || controller.text.trim().isEmpty;
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDisabled 
              ? [Colors.grey, Colors.grey.shade700]
              : const [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDisabled ? Colors.grey : const Color(0xFF667EEA)).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isWaitingForResponse
          ? const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : IconButton(
              onPressed: isDisabled 
                  ? null 
                  : () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                        controller.clear();
                      }
                    },
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
    );
  }

  void _handleMessageSend(String text) {
    _sendMessage(text);
  }
  void _sendMessage(String text) async {
  if (text.trim().isEmpty || _isWaitingForResponse) return;

  // Cancel any existing subscription
  await _llmSubscription?.cancel();

  setState(() {
    _isWaitingForResponse = true;
  });

  // Add user message
  final userMessage = TextMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    authorId: _currentUserId,
    createdAt: DateTime.now(),
    text: text,
  );
  _chatController.insertMessage(userMessage);

  try {
    // Build message context with system message and conversation history
    final messages = await _buildMessageContext(text);

    // Create initial AI message with empty content
    final aiMessage = TextMessage(
      id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
      authorId: _aiUserId,
      createdAt: DateTime.now(),
      text: '',
    );
    
    _chatController.insertMessage(aiMessage);
    
    // Get the response stream from LLM service
    final responseStream = _llmService.sendMessage(messages); // ✅ Changed from getAIResponse
    
    // Create a buffer to accumulate the response
    final responseBuffer = StringBuffer();
    
    _llmSubscription = responseStream.listen(
      (event) {
        if (!mounted) return;
        
        switch (event.type) {
          case LlmStreamEventType.token: // ✅ Changed from 'response'
            // Update the message with each new token
            responseBuffer.write(event.content);
            final updatedMessage = aiMessage.copyWith(
              text: responseBuffer.toString(),
              metadata: {'streaming': true} // ✅ Better metadata key
            );
            _chatController.updateMessage(aiMessage, updatedMessage);
            break;
            
          case LlmStreamEventType.done: // ✅ Changed from 'fullResponse'
            // Final update with the complete response
            final finalResponse = event.content.isNotEmpty 
                ? event.content 
                : responseBuffer.toString();
            
            final updatedMessage = aiMessage.copyWith(
              text: finalResponse,
              metadata: {} // ✅ Clear metadata when done
            );
            _chatController.updateMessage(aiMessage, updatedMessage);
            
            // Add the assistant response to conversation history
            _addAssistantResponseToHistory(finalResponse);
            
            setState(() {
              _isWaitingForResponse = false;
            });
            break;
            
          case LlmStreamEventType.error:
            final errorMessage = aiMessage.copyWith(
              text: 'Error: ${event.content}',
              metadata: {'isError': true}
            );
            _chatController.updateMessage(aiMessage, errorMessage);
            
            setState(() {
              _isWaitingForResponse = false;
            });
            break;
        }
      },
      onError: (error) {
        if (!mounted) return;
        
        final errorMessage = aiMessage.copyWith(
          text: 'Connection error: ${error.toString()}',
          metadata: {'isError': true}
        );
        _chatController.updateMessage(aiMessage, errorMessage);
        
        setState(() {
          _isWaitingForResponse = false;
        });
      },
      onDone: () {
        // This might be called in addition to the done event
        if (mounted && _isWaitingForResponse) {
          setState(() {
            _isWaitingForResponse = false;
          });
        }
      },
      cancelOnError: true,
    );
    
  } catch (e) {
    if (!mounted) return;
    
    final errorMessage = TextMessage(
      id: 'error-${DateTime.now().millisecondsSinceEpoch}',
      authorId: _aiUserId,
      createdAt: DateTime.now(),
      text: 'Error: ${e.toString()}',
      metadata: {'isError': true}
    );
    _chatController.insertMessage(errorMessage);
    
    if (mounted) {
      setState(() {
        _isWaitingForResponse = false;
      });
    }
  }
}

  Future<User> _resolveUser(String userId) async {
    if (userId == _currentUserId) {
      return User(
        id: userId,
        name: 'You',
        imageSource: null,
      );
    } else {
      return User(
        id: userId,
        name: 'Luna',
        imageSource: null,
      );
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}