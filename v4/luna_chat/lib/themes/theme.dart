import 'package:flutter/material.dart';
import 'color.dart';
import 'typography.dart';

/// Luna App Theme Configuration
/// 
/// This file provides centralized theme configuration for the Luna application,
/// including colors, typography, and common widget themes.
class LunaTheme {
  
  // Chat Theme
  static ThemeData get chatTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundColor,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: primaryFontFamily,
    ),
  );

  // Dashboard Theme
  static ThemeData get dashboardTheme => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: dashboardBackground,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: primaryFontFamily,
    ),
  );

  // Chat Colors for flutter_chat_ui
  static LunaChatColors get chatColors => LunaChatColors(
    primary: buttonColor,
    onPrimary: backgroundColor,
    surface: backgroundColor,
    onSurface: whiteAccent,
    surfaceContainer: surfaceContainer,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainerHigh: surfaceContainerHigh,
  );

  // Common Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: buttonColor,
    foregroundColor: backgroundColor,
    textStyle: buttonText,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: onboardingPrimary,
    foregroundColor: Colors.white,
    textStyle: buttonText,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle get warningButton => ElevatedButton.styleFrom(
    backgroundColor: warningYellow,
    foregroundColor: warningText,
    textStyle: buttonText,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static ButtonStyle get successButton => ElevatedButton.styleFrom(
    backgroundColor: successGreen,
    foregroundColor: Colors.white,
    textStyle: buttonText,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // Card Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 25,
        offset: Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration get onboardingCardDecoration => BoxDecoration(
    color: onboardingBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: onboardingBorder, width: 2),
  );

  static BoxDecoration get warningCardDecoration => BoxDecoration(
    gradient: LinearGradient(colors: warningGradient),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: warningYellow, width: 2),
  );

  static BoxDecoration get successCardDecoration => BoxDecoration(
    gradient: LinearGradient(colors: successGradient),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: onboardingPrimary, width: 2),
  );

  // Input Decorations
  static InputDecoration get textFieldDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: onboardingBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: onboardingPrimary, width: 2),
    ),
    filled: true,
    fillColor: onboardingBackground,
    hintStyle: formInput.copyWith(color: onboardingTertiary),
  );

  // Badge Decorations
  static BoxDecoration get primaryBadge => BoxDecoration(
    color: buttonColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration get warningBadge => BoxDecoration(
    color: warningYellow.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration get successBadge => BoxDecoration(
    color: successGreen.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
  );
}

// Custom ChatColors class for flutter_chat_ui compatibility
class LunaChatColors {
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;

  const LunaChatColors({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
  });
}