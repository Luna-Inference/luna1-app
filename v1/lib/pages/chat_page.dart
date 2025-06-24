import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/llm.dart';
import '../services/files.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:pdf_text/pdf_text.dart';

class LunaChat extends StatefulWidget {
  const LunaChat({super.key});

  @override
  LunaChatState createState() => LunaChatState();
}

class LunaChatState extends State<LunaChat> {
  final _user = ChatUser(
    id: "user1",
    firstName: "Thomas",
    profileImage: "https://via.placeholder.com/150",
  );
  
  final _assistant = ChatUser(
    id: "assistantLuna",
    firstName: "Luna",
    profileImage: "https://via.placeholder.com/150",
  );
  
  final _systemUser = ChatUser(
    id: "system",
    firstName: "System",
    profileImage: "https://via.placeholder.com/150",
  );

  List<ChatMessage> _messages = [];
  List<Map<String, String>> _apiMessages = [];
  final _llmService = LlmService();
  final _fileService = FileService();
  
  // Stream handling variables
  ChatMessage? _thinkingMessage;
  ChatMessage? _assistantMessage;

  // PDF attachment state
  File? _attachedPdfFile;
  String _attachedPdfName = '';
  String _extractedPdfText = '';
  bool _isExtractingPdf = false;


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
  
  /// Pick a PDF file and extract its text
  Future<void> _handlePdfPicker() async {
    final result = await _fileService.pickPdfFile();
    
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      setState(() {
        _attachedPdfName = result.files.first.name;
        _attachedPdfFile = File(result.files.first.path!);
        _isExtractingPdf = true;
        _extractedPdfText = ''; // Reset previous extraction
      });
      
      // Extract text from PDF
      final extractedText = await _fileService.extractTextFromPdf(_attachedPdfFile!);
      
      setState(() {
        _extractedPdfText = extractedText;
        _isExtractingPdf = false;
      });
      
      // Create a system message with the PDF content
      if (_extractedPdfText.isNotEmpty) {
        // Add a system message about the PDF content
        final pdfInfoMessage = ChatMessage(
          user: _systemUser,
          createdAt: DateTime.now(),
          text: 'PDF Attached: $_attachedPdfName',
          customProperties: {'isPdfAttachment': true},
        );
        
        setState(() {
          _messages.add(pdfInfoMessage);
        });
      }
    }
  }
  
  /// Clear the current PDF attachment
  void _clearAttachment() {
    setState(() {
      _attachedPdfFile = null;
      _attachedPdfName = '';
      _extractedPdfText = '';
    });
  }

  @override
  void dispose() {
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
    // If there's a PDF attached, add its content to the API messages
    List<Map<String, String>> messagesWithPdf = List.from(_apiMessages);
    if (_extractedPdfText.isNotEmpty) {
      messagesWithPdf.add({
        'role': 'system', 
        'content': 'The user has shared the following PDF document content that you should consider in your response:\n\n$_extractedPdfText'
      });
    }

    // Create tracking variables to identify messages for updates
    String? thinkingMessageKey;
    String? assistantMessageKey;

    _llmService.getAIResponse(messagesWithPdf).listen((event) {
      if (!mounted) return;

      switch (event.type) {
        case LlmStreamEventType.thinking:
          if (_thinkingMessage == null) {
            // Create a unique key to track this message for updates
            thinkingMessageKey = 'thinking_${DateTime.now().millisecondsSinceEpoch}';
            
            _thinkingMessage = ChatMessage(
              user: _assistant,
              createdAt: DateTime.now(),
              text: event.content,
              customProperties: {
                'isThinkingBlock': true, 
                'messageKey': thinkingMessageKey
              },
            );
            
            setState(() {
              _messages.add(_thinkingMessage!);
            });
          } else {
            setState(() {
              // Find the thinking message by its custom property key
              final idx = _messages.indexWhere(
                (msg) => msg.customProperties != null && 
                        msg.customProperties!['messageKey'] == thinkingMessageKey
              );
              
              if (idx != -1) {
                // Create a new message with updated text
                _thinkingMessage = ChatMessage(
                  user: _assistant,
                  createdAt: _thinkingMessage!.createdAt,
                  text: event.content,
                  customProperties: {
                    'isThinkingBlock': true,
                    'messageKey': thinkingMessageKey
                  },
                );
                
                // Replace the old message
                _messages[idx] = _thinkingMessage!;
              }
            });
          }
          break;

        case LlmStreamEventType.response:
          if (_assistantMessage == null) {
            // Create a unique key to track this message for updates
            assistantMessageKey = 'response_${DateTime.now().millisecondsSinceEpoch}';
            
            _assistantMessage = ChatMessage(
              user: _assistant,
              createdAt: DateTime.now(),
              text: event.content,
              customProperties: {'messageKey': assistantMessageKey},
            );
            
            setState(() {
              _messages.add(_assistantMessage!);
            });
          } else {
            setState(() {
              // Find the assistant message by its custom property key
              final idx = _messages.indexWhere(
                (msg) => msg.customProperties != null && 
                        msg.customProperties!['messageKey'] == assistantMessageKey
              );
              
              if (idx != -1) {
                // Create a new message with updated text
                _assistantMessage = ChatMessage(
                  user: _assistant,
                  createdAt: _assistantMessage!.createdAt,
                  text: event.content,
                  customProperties: {'messageKey': assistantMessageKey},
                );
                
                // Replace the old message
                _messages[idx] = _assistantMessage!;
              }
            });
          }
          break;

        case LlmStreamEventType.fullResponse:
          _apiMessages.add({'role': 'assistant', 'content': event.content});
          break;

        case LlmStreamEventType.error:
          final errorMessage = ChatMessage(
            user: _systemUser,
            createdAt: DateTime.now(),
            text: event.content,
          );
          
          setState(() {
            _messages.add(errorMessage);
          });
          break;
      }
    });
  }

  /// Handle sending a new message
  void _handleMessageSend(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    
    // Add to API messages format for backend
    _apiMessages.add({'role': 'user', 'content': message.text});
    
    // Get AI response
    _getAIResponse();
  }
  
  /// Custom message builder for PDF attachments, thinking blocks, and markdown messages
  Widget _buildCustomMessage(ChatMessage message, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isThinkingBlock = message.customProperties?['isThinkingBlock'] == true;
    final isPdfAttachment = message.customProperties?['isPdfAttachment'] == true;
    
    if (isPdfAttachment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.5),
            width: 1,
          )
        ),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message.text,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (isThinkingBlock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withOpacity(0.5),
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
    } else if (message.user.id == _assistant.id) {
      // Use markdown rendering for AI messages
      return _buildMarkdownMessage(message, context);
    }
    
    // For regular user messages, use default bubble style
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message.text),
    );
  }
  
  /// Build a message with markdown rendering for the AI's responses
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
          h1: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          h2: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
          h3: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
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
  
  // Widget to display PDF attachment information
  Widget _buildAttachmentInfo() {
    if (_attachedPdfFile == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _attachedPdfName,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isExtractingPdf)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Extracting text...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                else if (_extractedPdfText.isNotEmpty)
                  Text(
                    '${_extractedPdfText.length} characters extracted',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearAttachment,
            tooltip: 'Remove attachment',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Luna Chat'),
        actions: [
          // PDF attachment button
          IconButton(
            icon: Icon(
              _attachedPdfFile == null ? Icons.attach_file : Icons.file_present,
              color: _attachedPdfFile != null ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: 'Attach PDF',
            onPressed: _handlePdfPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // PDF attachment info
          if (_attachedPdfFile != null) _buildAttachmentInfo(),
          
          // Server health indicator
          _buildServerHealthIndicator(),
          
          // Chat area
          Expanded(
            child: DashChat(
              currentUser: _user,
              onSend: (ChatMessage message) => _handleMessageSend(message),
              messages: _messages,
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: "Message Luna...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.all(20),
                ),
                inputTextStyle: Theme.of(context).textTheme.bodyMedium!,
                sendButtonBuilder: (void Function() onSend) => IconButton(
                  onPressed: onSend,
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                leading: [
                  IconButton(
                    icon: const Icon(Icons.attachment),
                    onPressed: () => _handleAttachmentPressed(context),
                  ),
                ],
              ),
              messageOptions: MessageOptions(
                showCurrentUserAvatar: true,
                showOtherUsersAvatar: true,
                showOtherUsersName: true,
                messagePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                currentUserContainerColor: Theme.of(context).colorScheme.primary,
                containerColor: Theme.of(context).colorScheme.primaryContainer,
                currentUserTextColor: Theme.of(context).colorScheme.onPrimary,
                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                messageTextBuilder: (message, previousMessage, nextMessage) {
                  if (message.customProperties?['isThinkingBlock'] == true || 
                      message.customProperties?['isPdfAttachment'] == true || 
                      message.user.id == _assistant.id) {
                    return _buildCustomMessage(message, context);
                  }
                  // Return regular text for user messages
                  return Text(message.text);
                },
              ),
              /*messageContainerConfig: const MessageContainerConfig(
                padding: EdgeInsets.all(8),
              ),
              chatFooterBuilder: () => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No messages yet.\nAsk Luna a question!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),*/
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerHealthIndicator() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.computer, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Server Status: $_serverStatus',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Generation Status: $_generationStatus',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Prompt Eval Speed: $_promptEvalSpeedWps wps | Generation Speed: $_generationSpeedWps wps',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachmentPressed(BuildContext context) async {
    await _handlePdfPicker();
  }
}