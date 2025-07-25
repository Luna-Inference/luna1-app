import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/widgets/animated_button.dart';
import 'package:luna_chat/themes/color.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;

  const OnboardingWelcomeScreen({super.key, this.onGetStarted});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showButton = false;

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

    // Wait a bit, then show button
    await Future.delayed(const Duration(milliseconds: 1000));
    _showButtonDirectly();
  }

  void _showButtonDirectly() async {
    // Show button directly
    if (mounted) {
      setState(() {
        _showButton = true;
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
                      // Main content with animations
                      AnimatedBuilder(
                        animation: _fadeController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 1200,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Title
                                    Text(
                                      'Meet Luna',
                                      style: headingText.copyWith(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w300,
                                        color: onboardingSecondary,
                                        letterSpacing: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),

                                    const SizedBox(height: 16),

                                    // Subtitle
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 500,
                                      ),
                                      child: Text(
                                        'Your private AI assistant that runs completely on your device',
                                        style: mainText.copyWith(
                                          fontSize: 18,
                                          color: onboardingTertiary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // Luna device image
                                    _buildDeviceImage(),

                                    const SizedBox(height: 40),

                                    // Setup button (styled like Yes/No buttons)
                                    IntrinsicWidth(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 180,
                                        ),
                                        child: AnimatedButton(
                                          text: 'Get Started',
                                          icon: const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                          ),
                                          onPressed: widget.onGetStarted,
                                          isVisible: _showButton,
                                          animationDuration: const Duration(
                                            milliseconds: 500,
                                          ),
                                          backgroundColor: onboardingPrimary,
                                          foregroundColor: Colors.white,
                                          borderColor: onboardingPrimary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                            horizontal: 32,
                                          ),
                                          textStyle: mainText.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                          width: null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

  Widget _buildDeviceImage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Luna device image
        SizedBox(
          width: 300,
          child: Image.asset(
            'assets/onboarding/luna-intro.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
