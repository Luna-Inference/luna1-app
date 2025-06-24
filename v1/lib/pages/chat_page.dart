import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

ChatUser user = ChatUser(
  id: '1',
  firstName: 'Thomas',
);

ChatUser AI = ChatUser(
  id: '2',
  firstName: 'Luna',
);

class Basic extends StatefulWidget {
  @override
  _BasicState createState() => _BasicState();
}

class _BasicState extends State<Basic> {


  List<ChatMessage> messages = <ChatMessage>[
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic example'),
      ),
      body: DashChat(
        currentUser: user,
        onSend: (ChatMessage m) {
          setState(() {
            messages.insert(0, m);
            messages.insert(0,
              ChatMessage(user: AI, createdAt: DateTime.now(), text: 'thinking message')
            );
            messages.insert(0,
                ChatMessage(user: AI, createdAt: DateTime.now(), text: 'main message')
            );
          });
        },
        messages: messages,
      ),
    );
  }
}