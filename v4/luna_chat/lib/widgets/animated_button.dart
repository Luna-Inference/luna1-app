import 'package:flutter/material.dart';
import 'package:luna_chat/themes/color.dart';
import 'package:luna_chat/themes/typography.dart';

class AnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isVisible;
  final Duration animationDuration;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final double? width;
  final double? elevation;
  
  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.isVisible,
    this.animationDuration = const Duration(milliseconds: 600),
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.width,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: animationDuration,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.2),
        duration: animationDuration,
        child: SizedBox(
          width: width ?? double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? onboardingPrimary,
              foregroundColor: foregroundColor ?? Colors.white,
              padding: padding ?? const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
                side: borderColor != null ? BorderSide(
                  color: borderColor!,
                  width: 2,
                ) : BorderSide.none,
              ),
              elevation: elevation ?? 0,
            ),
            child: Text(
              text,
              style: textStyle ?? mainText.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: foregroundColor ?? Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}