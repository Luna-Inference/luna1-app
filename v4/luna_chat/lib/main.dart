import 'package:flutter/material.dart';
import 'package:luna_chat/applications/user_dashboard.dart';
import 'package:luna_chat/functions/luna_scan.dart';
import 'package:luna_chat/screens/onboarding/onboarding_flow.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  // Initialize MediaKit before running the app
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luna',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        textTheme: TextTheme(
          bodyLarge: mainText,
          headlineLarge: headingText,
        ),
      ),
      home: 
       // UserDashboardApp()
      // TestScreen(),
      // LunaChatApp()
      OnboardingFlow()
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          child: Text('test'),
          onPressed: () async{
            final luna = await LunaScanner.findLuna();
            if (luna != null) {
              // Luna is connected and ready!
              // Make API calls to http://169.254.100.10:1309/your-endpoints
            }
          }
          ,
          )),
    );
  }
}