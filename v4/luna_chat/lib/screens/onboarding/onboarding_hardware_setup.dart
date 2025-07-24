import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';

class OnboardingHardwareSetupScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  
  const OnboardingHardwareSetupScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<OnboardingHardwareSetupScreen> createState() => _OnboardingHardwareSetupScreenState();
}

class _OnboardingHardwareSetupScreenState extends State<OnboardingHardwareSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _typingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentStep = 1; // 1 for power, 2 for network
  List<String> _typingTexts = ['', '', '', ''];
  List<bool> _showChatBubbles = [false, false, false, false];
  bool _showStepContent = false;
  bool _showNextButton = false;

  // Step 1 texts
  final List<String> _step1Texts = [
    "You'll need this black power adapter - it should be in your Luna box!",
    "1. Plug the big end into any wall outlet in your home",
    "2. Plug the small end into Luna - look for the round hole",
  ];

  // Step 2 texts  
  final List<String> _step2Texts = [
    "You'll need this cable - it looks like a thick phone charger!",
    "1. Plug one end into Luna - look for the rectangular hole", 
    "2. Plug the other end into your computer - find a similar hole",
  ];

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
    
    // Wait a bit, then show step content
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showStepContent = true;
      });
    }
    
    // Start showing chat bubbles and typing animations
    await Future.delayed(const Duration(milliseconds: 400));
    _startStepAnimations();
  }

  void _startStepAnimations() async {
    final texts = _currentStep == 1 ? _step1Texts : _step2Texts;
    
    for (int i = 0; i < texts.length; i++) {
      if (!mounted) return;
      
      // Show chat bubble
      setState(() {
        _showChatBubbles[i] = true;
      });
      
      // Start typing animation
      await Future.delayed(const Duration(milliseconds: 300));
      await _animateTyping(i, texts[i]);
      
      // Wait before next bubble
      await Future.delayed(const Duration(milliseconds: 600));
    }
    
    // Show next button after all animations
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showNextButton = true;
      });
    }
  }

  Future<void> _animateTyping(int index, String text) async {
    for (int i = 0; i <= text.length; i++) {
      if (mounted) {
        setState(() {
          _typingTexts[index] = text.substring(0, i);
        });
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
  }

  void _goToNextStep() {
    if (_currentStep == 1) {
      // Reset state for step 2
      setState(() {
        _currentStep = 2;
        _typingTexts = ['', '', '', ''];
        _showChatBubbles = [false, false, false, false];
        _showNextButton = false;
      });
      _startStepAnimations();
    } else {
      // Complete hardware setup
      if (widget.onContinue != null) {
        widget.onContinue!();
      }
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
                                  children: [
                                    // Step Header
                                    _buildStepHeader(),
                                    
                                    const SizedBox(height: 40),
                                    
                                    // Step Content
                                    if (_showStepContent) _buildStepContent(),
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

  Widget _buildStepHeader() {
    return Column(
      children: [
        // Step number badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF38b2ac),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Step $_currentStep of 2',
            style: mainText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Step title
        Text(
          _currentStep == 1 
            ? 'Plug in Your Luna Device'
            : 'Connect Luna to Your Computer',
          style: headingText.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF2d3748),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    return Column(
      children: [
        // Component introduction
        _buildComponentIntro(),
        
        const SizedBox(height: 40),
        
        // Connection steps
        _buildConnectionSteps(),
        
        const SizedBox(height: 40),
        
        // Final instructions and button
        _buildFinalInstructions(),
      ],
    );
  }

  Widget _buildComponentIntro() {
    return AnimatedOpacity(
      opacity: _showChatBubbles[0] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFf7fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0), width: 2),
        ),
        child: Column(
          children: [
            // Chat bubble first (consistent with connection steps)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFfef3c7), Color(0xFFfde68a)],
                ),
                border: Border.all(color: const Color(0xFFf59e0b), width: 2),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf59e0b).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _typingTexts[0],
                style: mainText.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF92400e),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Component image below (consistent format)
            Container(
              width: 240,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  _currentStep == 1 
                    ? 'assets/onboarding/power-supply-intro.png'
                    : 'assets/onboarding/network-cable-intro.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionSteps() {
    return Column(
      children: [
        // Step 1
        _buildConnectionStep(
          1, 
          _currentStep == 1 
            ? 'assets/onboarding/power-supply-to-wall.png'
            : 'assets/onboarding/luna-to-network-cable.png'
        ),
        
        const SizedBox(height: 24),
        
        // Step 2
        _buildConnectionStep(
          2,
          _currentStep == 1
            ? 'assets/onboarding/luna-to-power.png' 
            : 'assets/onboarding/network-cable-to-computer.png'
        ),
      ],
    );
  }

  Widget _buildConnectionStep(int stepIndex, String imagePath) {
    return AnimatedOpacity(
      opacity: _showChatBubbles[stepIndex] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFf7fafc),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFe2e8f0), width: 2),
        ),
        child: Column(
          children: [
            // Chat bubble first (top-down hierarchy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFfef3c7), Color(0xFFfde68a)],
                ),
                border: Border.all(color: const Color(0xFFf59e0b), width: 2),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFf59e0b).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _typingTexts[stepIndex],
                style: mainText.copyWith(
                  fontSize: 16,
                  color: const Color(0xFF92400e),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Step image below (clear hierarchy)
            Container(
              width: 240,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalInstructions() {
    return Column(
      children: [
        // Detailed instructions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFf7fafc),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF38b2ac), width: 4),
          ),
          child: Text(
            _currentStep == 1
              ? 'Look for a small red light on Luna that also turns green - if you see it, you\'re doing great! No light? Just push both plugs in a little harder until they feel snug.'
              : 'Push both ends in until you hear a "click" sound - that\'s how you know they\'re connected! Can\'t find the right hole on your computer? Check your Luna box for a small adapter piece.',
            style: mainText.copyWith(
              fontSize: 16,
              color: const Color(0xFF2d3748),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Next button
        AnimatedOpacity(
          opacity: _showNextButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: AnimatedSlide(
            offset: _showNextButton ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 500),
            child: ElevatedButton(
              onPressed: _goToNextStep,
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
                _currentStep == 1 
                  ? 'Next: Connect Device'
                  : 'Next: Wait for Luna',
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
    );
  }
}