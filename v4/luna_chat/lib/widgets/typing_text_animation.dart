import 'package:flutter/material.dart';

class TypingTextAnimation extends StatefulWidget {
  final String fullText;
  final TextStyle textStyle;
  final Duration characterDelay;
  final VoidCallback? onComplete;
  final Duration startDelay;
  
  const TypingTextAnimation({
    super.key,
    required this.fullText,
    required this.textStyle,
    this.characterDelay = const Duration(milliseconds: 30),
    this.onComplete,
    this.startDelay = Duration.zero,
  });

  @override
  State<TypingTextAnimation> createState() => _TypingTextAnimationState();
}

class _TypingTextAnimationState extends State<TypingTextAnimation> {
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  Future<void> _startTypingAnimation() async {
    // Wait for start delay
    await Future.delayed(widget.startDelay);
    
    for (int i = 0; i <= widget.fullText.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _displayText = widget.fullText.substring(0, i);
      });
      
      if (i < widget.fullText.length) {
        await Future.delayed(widget.characterDelay);
      }
    }
    
    // Call completion callback
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style: widget.textStyle,
      textAlign: TextAlign.center,
    );
  }
}