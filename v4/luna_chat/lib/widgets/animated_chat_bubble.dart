import 'package:flutter/material.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';

class AnimatedChatBubble extends StatelessWidget {
  final String text;
  final bool isVisible;
  final Duration animationDuration;
  final double maxWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool hasGradient;
  final List<Color>? gradientColors;
  
  const AnimatedChatBubble({
    super.key,
    required this.text,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 600),
    this.maxWidth = 500,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.textStyle,
    this.padding,
    this.borderRadius,
    this.hasGradient = true,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: animationDuration,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.2),
        duration: animationDuration,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            gradient: hasGradient ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ?? [successBackground, successBorder],
            ) : null,
            color: hasGradient ? null : (backgroundColor ?? surfaceContainer),
            border: Border.all(
              color: borderColor ?? onboardingPrimary, 
              width: 2,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (borderColor ?? onboardingPrimary).withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(24),
          child: Text(
            text,
            style: textStyle ?? mainText.copyWith(
              fontSize: 18,
              color: textColor ?? onboardingSecondary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}