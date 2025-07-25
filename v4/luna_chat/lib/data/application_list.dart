import 'package:flutter/material.dart';

class LunaApplication {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isComingSoon;

  const LunaApplication({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isComingSoon = false,
  });
}

class ApplicationList {
  static const List<LunaApplication> applications = [
    LunaApplication(
      title: 'Chat Interface',
      description: 'ChatGPT-like local AI',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF007AFF),
    ),
    LunaApplication(
      title: 'Expert Creation',
      description: 'Upload files for AI experts',
      icon: Icons.upload_file,
      color: Color(0xFF34C759),
    ),
    LunaApplication(
      title: 'Automation Tools',
      description: 'Email, CRM integration',
      icon: Icons.settings_applications,
      color: Color(0xFFFF9500),
      isComingSoon: true,
    ),
    LunaApplication(
      title: 'Voice Chat',
      description: 'Real-time voice AI',
      icon: Icons.mic,
      color: Color(0xFF5856D6),
      isComingSoon: true,
    ),
  ];
}