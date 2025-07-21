import 'package:flutter/material.dart';
import 'package:luna_chat/themes/typography.dart';
import 'package:luna_chat/themes/color.dart';

class OnboardingNameInputScreen extends StatefulWidget {
  final Function(String)? onNameSubmit;
  final VoidCallback? onTap;
  final String? initialName;
  final String buttonText;

  const OnboardingNameInputScreen({
    Key? key,
    this.onNameSubmit,
    this.onTap,
    this.initialName,
    this.buttonText = 'Continue',
  }) : super(key: key);

  @override
  State<OnboardingNameInputScreen> createState() => _OnboardingNameInputScreenState();
}

class _OnboardingNameInputScreenState extends State<OnboardingNameInputScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
      _isButtonEnabled = widget.initialName!.trim().isNotEmpty;
    }
    
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
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
    ));

    // Listen to text changes
    _nameController.addListener(_onTextChanged);

    // Start animation when screen loads
    _controller.forward();

    // Auto-focus the text field after animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onTextChanged() {
    setState(() {
      _isButtonEnabled = _nameController.text.trim().isNotEmpty;
    });
  }

  void _onSubmit() {
    if (_isButtonEnabled) {
      if (widget.onNameSubmit != null) {
        widget.onNameSubmit!(_nameController.text.trim());
      }
      if (widget.onTap != null) {
        widget.onTap!();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _focusNode.dispose();
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Welcome icon
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: buttonColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: buttonColor.withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 40,
                                color: buttonColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Main question
                            Text(
                              'How should we call you?',
                              style: headingText.copyWith(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            
                            // Subtitle
                            Text(
                              'Let\'s personalize your Luna experience',
                              style: headingText.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 48),
                            
                            // Name input field
                            Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: TextField(
                                controller: _nameController,
                                focusNode: _focusNode,
                                textAlign: TextAlign.center,
                                style: headingText.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Your name',
                                  hintStyle: headingText.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w300,
                                    color: buttonColor.withOpacity(0.5),
                                    letterSpacing: 0.5,
                                  ),
                                  border: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: buttonColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: buttonColor,
                                      width: 3,
                                    ),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: buttonColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _onSubmit(),
                              ),
                            ),
                            const SizedBox(height: 64),
                            
                            // Continue button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 200,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isButtonEnabled ? _onSubmit : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isButtonEnabled 
                                      ? buttonColor 
                                      : buttonColor.withOpacity(0.3),
                                  foregroundColor: whiteAccent,
                                  elevation: _isButtonEnabled ? 2 : 0,
                                  shadowColor: buttonColor.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  widget.buttonText,
                                  style: headingText.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: whiteAccent,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Helper text
                            const SizedBox(height: 24),
                            Text(
                              'You can always change this later',
                              style: headingText.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: buttonColor.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}