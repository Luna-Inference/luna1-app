import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import '../widgets/chat_history_sidebar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For Timer

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
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _serverStatus = 'Error: ${response.statusCode}';
            _generationStatus = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverStatus = 'Offline';
          _generationStatus = '';
        });
      }
    }
  }

  Future<void> _getAIResponse() async {
    final url = Uri.parse('http://100.76.203.80:8080/v1/chat/completions'); // Ensure this matches the user's latest update if any
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'model': 'luna-small', // Ensure this model is available on your backend
      'messages': _apiMessages,
      'stream': false, // Non-streaming for simplicity first
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final assistantContent = responseData['choices'][0]['message']['content'].toString().trim();

        final assistantMessage = TextMessage(
          authorId: _assistant.id,
          createdAt: DateTime.now(),
          id: '${Random().nextInt(100000) + 1}', // Use a better ID generation in production
          text: assistantContent,
        );

        _chatController.insertMessage(assistantMessage);
        _apiMessages.add({'role': 'assistant', 'content': assistantContent});
      } else {
        final errorMessage = TextMessage(
          authorId: _systemUser.id,
          createdAt: DateTime.now(),
          id: '${Random().nextInt(100000) + 1}',
          text: 'Error: Failed to get response from AI. Status: ${response.statusCode} - ${response.body}',
        );
        _chatController.insertMessage(errorMessage);
        print('API Error: ${response.statusCode}');
        print('API Response: ${response.body}');
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
          child: Text(
            'S: $_serverStatus | G: $_generationStatus',
            style: TextStyle(fontSize: 10, color: colorScheme.onSurface),
          ),
        ),
      ),
    ],
  ),
);
  }
}