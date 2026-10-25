import 'package:flutter/material.dart';

import '../util/design_constants.dart';

/// Available app accent color modes.
enum AppColorChoice {
  trainLibre,
  monochrome,
  blue,
  teal,
  purple,
  orange,
  rose,
  custom,
  system,
}

/// Resolves an app color choice to colors for the light and dark themes.
extension AppColorChoiceColors on AppColorChoice {
  Color primary({
    required Brightness brightness,
    required Color customColor,
    Color? systemColor,
  }) {
    switch (this) {
      case AppColorChoice.trainLibre:
        return brightness == Brightness.light
            ? DesignConstants.brandAccentColorLightMode
            : DesignConstants.brandAccentColor;
      case AppColorChoice.monochrome:
        return brightness == Brightness.light ? Colors.black : Colors.white;
      case AppColorChoice.blue:
        return _seededPrimary(const Color(0xFF2563EB), brightness);
      case AppColorChoice.teal:
        return _seededPrimary(const Color(0xFF00897B), brightness);
      case AppColorChoice.purple:
        return _seededPrimary(const Color(0xFF7E57C2), brightness);
      case AppColorChoice.orange:
        return _seededPrimary(const Color(0xFFEF6C00), brightness);
      case AppColorChoice.rose:
        return _seededPrimary(const Color(0xFFE11D48), brightness);
      case AppColorChoice.custom:
        // A manually selected color is already the user's final choice. Keep
        // it byte-for-byte so the app accent matches the picker and hex value.
        return customColor;
      case AppColorChoice.system:
        return systemColor ??
            (brightness == Brightness.light
                ? DesignConstants.brandAccentColorLightMode
                : DesignConstants.brandAccentColor);
    }
  }

  Color onPrimary({required Brightness brightness, required Color primary}) {
    if (this == AppColorChoice.trainLibre) return Colors.black;
    if (this == AppColorChoice.monochrome) {
      return brightness == Brightness.light ? Colors.white : Colors.black;
    }
    return ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  static Color _seededPrimary(Color seed, Brightness brightness) {
    return ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
        .primary;
  }
}
