import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class HotspotSettingsButton extends StatelessWidget {
  const HotspotSettingsButton({super.key});

  Future<void> _openHotspotSettings() async {
    String url;
    if (Platform.isWindows) {
      url = 'ms-settings:network-hospot';
    } else if (Platform.isMacOS) {
      url = 'x-apple.systempreferences:com.apple.Sharing-Settings.extension';
    } else {
      // For other platforms, you might want to show a message or do nothing
      // Optionally, show an error message to the user
      return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Optionally, show an error message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _openHotspotSettings,
      icon: const Icon(Icons.wifi),
      label: const Text('Open Hotspot Settings'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
