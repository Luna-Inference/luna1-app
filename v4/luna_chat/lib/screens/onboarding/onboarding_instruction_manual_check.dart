import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/widgets/luna_avatar.dart';
import 'package:luna_chat/widgets/animated_button.dart';

class OnboardingInstructionManualCheckScreen extends StatefulWidget {
  final VoidCallback? onYesAlreadySetup;
  final VoidCallback? onNoNeedHelp;

  const OnboardingInstructionManualCheckScreen({
    super.key,
    this.onYesAlreadySetup,
    this.onNoNeedHelp,
  });

  @override
  State<OnboardingInstructionManualCheckScreen> createState() =>
      _OnboardingInstructionManualCheckScreenState();
}

class _OnboardingInstructionManualCheckScreenState
    extends State<OnboardingInstructionManualCheckScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String _mainText =
      "Before we begin, I need to know: Have you already set up your Luna hardware following the paper instruction manual that came in the box?";
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    // Start sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start main content animation
    _fadeController.forward();

    // Wait for fade in, then show buttons
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _showButtons = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Main content with animations (title, image, text)
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 800,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Step Header
                                    Text(
                                      'Quick Hardware Check',
                                      style: headingText.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w400,
                                        color: onboardingSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 32),
                                    // Luna device image
                                    SizedBox(
                                      width: 600,
                                      child: Image.asset(
                                        'assets/onboarding/instruction-manual.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Main text
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 550,
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        _mainText,
                                        style: mainText.copyWith(
                                          fontSize: 18,
                                          color: onboardingTertiary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Response Buttons
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AnimatedButton(
                                text: 'Yes',
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onYesAlreadySetup,
                                isVisible: _showButtons,
                                backgroundColor: successAccent,
                                foregroundColor: Colors.white,
                                borderColor: successDark,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AnimatedButton(
                                text: 'No',
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: widget.onNoNeedHelp,
                                isVisible: _showButtons,
                                backgroundColor: errorAccent,
                                foregroundColor: Colors.white,
                                borderColor: errorAccent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
