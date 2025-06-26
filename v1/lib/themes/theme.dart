import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff006874),
      surfaceTint: Color(0xff006874),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff9eeffd),
      onPrimaryContainer: Color(0xff004f58),
      secondary: Color(0xff4a6267),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffcde7ec),
      onSecondaryContainer: Color(0xff334b4f),
      tertiary: Color(0xff525e7d),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffdae2ff),
      onTertiaryContainer: Color(0xff3b4665),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff171d1e),
      onSurfaceVariant: Color(0xff3f484a),
      outline: Color(0xff6f797b),
      outlineVariant: Color(0xffbfc8ca),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff82d3e1),
      primaryFixed: Color(0xff9eeffd),
      onPrimaryFixed: Color(0xff001f24),
      primaryFixedDim: Color(0xff82d3e1),
      onPrimaryFixedVariant: Color(0xff004f58),
      secondaryFixed: Color(0xffcde7ec),
      onSecondaryFixed: Color(0xff051f23),
      secondaryFixedDim: Color(0xffb1cbd0),
      onSecondaryFixedVariant: Color(0xff334b4f),
      tertiaryFixed: Color(0xffdae2ff),
      onTertiaryFixed: Color(0xff0e1a37),
      tertiaryFixedDim: Color(0xffbac6ea),
      onTertiaryFixedVariant: Color(0xff3b4665),
      surfaceDim: Color(0xffd5dbdc),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f6),
      surfaceContainer: Color(0xffe9eff0),
      surfaceContainerHigh: Color(0xffe3e9ea),
      surfaceContainerHighest: Color(0xffdee3e5),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003c44),
      surfaceTint: Color(0xff006874),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff197884),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff223a3e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff597176),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff2a3553),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff616c8d),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff0c1213),
      onSurfaceVariant: Color(0xff2f3839),
      outline: Color(0xff4b5456),
      outlineVariant: Color(0xff656f71),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff82d3e1),
      primaryFixed: Color(0xff197884),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff005e69),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff597176),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff41595d),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff616c8d),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff495473),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc2c7c9),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff5f6),
      surfaceContainer: Color(0xffe3e9ea),
      surfaceContainerHigh: Color(0xffd8dedf),
      surfaceContainerHighest: Color(0xffcdd3d4),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003138),
      surfaceTint: Color(0xff006874),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff00515b),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff173034),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff354d51),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff202b48),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff3d4867),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff5fafb),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff252e2f),
      outlineVariant: Color(0xff424b4d),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2b3133),
      inversePrimary: Color(0xff82d3e1),
      primaryFixed: Color(0xff00515b),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003940),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff354d51),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff1e363a),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff3d4867),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff27324f),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb4babb),
      surfaceBright: Color(0xfff5fafb),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffecf2f3),
      surfaceContainer: Color(0xffdee3e5),
      surfaceContainerHigh: Color(0xffd0d5d7),
      surfaceContainerHighest: Color(0xffc2c7c9),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff82d3e1),
      surfaceTint: Color(0xff82d3e1),
      onPrimary: Color(0xff00363d),
      primaryContainer: Color(0xff004f58),
      onPrimaryContainer: Color(0xff9eeffd),
      secondary: Color(0xffb1cbd0),
      onSecondary: Color(0xff1c3438),
      secondaryContainer: Color(0xff334b4f),
      onSecondaryContainer: Color(0xffcde7ec),
      tertiary: Color(0xffbac6ea),
      onTertiary: Color(0xff24304d),
      tertiaryContainer: Color(0xff3b4665),
      onTertiaryContainer: Color(0xffdae2ff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffdee3e5),
      onSurfaceVariant: Color(0xffbfc8ca),
      outline: Color(0xff899294),
      outlineVariant: Color(0xff3f484a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff006874),
      primaryFixed: Color(0xff9eeffd),
      onPrimaryFixed: Color(0xff001f24),
      primaryFixedDim: Color(0xff82d3e1),
      onPrimaryFixedVariant: Color(0xff004f58),
      secondaryFixed: Color(0xffcde7ec),
      onSecondaryFixed: Color(0xff051f23),
      secondaryFixedDim: Color(0xffb1cbd0),
      onSecondaryFixedVariant: Color(0xff334b4f),
      tertiaryFixed: Color(0xffdae2ff),
      onTertiaryFixed: Color(0xff0e1a37),
      tertiaryFixedDim: Color(0xffbac6ea),
      onTertiaryFixedVariant: Color(0xff3b4665),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff343a3b),
      surfaceContainerLowest: Color(0xff090f10),
      surfaceContainerLow: Color(0xff171d1e),
      surfaceContainer: Color(0xff1b2122),
      surfaceContainerHigh: Color(0xff252b2c),
      surfaceContainerHighest: Color(0xff303637),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xff98e9f7),
      surfaceTint: Color(0xff82d3e1),
      onPrimary: Color(0xff002a30),
      primaryContainer: Color(0xff499ca9),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc7e1e6),
      onSecondary: Color(0xff10292d),
      secondaryContainer: Color(0xff7c959a),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffd1dbff),
      onTertiary: Color(0xff192541),
      tertiaryContainer: Color(0xff8590b2),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd4dee0),
      outline: Color(0xffaab4b5),
      outlineVariant: Color(0xff889294),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff005059),
      primaryFixed: Color(0xff9eeffd),
      onPrimaryFixed: Color(0xff001417),
      primaryFixedDim: Color(0xff82d3e1),
      onPrimaryFixedVariant: Color(0xff003c44),
      secondaryFixed: Color(0xffcde7ec),
      onSecondaryFixed: Color(0xff001417),
      secondaryFixedDim: Color(0xffb1cbd0),
      onSecondaryFixedVariant: Color(0xff223a3e),
      tertiaryFixed: Color(0xffdae2ff),
      onTertiaryFixed: Color(0xff04102c),
      tertiaryFixedDim: Color(0xffbac6ea),
      onTertiaryFixedVariant: Color(0xff2a3553),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff3f4647),
      surfaceContainerLowest: Color(0xff040809),
      surfaceContainerLow: Color(0xff191f20),
      surfaceContainer: Color(0xff23292a),
      surfaceContainerHigh: Color(0xff2d3435),
      surfaceContainerHighest: Color(0xff393f40),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcef7ff),
      surfaceTint: Color(0xff82d3e1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff7ecfdd),
      onPrimaryContainer: Color(0xff000e10),
      secondary: Color(0xffdaf5fa),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffadc7cc),
      onSecondaryContainer: Color(0xff000e10),
      tertiary: Color(0xffedefff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffb7c2e6),
      onTertiaryContainer: Color(0xff000926),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff0e1415),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffe8f2f4),
      outlineVariant: Color(0xffbbc4c6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffdee3e5),
      inversePrimary: Color(0xff005059),
      primaryFixed: Color(0xff9eeffd),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xff82d3e1),
      onPrimaryFixedVariant: Color(0xff001417),
      secondaryFixed: Color(0xffcde7ec),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb1cbd0),
      onSecondaryFixedVariant: Color(0xff001417),
      tertiaryFixed: Color(0xffdae2ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffbac6ea),
      onTertiaryFixedVariant: Color(0xff04102c),
      surfaceDim: Color(0xff0e1415),
      surfaceBright: Color(0xff4b5152),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1b2122),
      surfaceContainer: Color(0xff2b3133),
      surfaceContainerHigh: Color(0xff363c3e),
      surfaceContainerHighest: Color(0xff424849),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.background,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
