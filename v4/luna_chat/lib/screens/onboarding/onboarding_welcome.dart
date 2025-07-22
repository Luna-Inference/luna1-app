import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:media_kit/media_kit.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Player? _preloadPlayer;  // Video preloading disabled

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Start animation when screen loads
    _controller.forward();
    
    // Video preloading disabled
    // _preloadVideo();
  }

  // Video preloading disabled
  // Future<void> _preloadVideo() async {
  //   try {
  //     _preloadPlayer = Player();
  //     await _preloadPlayer!.open(Media('asset:///assets/onboarding/setup_480p.mp4'));
  //     debugPrint('✅ Video preloaded successfully');
  //   } catch (e) {
  //     debugPrint('❌ Video preload failed: $e');
  //   }
  // }

  @override
  void dispose() {
    _controller.dispose();
    // _preloadPlayer?.dispose();  // Video preloading disabled
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              whiteAccent,
              buttonColor,
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: headingText.copyWith(
                          fontSize: 48,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'to a private AI experience',
                        style: headingText.copyWith(
                          fontSize: 24,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// 3. ALTERNATIVE: If you don't want to modify the welcome screen,
// you can add preloading to the OnboardingFlow:

// In onboarding_flow.dart, add this to the _OnboardingFlowState class:

