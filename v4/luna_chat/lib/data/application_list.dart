import 'package:flutter/material.dart';
import 'package:luna_chat/applications/chat.dart';
import 'package:luna_chat/themes/color.dart';

class LunaApplication {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget? widget;

  const LunaApplication({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.widget,
      }); 
}

class ApplicationList {
  static final List<LunaApplication> applications = [
    LunaApplication(
      title: 'Chat Interface',
      description: 'ChatGPT-like local AI',
      icon: Icons.chat_bubble_outline,
      color: chatBlue,
      widget: LunaChatApp(),
    ),
    LunaApplication(
      title: 'Expert Creation',
      description: 'Upload files for AI experts',
      icon: Icons.upload_file,
      color: expertGreen,
    ),
    LunaApplication(
      title: 'Automation Tools',
      description: 'Email, CRM integration',
      icon: Icons.settings_applications,
      color: automationOrange,
    ),
    LunaApplication(
      title: 'Voice Chat',
      description: 'Real-time voice AI',
      icon: Icons.mic,
      color: voicePurple,
    ),
  ];
}