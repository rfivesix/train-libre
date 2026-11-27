import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

/// Applies the user's global glass preferences to a surface's own baseline.
/// A missing provider uses the defaults, allowing isolated widget previews.
class GlassPreferences {
  const GlassPreferences({
    this.blur = ThemeService.defaultGlassBlur,
    this.opacity = ThemeService.defaultGlassOpacity,
    this.supportsFrost = true,
  });

  final double blur;
  final double opacity;

  /// The full frost effect needs the premium Impeller renderer.
  final bool supportsFrost;

  static GlassPreferences of(BuildContext context) {
    final service = context.watch<ThemeService?>();
    return GlassPreferences(
      blur: service?.glassBlur ?? ThemeService.defaultGlassBlur,
      opacity: service?.glassOpacity ?? ThemeService.defaultGlassOpacity,
      supportsFrost:
          defaultTargetPlatform != TargetPlatform.android &&
          ui.ImageFilter.isShaderFilterSupported,
    );
  }

  Color tint(Color color) =>
      color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));

  // Opacity corresponding to the 50% slider midpoint where the iOS 27 preset
  // is calibrated unmodified.
  static const double _calibratedPresetOpacity = 0.9;

  LiquidGlassSettings apply(LiquidGlassSettings base, {bool premium = false}) {
    final color = base.glassColor;
    // Keep the library's calibrated material intact at the 50% midpoint.
    // Its demo does not define presets for the intermediate levels:
    // interpolate frost opacity around the supplied native-comparison value.
    if (base.lensModel == GlassLensModel.paraxial && base.frost == 14) {
      final level = ((opacity - 0.3) / 1.2).clamp(0.0, 1.0);
      if ((level - 0.5).abs() < 0.000001) return base;
      if (premium && supportsFrost) {
        final frostOpacity = level < 0.5
            ? base.frostOpacity * (0.25 + 1.5 * level)
            : base.frostOpacity +
                  (0.98 - base.frostOpacity) * (level - 0.5) * 2;
        return base.copyWith(
          frostOpacity: frostOpacity,
          blur:
              base.blur +
              (blur - ThemeService.defaultGlassBlur).clamp(0.0, 2.0),
        );
      }
      return base.copyWith(
        blur:
            base.blur + (blur - ThemeService.defaultGlassBlur).clamp(0.0, 2.0),
        glassColor: color.withValues(
          alpha: (color.a * (opacity / _calibratedPresetOpacity)).clamp(
            0.0,
            1.0,
          ),
        ),
      );
    }
    // A compact frost cloud softens fine detail without letting strong colours
    // spread too far into neighbouring parts of the backdrop.
    // Don't add a cloud to an indicator lens, whose base blur is deliberately 0.
    final hasSurface = premium && base.blur > 0 && color.a > 0;
    final level = ((opacity - 0.3) / 1.2).clamp(0.0, 1.0);
    final tint = hasSurface && supportsFrost
        ? color
        : color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
    return base.copyWith(
      blur: base.blur * blur,
      glassColor: tint,
      frost: hasSurface ? (base.frost > 0 ? base.frost : 6) : base.frost,
      frostOpacity: hasSurface ? 0.2 + 0.76 * level : base.frostOpacity,
      frostWeight: hasSurface ? 1 : base.frostWeight,
    );
  }
}
