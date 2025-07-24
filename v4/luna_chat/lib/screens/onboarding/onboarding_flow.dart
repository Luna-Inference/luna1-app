import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:luna_chat/screens/onboarding/onboarding_hardware_setup.dart';
import 'package:luna_chat/screens/onboarding/onboarding_device_connected.dart';
import 'package:luna_chat/screens/onboarding/onboarding_user_name.dart';
import 'package:luna_chat/applications/chat.dart';
import 'package:media_kit/media_kit.dart';
import 'onboarding_welcome.dart';

class OnboardingFlow extends StatefulWidget {
  final Function()? onComplete;
  
  const OnboardingFlow({
    Key? key,
    this.onComplete,
  }) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  String? _userName;

  Timer? _hardwareSetupTimer;
  Player? _preloadPlayer;

@override
void initState() {
  super.initState();
  // Preload video when onboarding flow starts
  _preloadVideo();
  
  // Your existing timer code...
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) {
      setState(() {
        _currentStep = 1;
      });
    }
  });
}

Future<void> _preloadVideo() async {
  try {
    //_preloadPlayer = Player();
    //await _preloadPlayer!.open(Media('asset:///assets/onboarding/setup_480p.mp4'));
    print('✅ Video preloaded for hardware setup');
  } catch (e) {
    print('❌ Video preload failed: $e');
  }
}

@override
void dispose() {
  _hardwareSetupTimer?.cancel();
  _preloadPlayer?.dispose(); // Don't forget to dispose
  super.dispose();
}

  void _navigateToChat() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LunaChatApp(),
        ),
      );
    }
  }

  void _onDeviceConnected() {
    if (mounted) {
      setState(() {
        _currentStep = 2;
      });
      // After 3 seconds on the connected screen, move to username screen
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _currentStep = 3;
          });
        }
      });
    }
  }

  void _onNameSubmitted(String name) {
    setState(() {
      _userName = name;
      // Here you can add navigation to the main app or next screen
      // For example: Navigator.pushReplacement(...)
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return const OnboardingWelcomeScreen();
      case 1:
        return OnboardingHardwareSetupScreen(
          onContinue: _onDeviceConnected,
        );
      case 2:

        print('currently on connected screem');
        return DeviceConnectedScreen(
          onComplete: () {
            setState(() {
              _currentStep = 3; // Move to username screen
            });
          },
        );
      case 3:
        return OnboardingNameInputScreen(
          initialName: _userName,
          onNameSubmit: _onNameSubmitted,
          onTap: _navigateToChat,
          buttonText: 'Get Started',
        );
      default:
        return const OnboardingWelcomeScreen();
    }
  }
}