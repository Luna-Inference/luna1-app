import 'package:flutter/material.dart';
import 'package:luna_chat/screens/onboarding/onboarding_hardware_setup.dart';
import 'package:luna_chat/screens/onboarding/onboarding_device_connected.dart';
import 'package:luna_chat/screens/onboarding/onboarding_user_name.dart';
import 'package:luna_chat/applications/chat.dart';
import 'onboarding_welcome.dart';

class OnboardingFlow extends StatefulWidget {
  final Function()? onComplete;
  
  const OnboardingFlow({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentStep = 0;
  String? _userName;

  @override
  void initState() {
    super.initState();
    // Start with welcome screen - no timers needed
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

  void _onWelcomeGetStarted() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _onHardwareSetupComplete() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _onDeviceConnected() {
    setState(() {
      _currentStep = 3;
    });
  }

  void _onNameSubmitted(String name) {
    setState(() {
      _userName = name;
    });
    _navigateToChat();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return OnboardingWelcomeScreen(
          onGetStarted: _onWelcomeGetStarted,
        );
      case 1:
        return OnboardingHardwareSetupScreen(
          onContinue: _onHardwareSetupComplete,
        );
      case 2:
        return DeviceConnectedScreen(
          onComplete: _onDeviceConnected,
        );
      case 3:
        return OnboardingNameInputScreen(
          initialName: _userName,
          onNameSubmit: _onNameSubmitted,
          onTap: _navigateToChat,
          buttonText: 'Get Started',
        );
      default:
        return OnboardingWelcomeScreen(
          onGetStarted: _onWelcomeGetStarted,
        );
    }
  }
}