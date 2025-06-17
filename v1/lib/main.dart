import 'package:flutter/material.dart';
import 'package:v1/app_router.dart';
import 'package:clarity_flutter/clarity_flutter.dart';


void main() {
  final config = ClarityConfig(
      projectId: "s0pvt1yvgo",
      userId: "your_user_id",
    logLevel: LogLevel.Info,
  );

  runApp(ClarityWidget(
    app: MyApp(),
    clarityConfig: config,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

