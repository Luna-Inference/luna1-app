import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:v1/pages/agent_page.dart';
import 'package:v1/pages/app_store.dart';
import 'package:v1/pages/network.dart';
import 'package:v1/pages/setup/hardware_setup.dart';
import 'package:v1/pages/setup/hotspot_page.dart';
import 'package:v1/pages/setup/luna_scan.dart';
import 'package:v1/themes/theme.dart';
import 'package:v1/themes/util.dart';
import 'package:v1/pages/chat_page.dart';
import 'package:v1/pages/dashboard.dart';
import 'package:v1/pages/home_page.dart';
import 'package:v1/pages/vision_page.dart';
import 'package:v1/pages/voice_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v1/config.dart';

// Global RouteObserver for navigation monitoring
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  AppConfig.llmIp = prefs.getString('llm_ip') ?? AppConfig.llmIp;
  runApp(const MyApp());
}

/// The route configuration.
final GoRouter _router = GoRouter(
  routes: <RouteBase>[

    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomePage();
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (BuildContext context, GoRouterState state) => LunaChatPage(),
    ),
    GoRoute(
      path: '/voice',
      builder: (BuildContext context, GoRouterState state) => const VoicePage(),
    ),
    GoRoute(
      path: '/vision',
      builder: (BuildContext context, GoRouterState state) => const VisionPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) => const Dashboard(),
    ),
    GoRoute(
      path: '/agent',
      builder: (BuildContext context, GoRouterState state) => AgentPage(),
    ),
    GoRoute(
      path: '/network',
      builder: (BuildContext context, GoRouterState state) => NetworkPage(),
    ),
    GoRoute(
      path:'/hotspot-setup',
      builder: (BuildContext context, GoRouterState state) => HotspotPage()
    ),
    GoRoute(
        path:'/',
        builder: (BuildContext context, GoRouterState state) => HardwareSetup()
    ),
    GoRoute(
        path:'/luna-scan',
        builder: (BuildContext context, GoRouterState state) => LunaScanPage()
    ),
    GoRoute(
        path:'/app-store',
        builder: (BuildContext context, GoRouterState state) => AppStore()
    ),


  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    TextTheme textTheme = createTextTheme(context, "Inter", "Inter");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Luna AI Suite',
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      debugShowCheckedModeBanner: false,
      //navigatorObservers: [routeObserver],
    );
  }
}