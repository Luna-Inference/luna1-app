import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';

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
                                        color: const Color(0xFF2d3748),
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
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: const Color(0xFF38b2ac),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38b2ac).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(57),
                child: Image.asset(
                  'assets/onboarding/luna-intro.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Chat Bubble
        AnimatedOpacity(
          opacity: _showChatBubble ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: AnimatedSlide(
            offset: _showChatBubble ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 600),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFe6fffa), Color(0xFFb2f5ea)],
                ),
                border: Border.all(color: const Color(0xFF38b2ac), width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38b2ac).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Text(
                _typingText,
                style: mainText.copyWith(
                  fontSize: 18,
                  color: const Color(0xFF2d3748),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Response Buttons
        AnimatedOpacity(
          opacity: _showButtons ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: AnimatedSlide(
            offset: _showButtons ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 600),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // Yes Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onYesAlreadySetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF68d391),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFF38a169),
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes, it\'s already set up',
                        style: mainText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // No Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onNoNeedHelp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfed7d7),
                        foregroundColor: const Color(0xFF2d3748),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFfc8181),
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'No, I need help setting it up',
                        style: mainText.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2d3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}