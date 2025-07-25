import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/widgets/onboarding_step_block.dart';

class OnboardingHardwareSetupScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const OnboardingHardwareSetupScreen({super.key, this.onContinue});

  @override
  State<OnboardingHardwareSetupScreen> createState() =>
      _OnboardingHardwareSetupScreenState();
}

class _OnboardingHardwareSetupScreenState
    extends State<OnboardingHardwareSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // No step state needed
  bool _showStepContent = false;
  bool _showFinalInstructions = false;
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

    // Wait a bit, then show step content (steps/images)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _showStepContent = true;
      });
    }
    // Wait, then show final instructions
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _showFinalInstructions = true;
      });
    }
    // Wait, then show button
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _showNextButton = true;
      });
    }
  }

  void _goToNextStep() {
    // Always go to next page
    if (widget.onContinue != null) {
      widget.onContinue!();
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
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
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
                                // Remove maxWidth constraint to allow full width
                                child: Column(
                                  children: [
                                    // Page Title
                                    Text(
                                      'Hardware Setup',
                                      style: headingText.copyWith(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2d3748),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 40),
                                    // Step Content (steps/images)
                                    AnimatedOpacity(
                                      opacity: _showStepContent ? 1.0 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      child:
                                          _showStepContent
                                              ? _buildStepContent()
                                              : const SizedBox.shrink(),
                                    ),
                                    // Next/Completed button
                                    const SizedBox(height: 32),
                                    AnimatedOpacity(
                                      opacity: _showNextButton ? 1.0 : 0.0,
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      child:
                                          _showNextButton
                                              ? _buildCompletedButton()
                                              : const SizedBox.shrink(),
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

  // Step header removed

  Widget _buildStepContent() {
    return Column(
      children: [
        // Only show the step blocks
        _buildConnectionSteps(),
        const SizedBox(height: 40),
        // Final instructions and button
      ],
    );
  }

  Widget _buildConnectionSteps() {
    final List<Map<String, dynamic>> steps = [
      {
        'step': '1',
        'title': 'Power up Luna',
        'desc':
            'Using the included power supply, plug in Luna to a wall outlet.',
        'images': [
          'assets/onboarding/luna-to-power.png',
          'assets/onboarding/power-supply-to-wall.png',
        ],
        'color': '#2563eb', // blue
        'light': '#dbeafe',
      },
      {
        'step': '2',
        'title': 'Connect Luna to Computer',
        'desc':
            'Using the included network cable, connect Luna to your computer.',
        'images': [
          'assets/onboarding/luna-to-network-cable.png',
          'assets/onboarding/network-cable-to-computer.png',
        ],
        'color': '#f59e0b', // yellow
        'light': '#fef3c7',
      },
      {
        'step': '3',
        'title': 'Wait for Luna to boot',
        'desc':
            'Look for a small red light on Luna that turns green. If you see it, you’re doing great! No light? Push both plugs in a little harder until they feel snug.',
        'images': ['assets/onboarding/luna-face.png'],
        'color': '#10b981', // green
        'light': '#d1fae5',
      },
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;
        return SingleChildScrollView(
          scrollDirection: isWide ? Axis.horizontal : Axis.vertical,
          child:
              isWide
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        steps.map((step) {
                          final Color mainColor = Color(
                            int.parse('0xFF${step['color']!.substring(1)}'),
                          );
                          final Color lightColor = Color(
                            int.parse('0xFF${step['light']!.substring(1)}'),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            child: OnboardingStepBlock(
                              step: step['step']!,
                              title: step['title']!,
                              desc: step['desc']!,
                              images: List<String>.from(step['images']),
                              mainColor: mainColor,
                              lightColor: lightColor,
                            ),
                          );
                        }).toList(),
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        steps.map((step) {
                          final Color mainColor = Color(
                            int.parse('0xFF${step['color']!.substring(1)}'),
                          );
                          final Color lightColor = Color(
                            int.parse('0xFF${step['light']!.substring(1)}'),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 0,
                            ),
                            child: OnboardingStepBlock(
                              step: step['step']!,
                              title: step['title']!,
                              desc: step['desc']!,
                              images: List<String>.from(step['images']),
                              mainColor: mainColor,
                              lightColor: lightColor,
                            ),
                          );
                        }).toList(),
                  ),
        );
      },
    );
  }

  Widget _buildCompletedButton() {
    return ElevatedButton(
      onPressed: _goToNextStep,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38b2ac),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        'Completed',
        style: mainText.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
