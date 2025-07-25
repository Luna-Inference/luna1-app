import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/widgets/luna_avatar.dart';
import 'package:luna_chat/widgets/animated_chat_bubble.dart';
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
  State<OnboardingInstructionManualCheckScreen> createState() => _OnboardingInstructionManualCheckScreenState();
}

class _OnboardingInstructionManualCheckScreenState extends State<OnboardingInstructionManualCheckScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _typingText = '';
  final String _fullText = "Before we begin, I need to know: Have you already set up your Luna hardware following the paper instruction manual that came in the box?";
  bool _showLunaAvatar = false;
  bool _showChatBubble = false;
  bool _showButtons = false;

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
    
    // Wait a bit, then show Luna avatar
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showLunaAvatar = true;
      });
    }
    
    // Show chat bubble
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _showChatBubble = true;
      });
    }
    
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
        await Future.delayed(const Duration(milliseconds: 25));
      }
    }
    
    // Show buttons after typing completes
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showButtons = true;
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
                                constraints: const BoxConstraints(maxWidth: 800),
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
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Hardware Check Chat
                                    _buildHardwareCheckChat(),
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

  Widget _buildHardwareCheckChat() {
    return Column(
      children: [
        // Luna Avatar
        AnimatedOpacity(
          opacity: _showLunaAvatar ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: AnimatedSlide(
            offset: _showLunaAvatar ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 600),
            child: const LunaAvatar(),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Chat Bubble
        AnimatedChatBubble(
          text: _typingText,
          isVisible: _showChatBubble,
        ),
        
        const SizedBox(height: 32),
        
        // Response Buttons
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              // Yes Button
              AnimatedButton(
                text: 'Yes, it\'s already set up',
                onPressed: widget.onYesAlreadySetup,
                isVisible: _showButtons,
                backgroundColor: successAccent,
                borderColor: successDark,
              ),
              
              const SizedBox(height: 16),
              
              // No Button
              AnimatedButton(
                text: 'No, I need help setting it up',
                onPressed: widget.onNoNeedHelp,
                isVisible: _showButtons,
                backgroundColor: errorBackground,
                foregroundColor: onboardingSecondary,
                borderColor: errorAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}