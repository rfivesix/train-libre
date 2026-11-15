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

  LiquidGlassSettings apply(LiquidGlassSettings base, {bool premium = false}) {
    final color = base.glassColor;
    // A frost mixes a broad, colour-preserving cloud with the lightly blurred
    // copy beneath it. Uniform colours stay vivid while small details fade.
    // Don't add a cloud to an indicator lens, whose base blur is deliberately 0.
    final hasSurface = premium && base.blur > 0 && color.a > 0;
    final level = ((opacity - 0.3) / 1.2).clamp(0.0, 1.0);
    final tint = hasSurface && supportsFrost
        ? color
        : color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
    return base.copyWith(
      blur: base.blur * blur,
      glassColor: tint,
      frost: hasSurface ? (base.frost > 0 ? base.frost : 14) : base.frost,
      frostOpacity: hasSurface ? 0.2 + 0.76 * level : base.frostOpacity,
      frostWeight: hasSurface ? 1 : base.frostWeight,
    );
  }
}
