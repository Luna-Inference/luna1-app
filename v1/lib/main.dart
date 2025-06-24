import 'package:flutter/material.dart';
import 'package:v1/themes/theme.dart';
import 'package:v1/pages/chat_page.dart';
import 'package:v1/pages/dashboard.dart';
import 'package:v1/pages/home_page.dart';
import 'package:v1/pages/vision_page.dart';
import 'package:v1/pages/voice_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Luna AI Suite',
      theme: MaterialTheme(ThemeData.light().textTheme).light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => LunaChatPage(),
        '/voice': (context) => const VoicePage(),
        '/vision': (context) => const VisionPage(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}
