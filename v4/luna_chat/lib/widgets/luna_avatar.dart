import 'package:flutter/material.dart';
import 'package:luna_chat/themes/color.dart';

class LunaAvatar extends StatelessWidget {
  final double size;
  final String imagePath;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  
  const LunaAvatar({
    super.key,
    this.size = 120,
    this.imagePath = 'assets/onboarding/luna-intro.png',
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        border: showBorder ? Border.all(
          color: borderColor ?? onboardingPrimary,
          width: borderWidth,
        ) : null,
        boxShadow: showBorder ? [
          BoxShadow(
            color: (borderColor ?? onboardingPrimary).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((size / 2) - borderWidth),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}