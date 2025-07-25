import 'package:flutter/material.dart';
import 'package:luna_chat/screens/onboarding/onboarding_hardware_setup.dart';
import 'package:luna_chat/screens/onboarding/onboarding_user_name.dart';
import 'package:luna_chat/screens/onboarding/onboarding_instruction_manual_check.dart';
import 'package:luna_chat/screens/onboarding/onboarding_scanning_luna.dart';
import 'package:luna_chat/applications/user_dashboard.dart';
import 'package:luna_chat/data/user_name.dart';
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
  }

  void _navigateToDashboard() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UserDashboardApp(),
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
      _currentStep = 3; 
    });
  }


  void _onLunaScanned() {
    setState(() {
      _currentStep = 4; // This will now be OnboardingNameInputScreen
    });
  }

  void _onNameSubmitted(String name) async {
    setState(() {
      _userName = name;
    });
    
    // Save the user name to SharedPreferences
    final success = await saveUserName(name);
    
    if (success) {
      _navigateToDashboard();
    } else {
      // Handle save error - could show a dialog or retry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save user name. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        return OnboardingNameInputScreen(
          initialName: _userName,
          onNameSubmit: _onNameSubmitted,
          onTap: _navigateToDashboard,
          buttonText: 'Get Started',
        );
      default:
        return OnboardingWelcomeScreen(
          onGetStarted: _onWelcomeGetStarted,
        );
    }
  }
}