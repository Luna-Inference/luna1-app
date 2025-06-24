import 'package:go_router/go_router.dart';
import 'package:v1/pages/chat_page.dart';
import 'package:v1/pages/voice_page.dart';
import 'package:v1/pages/vision_page.dart';
import 'package:v1/pages/dashboard.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/chat',
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => LunaChat(),
    ),
    GoRoute(
      path: '/voice',
      builder: (context, state) => const VoicePage(),
    ),
    GoRoute(
      path: '/vision',
      builder: (context, state) => const VisionPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const Dashboard(),
    ),
  ],
);
