import 'package:flutter/material.dart';

import '../util/design_constants.dart';

/// Keeps custom accents away from near-black and near-white extremes so the
/// same selected color remains useful in both light and dark themes.
const double customAppColorMinBrightness = 0.40;
const double customAppColorMaxBrightness = 0.82;

bool isCustomAppColorBrightnessAllowed(Color color) {
  final brightness = HSVColor.fromColor(color).value;
  return brightness >= customAppColorMinBrightness &&
      brightness <= customAppColorMaxBrightness;
}

Color constrainCustomAppColor(Color color) {
  final hsv = HSVColor.fromColor(color);
  return hsv
      .withValue(
        hsv.value
            .clamp(
              customAppColorMinBrightness,
              customAppColorMaxBrightness,
            )
            .toDouble(),
      )
      .toColor();
}

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
        return brightness == Brightness.light
            ? const Color(0xFFE65100)
            : const Color(0xFFFFA726);
      case AppColorChoice.rose:
        return _seededPrimary(const Color(0xFFE11D48), brightness);
      case AppColorChoice.custom:
        // Treat the chosen color as a seed to create distinct, legible accents
        // for light and dark themes. The settings cards preview these values.
        return _seededPrimary(customColor, brightness);
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
