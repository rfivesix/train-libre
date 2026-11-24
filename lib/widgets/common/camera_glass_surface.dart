import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';

import '../../util/glass_preferences.dart';

/// Round camera control material, sized independently of its icon or shutter.
class CameraGlassSurface extends StatelessWidget {
  const CameraGlassSurface({
    super.key,
    required this.dimension,
    required this.isDarkSurface,
    this.overPlatformView = false,
    this.tint,
    required this.child,
  });

  static const _nativeViewType = 'com.trainlibre.app/camera_glass';

  final double dimension;
  final bool isDarkSurface;
  final bool overPlatformView;
  final Color? tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = tint == null
        ? child
        : DecoratedBox(
            decoration: BoxDecoration(
              color: tint!.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: child,
          );

    // The iOS camera preview is composed by UIKit outside the Flutter scene.
    // Keep its glass backdrop in the same compositor as the live preview.
    if (overPlatformView && Platform.isIOS) {
      return SizedBox.square(
        dimension: dimension,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: UiKitView(
                viewType: _nativeViewType,
                hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              ),
            ),
            content,
          ],
        ),
      );
    }

    final preferences = GlassPreferences.of(context);
    final blur = 3.5 + 2 * preferences.blur;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final fill = preferences.tint(
        isDarkSurface
            ? (overPlatformView ? const Color(0x62000000) : Colors.white24)
            : Colors.black12,
      );
      // Clip the live blur once and shade the body without a perimeter stroke.
      // The standard glass shader draws a rim even without a widget border.
      return SizedBox.square(
        dimension: dimension,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dimension / 2),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(const Color(0x24FFFFFF), fill),
                    fill,
                    Color.alphaBlend(const Color(0x1A000000), fill),
                  ],
                ),
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    final settings = LiquidGlassSettings(
      glassColor: preferences.tint(
        isDarkSurface ? const Color(0x33FFFFFF) : const Color(0x18000000),
      ),
      backerColor: isDarkSurface ? const Color(0x40000000) : null,
      bodyMode: GlassBodyMode.clear,
      blur: blur,
      thickness: 8,
      saturation: 1.25,
      lightIntensity: 0.16,
      fresnelStrength: 0.26,
      chromaticAberration: 0,
      rimLight: 0.45,
      shadowElevation: 0,
    );
    return SizedBox.square(
      dimension: dimension,
      child: AdaptiveGlass(
        shape: LiquidRoundedRectangle(borderRadius: dimension / 2),
        settings: settings,
        quality: GlassQuality.standard,
        useOwnLayer: true,
        allowElevation: false,
        child: content,
      ),
    );
  }
}
