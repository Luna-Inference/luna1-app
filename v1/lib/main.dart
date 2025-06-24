import 'package:flutter/material.dart';
import 'package:v1/pages/chat_page2.dart';
import 'package:v1/pages/dashboard.dart';
import 'package:v1/pages/home_page.dart';
import 'package:v1/pages/vision_page.dart';
import 'package:v1/pages/voice_page.dart';
import 'package:clarity_flutter/clarity_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna AI Suite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/chat': (context) => Basic(),
        '/voice': (context) => const VoicePage(),
        '/vision': (context) => const VisionPage(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}
