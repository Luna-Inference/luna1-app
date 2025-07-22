import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';

import 'package:media_kit/media_kit.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  Player? _preloadPlayer;

  @override
  void initState() {
    super.initState();
    // Preload the video for the hardware setup screen
    _preloadVideo();
  }

  Future<void> _preloadVideo() async {
    try {
      _preloadPlayer = Player();
      await _preloadPlayer!.open(Media('asset:///assets/onboarding/setup_480p.mp4'));
      print('✅ Video preloaded successfully');
    } catch (e) {
      print('❌ Video preload failed: $e');
    }
  }

  @override
  void dispose() {
    _preloadPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your existing welcome screen build method
    return Scaffold(
      // ... your welcome screen UI
    );
  }
}

// 3. ALTERNATIVE: If you don't want to modify the welcome screen,
// you can add preloading to the OnboardingFlow:

// In onboarding_flow.dart, add this to the _OnboardingFlowState class:

