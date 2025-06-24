import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:v1/services/llm.dart';
import 'package:v1/services/files.dart';

ChatUser user = ChatUser(
  id: '1',
  firstName: 'Thomas',
);

ChatUser AI = ChatUser(
  id: '2',
  firstName: 'Luna',
);

class LunaChat extends StatefulWidget {
  @override
  _LunaChatState createState() => _LunaChatState();
}

class _LunaChatState extends State<LunaChat> {


  List<ChatMessage> messages = [];

  final LlmService _llmService = LlmService();
  StreamSubscription<LlmStreamEvent>? _llmSubscription;
  int? _thinkingMsgIndex;
  int? _answerMsgIndex;
  final FileService _fileService = FileService();
  final List<String> _pdfContexts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic example'),
      ),
      body: DashChat(
        inputOptions: InputOptions(
          inputDecoration: InputDecoration(
            prefixIcon: IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _attachPdf,
            ),
          ),
        ),
        messageOptions: MessageOptions(
          messageTextBuilder: (message, previous, next) {
            return MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            );
          },
          messageDecorationBuilder: (message, previous, next) {
            if (message.customProperties != null && message.customProperties!['thinking'] == true) {
              return BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(12),
              );
            }
            return BoxDecoration(
              color: message.user.id == user.id ? Colors.blueAccent.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
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
          _llmSubscription?.cancel();

          final apiMessages = _convertMessagesToApi(messages);
          // Debug log
          print('[LLM] Sending first messages: \\${jsonEncode(apiMessages.take(3).toList())}');

          _llmSubscription = _llmService.getAIResponse(apiMessages).listen((event) {
            setState(() {
              switch (event.type) {
                case LlmStreamEventType.thinking:
                  if (_thinkingMsgIndex == null) {
                    messages.insert(0, ChatMessage(user: AI, createdAt: DateTime.now(), text: event.content, customProperties: {'thinking': true}));
                    _thinkingMsgIndex = 0;
                  } else {
                    final oldMsg = messages[_thinkingMsgIndex!];
                    messages[_thinkingMsgIndex!] = ChatMessage(user: AI, createdAt: oldMsg.createdAt, text: event.content, customProperties: {'thinking': true});
                  }
                  break;
                case LlmStreamEventType.response:
                  if (_answerMsgIndex == null) {
                    messages.insert(0, ChatMessage(user: AI, createdAt: DateTime.now(), text: event.content));
                    _answerMsgIndex = 0;
                  } else {
                    final oldMsg = messages[_answerMsgIndex!];
                    messages[_answerMsgIndex!] = ChatMessage(user: AI, createdAt: oldMsg.createdAt, text: event.content);
                  }
                  break;
                case LlmStreamEventType.fullResponse:
                  if (_answerMsgIndex != null) {
                    final oldMsg = messages[_answerMsgIndex!];
                    messages[_answerMsgIndex!] = ChatMessage(user: AI, createdAt: oldMsg.createdAt, text: event.content);
                  }
                  break;
                case LlmStreamEventType.error:
                  messages.insert(0, ChatMessage(user: AI, createdAt: DateTime.now(), text: 'Error: ${event.content}'));
                  break;
              }
            });
          });
        },
        messages: messages,
      ),

      
    );
  }

  List<Map<String, String>> _convertMessagesToApi(List<ChatMessage> chatMessages) {
    final List<Map<String, String>> api = [];
    for (final ctx in _pdfContexts) {
      api.add({'role': 'system', 'content': ctx});
    }
    api.addAll(chatMessages.reversed.map((msg) {
      final role = msg.user.id == user.id ? 'user' : 'assistant';
      return {'role': role, 'content': msg.text};
    }));
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
      print('[PDF] Extracted text length: \\${text.length}. Preview: \\${text.substring(0, text.length > 200 ? 200 : text.length)}');
      setState(() {
        _pdfContexts.add(text);
        messages.insert(
          0,
          ChatMessage(
            user: user,
            createdAt: DateTime.now(),
            text: '[PDF Attached] 📄 ${result.files.single.name}',
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _llmSubscription?.cancel();
    super.dispose();
  }
}