import '../../../../../util/glass_preferences.dart';

import 'package:material_ui/material_ui.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../../util/design_constants.dart';
import '../../../../../widgets/common/camera_glass_surface.dart';

/// Circular liquid glass icon button used in overlay headers, chat turns, and composer.
class HeaderGlassButton extends StatelessWidget {
  const HeaderGlassButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isDarkSurface,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.showBorder = true,
    this.useStaticGlass = false,
    this.platformViewBackdrop = false,
    this.useCameraGlass = false,
    this.dimension = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final String tooltip;
  final bool isDarkSurface;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showBorder;
  final bool useStaticGlass;
  final bool platformViewBackdrop;

  final bool useCameraGlass;

  final double dimension;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final foreground =
        foregroundColor ?? (isDarkSurface ? Colors.white : Colors.black);
    final iconContent = Center(
      child: Icon(icon, size: iconSize, color: foreground),
    );
    Widget glassContent = iconContent;
    if (showBorder && useCameraGlass) {
      glassContent = CameraGlassSurface(
        dimension: dimension,
        isDarkSurface: isDarkSurface,
        overPlatformView: platformViewBackdrop,
        tint: backgroundColor,
        child: iconContent,
      );
    } else if (showBorder) {
      final glassPreferences = GlassPreferences.of(context);
      final buttonSurface = DecoratedBox(
        decoration: BoxDecoration(
          color: glassPreferences.tint(
            backgroundColor ??
                (isDarkSurface
                    ? DesignConstants.glassNeutralTint(true)
                    : Colors.black.withValues(alpha: 0.04)),
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: foreground.withValues(alpha: 0.14),
            width: 0.5,
          ),
        ),
        child: iconContent,
      );
      // The cloud can have the opposite appearance from the app while it opens
      // or closes. Let the glass renderer use the cloud's current surface too.
      final glassTheme = Theme.of(context).copyWith(
        brightness: isDarkSurface ? Brightness.dark : Brightness.light,
      );
      final settings = glassPreferences.apply(
        DesignConstants.liquidGlassSettings(isDarkSurface),
        premium: !platformViewBackdrop,
      );
      glassContent = Theme(
        data: glassTheme,
        child: GlassAdaptiveScope(
          maxQuality: DesignConstants.defaultGlassQuality,
          minQuality: DesignConstants.minGlassQuality,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: useStaticGlass ? 0 : 1,
              end: useStaticGlass ? 0 : 1,
            ),
            duration: useStaticGlass
                ? Duration.zero
                : const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder: (context, visibility, _) {
              final visibleSettings = settings.copyWith(visibility: visibility);
              final glass = AdaptiveGlass(
                settings: visibleSettings,
                quality: DesignConstants.defaultGlassQuality,
                useOwnLayer: true,
                allowElevation: false,
                shape: LiquidRoundedSuperellipse(borderRadius: dimension / 2),
                platformViewBackdrop: platformViewBackdrop,
                child: GlassGlow(
                  glowColor: Colors.white.withValues(
                    alpha: (isDarkSurface ? 0.24 : 0.18) * visibility,
                  ),
                  glowRadius: visibility,
                  child: buttonSurface,
                ),
              );
              return glass;
            },
          ),
        ),
      );
    }
    final button = SizedBox.square(
      dimension: dimension,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: showBorder && !useCameraGlass
              ? DesignConstants.glassShadow(isDarkSurface)
              : null,
        ),
        child: glassContent,
      ),
    );
    // This widget is also mounted through a root OverlayEntry, whose subtree
    // does not consistently expose an Overlay ancestor on every platform.
    // Tooltip tries to insert a RawTooltip entry and throws in that case.
    return Semantics(
      button: onPressed != null,
      label: tooltip,
      child: onPressed == null
          ? button
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: button,
            ),
    );
  }
}
