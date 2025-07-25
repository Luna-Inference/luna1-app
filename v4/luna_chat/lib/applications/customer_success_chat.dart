import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:luna_chat/data/user_name.dart';
import 'package:luna_chat/functions/file_service.dart';
import 'package:luna_chat/functions/llm.dart';
import 'package:luna_chat/functions/luna_health_check.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/prompts/system_prompts.dart';

class CustomerSuccessChatApp extends StatefulWidget {
  const CustomerSuccessChatApp({super.key});

  @override
  State<CustomerSuccessChatApp> createState() => _CustomerSuccessChatAppState();
}

class _CustomerSuccessChatAppState extends State<CustomerSuccessChatApp> {
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
  
  // Store attached document content
  String? _attachedDocumentText;
  String? _attachedDocumentName;

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
    
    // Get system prompt from SystemPrompts class
    final systemPrompt = SystemPrompts.getCustomerSuccessPrompt(userName: userName);

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
      welcomeText = 'Hello $userName! 👋\n\nWelcome to the Luna Companion Application. I\'m Luna, your AI assistant running locally on your Luna device. I\'m here to help with questions, creative tasks, coding, analysis, and more.\n\nHow can I assist you today?';
    } else {
      welcomeText = 'Hello there! 👋\n\nWelcome to the Luna Companion Application. I\'m Luna, your AI assistant running locally on your Luna device. I\'m here to help with questions, creative tasks, coding, analysis, and more.\n\nHow can I assist you today?';
    }

    // Create initial empty welcome message
    final welcomeMessage = TextMessage(
      id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
      authorId: _aiUserId,
      createdAt: DateTime.now(),
      text: '',
      metadata: {'streaming': true},
    );
    
    if (mounted) {
      _chatController.insertMessage(welcomeMessage);
      
      // Stream the welcome text character by character
      await _streamWelcomeText(welcomeMessage, welcomeText);
      _hasShownWelcome = true;
    }
  }

  Future<void> _streamWelcomeText(TextMessage message, String fullText) async {
    const int delay = 30; // milliseconds between characters
    String currentText = '';
    
    for (int i = 0; i < fullText.length; i++) {
      if (!mounted) return;
      
      currentText += fullText[i];
      
      final updatedMessage = message.copyWith(
        text: currentText,
        metadata: {'streaming': true},
      );
      
      _chatController.updateMessage(message, updatedMessage);
      
      // Add delay between characters for typing effect
      await Future.delayed(Duration(milliseconds: delay));
    }
    
    // Final update to remove streaming metadata
    if (mounted) {
      final finalMessage = message.copyWith(
        text: fullText,
        metadata: {},
      );
      _chatController.updateMessage(message, finalMessage);
    }
  }

  // Handle attachment tap - this is called by flutter_chat_ui
  void _handleAttachmentTap() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Attach Document',
                  style: headingText.copyWith(
                    color: whiteAccent,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'PDF Document',
                    style: mainText.copyWith(color: whiteAccent),
                  ),
                  subtitle: Text(
                    'Extract text from PDF files',
                    style: smallText.copyWith(color: textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePdfUpload();
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePdfUpload() async {
    try {
      // Show loading indicator
      _showLoadingDialog('Extracting text from PDF...');

      // Pick PDF and extract text
      final String? extractedText = await PdfHelper.pickPdfAndExtractText();
      
      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (extractedText != null && extractedText.isNotEmpty) {
        // Clean the extracted text
        final String cleanText = PdfHelper.cleanExtractedText(extractedText);
        
        // Store the document content for next message
        setState(() {
          _attachedDocumentText = cleanText;
          _attachedDocumentName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
        });
        
        // Show attachment confirmation with preview
        _showAttachmentConfirmation(cleanText);
        
      } else {
        if (mounted) {
          _showErrorDialog('No text could be extracted from the PDF file.');
        }
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        _showErrorDialog('Error processing PDF: ${e.toString()}');
      }
    }
  }

  void _showAttachmentConfirmation(String content) {
    if (!mounted) return;
    
    // Add a visual indicator message that document is attached
    final attachmentMessage = TextMessage(
      id: 'attachment-${DateTime.now().millisecondsSinceEpoch}',
      authorId: _currentUserId,
      createdAt: DateTime.now(),
      text: '📎 Document attached successfully\n\nType your message and send to include the document content with your query.',
      metadata: {
        'isAttachment': true,
        'attachmentName': _attachedDocumentName,
        'preview': PdfHelper.getTextPreview(content, maxLength: 200),
      },
    );
    
    _chatController.insertMessage(attachmentMessage);
  }

  void _clearAttachment() {
    setState(() {
      _attachedDocumentText = null;
      _attachedDocumentName = null;
    });
  }

  Future<List<Map<String, String>>> _buildMessageContext(String userText) async {
    // Combine user message with attached document if present
    String finalMessage = userText;
    
    if (_attachedDocumentText != null && _attachedDocumentText!.isNotEmpty) {
      finalMessage = '$userText\n\n--- Attached Document Content ---\n$_attachedDocumentText';
      
      // Clear attachment after using it
      setState(() {
        _attachedDocumentText = null;
        _attachedDocumentName = null;
      });
    }
    
    // Add combined message to conversation history
    _conversationHistory.add({'role': 'user', 'content': finalMessage});
    
    // Manage conversation history length to prevent context overflow
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
    _conversationHistory.add({'role': 'assistant', 'content': response});
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              CircularProgressIndicator(color: buttonColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: mainText.copyWith(color: whiteAccent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            'Error',
            style: headingText.copyWith(color: Colors.red),
          ),
          content: Text(
            message,
            style: mainText.copyWith(color: whiteAccent),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: buttonColor)),
            ),
          ],
        );
      },
    );
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
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'Roboto',
        ),
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
            onAttachmentTap: _handleAttachmentTap, // Use native attachment system
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: headingText.copyWith(
                        color: whiteAccent,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _isLunaOnline ? 'Online' : 'Offline',
                          style: smallText.copyWith(
                            color: _isLunaOnline 
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        if (_attachedDocumentText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: buttonColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_file,
                                  size: 12,
                                  color: buttonColor,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Doc attached',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: buttonColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        if (_attachedDocumentText != null)
          IconButton(
            onPressed: _clearAttachment,
            icon: Icon(
              Icons.close,
              color: Colors.orange,
            ),
            tooltip: 'Remove attached document',
          ),
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
    final isThinking = message.metadata?['isThinking'] == true;
    final isError = message.metadata?['isError'] == true;
    final isStreaming = message.metadata?['streaming'] == true;
    final isAttachment = message.metadata?['isAttachment'] == true;
    
    return Container(
      margin: EdgeInsets.only(
        left: isSentByMe ? 60 : 16,
        right: isSentByMe ? 16 : 60,
        bottom: 4,
        top: 0,
      ),
      child: Align(
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getMessageBackgroundColor(isSentByMe, isThinking, isError, isAttachment),
            borderRadius: isSentByMe 
              ? BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(4),
                )
              : isThinking || isError || isAttachment
                ? BorderRadius.circular(12)
                : BorderRadius.zero,
            border: isThinking 
              ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1)
              : isAttachment 
                ? Border.all(color: buttonColor.withOpacity(0.5), width: 1)
                : null,
            boxShadow: _getShadowColor(isSentByMe, isThinking, isError, isAttachment) == Colors.transparent 
              ? null
              : [
                  BoxShadow(
                    color: _getShadowColor(isSentByMe, isThinking, isError, isAttachment),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Attachment indicator
                if (isAttachment) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_file, size: 16, color: buttonColor),
                      const SizedBox(width: 6),
                      Text(
                        message.metadata?['attachmentName'] ?? 'Document',
                        style: smallText.copyWith(
                          color: buttonColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (message.metadata?['preview'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        message.metadata!['preview'],
                        style: smallText.copyWith(
                          color: textColor,
                          fontSize: 10,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
                
                // Other indicators (thinking, error, etc.)
                if (isThinking) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.psychology, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Thinking...',
                        style: smallText.copyWith(
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                
                if (isError) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Text(
                        'Error',
                        style: smallText.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                
                // Message content
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: message.text.isEmpty && isStreaming 
                          ? Text(
                              'Luna is typing...',
                              style: mainText.copyWith(
                                color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : MarkdownBody(
                              data: message.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  height: 1.4,
                                ),
                                h1: headingText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                h2: headingText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                h3: headingText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                strong: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontWeight: FontWeight.bold,
                                ),
                                em: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontStyle: FontStyle.italic,
                                ),
                                listBullet: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                ),
                                code: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment),
                                  fontFamily: 'monospace',
                                  backgroundColor: isSentByMe 
                                      ? backgroundColor.withOpacity(0.2)
                                      : buttonColor.withOpacity(0.1),
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: isSentByMe 
                                      ? backgroundColor.withOpacity(0.2)
                                      : buttonColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                blockquote: mainText.copyWith(
                                  color: _getTextColor(isSentByMe, isThinking, isError, isAttachment).withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                    ),
                    
                    // Streaming indicator
                    if (isStreaming && !isThinking) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isSentByMe ? whiteAccent.withOpacity(0.8) : textColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Timestamp
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.createdAt),
                  style: smallText.copyWith(
                    color: _getTimestampColor(isSentByMe, isThinking, isError, isAttachment),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods for styling
  Color _getMessageBackgroundColor(bool isSentByMe, bool isThinking, bool isError, bool isAttachment) {
    if (isError) return Colors.red.withOpacity(0.1);
    if (isThinking) return Colors.orange.withOpacity(0.05);
    if (isAttachment) return buttonColor.withOpacity(0.1);
    return isSentByMe ? buttonColor : backgroundColor;
  }

  Color _getShadowColor(bool isSentByMe, bool isThinking, bool isError, bool isAttachment) {
    if (isError) return Colors.red.withOpacity(0.3);
    if (isThinking) return Colors.orange.withOpacity(0.3);
    if (isAttachment) return buttonColor.withOpacity(0.2);
    return isSentByMe ? buttonColor.withOpacity(0.3) : Colors.transparent;
  }

  Color _getTextColor(bool isSentByMe, bool isThinking, bool isError, bool isAttachment) {
    if (isError) return Colors.red[300]!;
    if (isThinking) return Colors.orange[200]!;
    if (isAttachment) return buttonColor;
    return isSentByMe ? backgroundColor : whiteAccent;
  }

  Color _getTimestampColor(bool isSentByMe, bool isThinking, bool isError, bool isAttachment) {
    if (isError) return Colors.red.withOpacity(0.7);
    if (isThinking) return Colors.orange.withOpacity(0.7);
    if (isAttachment) return buttonColor.withOpacity(0.7);
    return isSentByMe ? whiteAccent.withOpacity(0.8) : textColor;
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
      // Build message context (this will include attached document if present)
      final messages = await _buildMessageContext(text);

      // Create initial AI response message
      final aiMessage = TextMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        authorId: _aiUserId,
        createdAt: DateTime.now(),
        text: '',
      );
      
      _chatController.insertMessage(aiMessage);
      
      // Handle streaming response (rest of your existing streaming logic)
      TextMessage? currentThinkingMessage;
      final responseBuffer = StringBuffer();
      
      final responseStream = _llmService.sendMessage(messages);
      
      _llmSubscription = responseStream.listen(
        (event) {
          if (!mounted) return;
          
          switch (event.type) {
            case LlmStreamEventType.thinking:
              if (currentThinkingMessage == null) {
                currentThinkingMessage = TextMessage(
                  id: 'thinking-${DateTime.now().millisecondsSinceEpoch}',
                  authorId: _aiUserId,
                  createdAt: DateTime.now(),
                  text: event.content,
                  metadata: {'isThinking': true},
                );
                _chatController.insertMessage(currentThinkingMessage!);
              } else {
                final updatedThinking = currentThinkingMessage!.copyWith(
                  text: event.content,
                  metadata: {'isThinking': true},
                );
                _chatController.updateMessage(currentThinkingMessage!, updatedThinking);
                currentThinkingMessage = updatedThinking;
              }
              break;
              
            case LlmStreamEventType.token:
              responseBuffer.write(event.content);
              final updatedMessage = aiMessage.copyWith(
                text: responseBuffer.toString(),
                metadata: {'streaming': true},
              );
              _chatController.updateMessage(aiMessage, updatedMessage);
              break;
              
            case LlmStreamEventType.done:
              final finalResponse = event.content.isNotEmpty 
                  ? event.content 
                  : responseBuffer.toString();
              
              final finalMessage = aiMessage.copyWith(
                text: finalResponse,
                metadata: {},
              );
              _chatController.updateMessage(aiMessage, finalMessage);
              
              if (currentThinkingMessage != null) {
                _chatController.removeMessage(currentThinkingMessage!);
                currentThinkingMessage = null;
              }
              
              _addAssistantResponseToHistory(finalResponse);
              
              setState(() {
                _isWaitingForResponse = false;
              });
              break;
              
            case LlmStreamEventType.error:
              if (currentThinkingMessage != null) {
                _chatController.removeMessage(currentThinkingMessage!);
                currentThinkingMessage = null;
              }
              
              final errorMessage = aiMessage.copyWith(
                text: 'Error: ${event.content}',
                metadata: {'isError': true},
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
          
          if (currentThinkingMessage != null) {
            _chatController.removeMessage(currentThinkingMessage!);
            currentThinkingMessage = null;
          }
          
          final errorMessage = aiMessage.copyWith(
            text: 'Connection error: ${error.toString()}',
            metadata: {'isError': true},
          );
          _chatController.updateMessage(aiMessage, errorMessage);
          
          setState(() {
            _isWaitingForResponse = false;
          });
        },
        onDone: () {
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
        metadata: {'isError': true},
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