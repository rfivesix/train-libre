import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

/// Applies the user's global glass preferences to a surface's own baseline.
/// A missing provider uses the defaults, allowing isolated widget previews.
class GlassPreferences {
  const GlassPreferences({
    this.blur = 1,
    this.opacity = 1,
    this.liquidEnabled = true,
    this.borderRemoved = false,
  });

  final double blur;
  final double opacity;
  final bool liquidEnabled;
  final bool borderRemoved;

  static GlassPreferences of(BuildContext context) {
    final service = context.watch<ThemeService?>();
    return GlassPreferences(
      blur: service?.glassBlur ?? 1,
      opacity: service?.glassOpacity ?? 1,
      liquidEnabled: service?.liquidGlassEnabled ?? true,
      borderRemoved: service?.glassBorderRemoved ?? false,
    );
  }

  Color tint(Color color) =>
      color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));

  LiquidGlassSettings apply(LiquidGlassSettings base) {
    final color = base.glassColor;
    return base.copyWith(
      blur: base.blur * blur,
      glassColor: color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0)),
      thickness: liquidEnabled ? base.thickness : 0,
      refractiveIndex: liquidEnabled ? base.refractiveIndex : 1,
      chromaticAberration: liquidEnabled ? base.chromaticAberration : 0,
      fresnelStrength: liquidEnabled && !borderRemoved
          ? base.fresnelStrength
          : 0,
      ambientRim: liquidEnabled && !borderRemoved ? base.ambientRim : 0,
      rimLight: liquidEnabled && !borderRemoved ? base.rimLight : 0,
      rimShade: liquidEnabled && !borderRemoved ? base.rimShade : 0,
      edgeAbsorption: liquidEnabled && !borderRemoved ? base.edgeAbsorption : 0,
      lightIntensity: liquidEnabled && !borderRemoved ? base.lightIntensity : 0,
    );
  }
}
