import 'package:go_router/go_router.dart';
import 'package:v1/pages/agent_page.dart';
import 'package:v1/pages/chat_page.dart';
import 'package:v1/pages/setup/hotspot_page.dart';
import 'package:v1/pages/voice_page.dart';
import 'package:v1/pages/vision_page.dart';
import 'package:v1/pages/dashboard.dart';
import 'package:v1/pages/network.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/chat'),
    GoRoute(path: '/chat', builder: (context, state) => LunaChatPage()),
    GoRoute(path: '/voice', builder: (context, state) => VoicePage()),
    GoRoute(path: '/vision', builder: (context, state) => VisionPage()),
    GoRoute(path: '/dashboard', builder: (context, state) => Dashboard()),
    GoRoute(path: '/agent', builder: (context, state) => AgentPage()),
    GoRoute(path: '/network', builder: (context, state) => NetworkPage()),
    GoRoute(path: '/hotspot-setup', builder: (context, state) => HotspotPage())
  ],
);
