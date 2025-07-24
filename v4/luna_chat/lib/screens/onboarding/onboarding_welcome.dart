import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  final VoidCallback? onGetStarted;
  
  const OnboardingWelcomeScreen({super.key, this.onGetStarted});

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _typingText = '';
  final String _fullText = "Hi there! Let's get your Luna AI assistant set up. Don't worry - we'll walk through this step by step, and it's easier than it looks!";
  bool _showChatBubble = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    // Start sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start main content animation
    _fadeController.forward();
    
    // Wait a bit, then show chat bubble
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      _showChatBubble = true;
    });
    
    // Start typing animation after bubble appears
    await Future.delayed(const Duration(milliseconds: 300));
    _startTypingAnimation();
  }

  void _startTypingAnimation() async {
    for (int i = 0; i <= _fullText.length; i++) {
      if (mounted) {
        setState(() {
          _typingText = _fullText.substring(0, i);
        });
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    
    // Show button after typing completes
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showButton = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _typingController.dispose();
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
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
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
                                constraints: const BoxConstraints(maxWidth: 1200),
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
                                        color: const Color(0xFF2d3748),
                                        letterSpacing: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Subtitle
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 500),
                                      child: Text(
                                        'Your private AI assistant that runs completely on your device',
                                        style: mainText.copyWith(
                                          fontSize: 18,
                                          color: const Color(0xFF4a5568),
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Device with chat bubble
                                    _buildDeviceWithChatBubble(),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Get Started button
                                    AnimatedOpacity(
                                      opacity: _showButton ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 500),
                                      child: AnimatedSlide(
                                        offset: _showButton ? Offset.zero : const Offset(0, 0.2),
                                        duration: const Duration(milliseconds: 500),
                                        child: ElevatedButton(
                                          onPressed: widget.onGetStarted,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF38b2ac),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'Get Started',
                                            style: mainText.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
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

  Widget _buildDeviceWithChatBubble() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;
    
    if (isLargeScreen) {
      // Large screen: device with chat bubble on the right (like v4.1)
      return SizedBox(
        height: 300, // Define explicit height
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Luna device image
            SizedBox(
              width: 300,
              child: Image.asset(
                'assets/onboarding/luna-intro.png',
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Chat bubble positioned to the right
            if (_showChatBubble)
              Expanded(
                child: AnimatedOpacity(
                  opacity: _showChatBubble ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedSlide(
                    offset: _showChatBubble ? Offset.zero : const Offset(0, 0.1),
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      margin: const EdgeInsets.only(top: 0),
                      child: _buildChatBubble(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    } else {
      // Small screen: device on top, chat bubble below (stacked vertically)
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
          
          // Chat bubble below device
          if (_showChatBubble) ...[
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _showChatBubble ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: _showChatBubble ? Offset.zero : const Offset(0, 0.1),
                duration: const Duration(milliseconds: 500),
                child: _buildChatBubble(),
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildChatBubble() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1024;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: isLargeScreen ? 420 : 350,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFe2e8f0), width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Text(
        _typingText,
        style: mainText.copyWith(
          fontSize: 16,
          color: const Color(0xFF4a5568),
          height: 1.5,
        ),
      ),
    );
  }
}

