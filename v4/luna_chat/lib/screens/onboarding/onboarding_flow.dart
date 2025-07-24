import 'package:flutter/material.dart';
import 'package:luna_chat/screens/onboarding/onboarding_hardware_setup.dart';
import 'package:luna_chat/screens/onboarding/onboarding_device_connected.dart';
import 'package:luna_chat/screens/onboarding/onboarding_user_name.dart';
import 'package:luna_chat/screens/onboarding/onboarding_instruction_manual_check.dart';
import 'package:luna_chat/screens/onboarding/onboarding_scanning_luna.dart';
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

  void _onManualCheckYes() {
    // If user already set up hardware, skip to device scanning
    setState(() {
      _currentStep = 3;
    });
  }

  void _onManualCheckNo() {
    // If user needs help, go to hardware setup
    setState(() {
      _currentStep = 2;
    });
  }

  void _onHardwareSetupComplete() {
    setState(() {
      _currentStep = 3; // This will now be OnboardingScanningLunaScreen
    });
  }

  void _onDeviceConnected() {
    setState(() {
      _currentStep = 4; // This will now be DeviceConnectedScreen
    });
  }

  void _onLunaScanned() {
    setState(() {
      _currentStep = 5; // This will now be OnboardingNameInputScreen
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
        return OnboardingInstructionManualCheckScreen(
          onYesAlreadySetup: _onManualCheckYes,
          onNoNeedHelp: _onManualCheckNo,
        );
      case 2:
        return OnboardingHardwareSetupScreen(
          onContinue: _onHardwareSetupComplete,
        );
      case 3:
        return OnboardingScanningLunaScreen(
          onDeviceFound: _onLunaScanned,
          onScanFailed: _onManualCheckNo, // Option to go back to manual check if scan fails
        );
      case 4:
        return DeviceConnectedScreen(
          onComplete: _onDeviceConnected,
        );
      case 5:
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