import 'package:flutter/material.dart';

class ChatHistorySidebar extends StatefulWidget {
  const ChatHistorySidebar({super.key});

  @override
  State<ChatHistorySidebar> createState() => _ChatHistorySidebarState();
}

class _ChatHistorySidebarState extends State<ChatHistorySidebar> {
  // Dummy data for chat history
  final List<String> _chatHistory = [
    'Conversation with GPT-4',
    'Project Brainstorm',
    'Flutter Dev Help',
    'Last week\'s meeting',
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView.builder(
        itemCount: _chatHistory.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_chatHistory[index]),
            onTap: () {
              // Handle chat selection
              Navigator.pop(context); // Close the drawer
            },
          );
        },
      ),
    );
  }
}
