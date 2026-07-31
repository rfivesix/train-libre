import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Central source of truth for design tokens including spacing, radii, and padding.
///
/// Ensures visual consistency across the application by providing standardized constants.
class DesignConstants {
  // === ADAPTIVE ICONS ===
  /// Returns the platform-appropriate share icon (share for iOS/macOS, share_2 for Android/others)
  static IconData get adaptiveShareIcon => Platform.isIOS || Platform.isMacOS
      ? LucideIcons.share
      : LucideIcons.share_2;
  // === SPACING ===
  // Card Padding
  static const double cardPaddingInternal = 16.0; // Innenabstand von Cards
  static const double cardPaddingExternal =
      8.0; // External spacing between cards

  // General Spacing
  static const double spacingXS = 4.0; // Extra-small spacing
  static const double spacingS = 8.0; // Small spacing
  static const double spacingM = 12.0; // Medium spacing
  static const double spacingL = 16.0; // Standard spacing
  static const double spacingXL = 24.0; // Large spacing
  static const double spacingXXL = 32.0; // Extra-large spacing
  static const double bottomContentSpacer = 80.0; // Space for FAB, etc.

  // === TYPOGRAPHY ===
  /// Letter spacing used for uppercase section headers throughout the app.
  static const double sectionHeaderLetterSpacing = 0.7;

  /// Standard font weight for section headers.
  static const FontWeight sectionHeaderFontWeight = FontWeight.bold;

  // === METADATA ===
  /// Bullet separator used in metadata rows (e.g. "120 kcal • 30g P • 20g C").
  static const String metadataSeparator = ' \u2022 ';

  // === ANIMATION ===
  /// Duration for expand/collapse animations in card sections.
  static const Duration expandCollapseDuration = Duration(milliseconds: 180);

  // Screen Padding
  static const double screenPaddingHorizontal = 16.0;
  static const double screenPaddingVertical = 8.0;

  // === BORDER RADIUS ===
  static const double borderRadiusS = 8.0; // Kleine Rundung
  static const double borderRadiusM = 12.0; // Standard corner radius
  static const double borderRadiusL = 19.0; // Large corner radius

  // === LIST SPACING ===
  static const double listItemSpacing = 8.0;
  static const double listSectionSpacing = 24.0;

  // === BUTTON SPACING ===
  static const double buttonPadding = 16.0;
  static const double buttonSpacing = 12.0;

  // === ICON SIZES ===
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;

  // === EDGE INSETS SHORTCUTS ===
  static const EdgeInsets cardPadding = EdgeInsets.all(cardPaddingInternal);
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    vertical: cardPaddingExternal,
  );
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
    vertical: screenPaddingVertical,
  );
  static const EdgeInsets listPadding = EdgeInsets.all(spacingL);
  static const EdgeInsets buttonContentPadding = EdgeInsets.symmetric(
    horizontal: buttonPadding,
    vertical: spacingM,
  );

  /// Compact card content padding used in expandable meal/fluid cards.
  static const EdgeInsets cardContentPadding = EdgeInsets.all(12.0);

  /// Standard padding for section headers (bottom + left inset).
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.only(
    bottom: 8.0,
    left: 4.0,
    top: 4.0, // Increased top padding for better visual separation
  );

  // === COLORS ===
  static const Color summaryCardDarkMode = Color(0xFF2A2A2A);

  // === GLASSMORPHISM ===
  // Glassmorphic Component Sizes (Apple HIG Aligned)
  /// Standard height for the premium floating bottom navigation bar.
  static const double bottomNavigationBarHeight = 64.0;

  /// Standard size (width & height) for the main Glass FAB.
  static const double fabSize = 64.0;

  /// Standard height for floating overlays such as the Running Workout Overlay and the Live Rest Timer bar.
  static const double workoutOverlayHeight = 64.0;

  /// Standard size for the action item buttons inside the Speed Dial (Plus) Menu.
  static const double speedDialActionSize = 56.0;

  /// Standard height for custom list tiles/interactive items inside glass menus.
  static const double glassTileHeight = 52.0;

  /// Unified shadow for glassmorphic elements (disabled in favor of soft background vignettes).
  static List<BoxShadow> get glassShadow => const [];

  /// Global bottom vignette gradient that ramps up towards the bottom edge,
  /// reaching 100% opacity right at the very bottom screen boundary.
  static LinearGradient bottomVignetteGradient(bool isDark) {
    final baseColor =
        isDark ? Colors.black : const Color.fromARGB(255, 194, 194, 194);
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        baseColor.withValues(
            alpha: 1.00), // Solid opacity ONLY at the absolute bottom edge
        baseColor.withValues(
            alpha: 0.70), // Translucent behind the bottom navigation bar
        baseColor.withValues(alpha: 0.35), // Subtle fade above the bar
        baseColor.withValues(alpha: 0.08), // Soft entry
        Colors.transparent, // Fully transparent upper area
      ],
      stops: const [0.0, 0.12, 0.30, 0.55, 1.0],
    );
  }

  /// Unified neutral background color tint for glassmorphic elements.
  static Color glassNeutralTint(bool isDark) =>
      (isDark ? Colors.white : Colors.white).withValues(alpha: 0.10);

  /// Unified base color tint for the glass shader.
  /// Combines a white base layer so glass elements remain clearly distinct
  /// over solid backgrounds while maintaining desaturated iOS optics.
  static Color glassColor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.45);

  /// Default platform-adaptive glass quality.
  /// Uses [GlassQuality.standard] on Android for optimal GPU subpass performance,
  /// and [GlassQuality.premium] on iOS/macOS.
  static GlassQuality get defaultGlassQuality {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return GlassQuality.standard;
    }
    return GlassQuality.premium;
  }

  /// Unified settings for liquid glassmorphic rendering.
  static LiquidGlassSettings liquidGlassSettings(bool isDark) =>
      LiquidGlassSettings(
        thickness: 30,
        blur: 2.0,
        glassColor: glassColor(isDark),
        lightIntensity: isDark ? 0.55 : 0.80,
        saturation: 0.70,
        ambientRim: 0.2,
      );

  /// The primary brand color for Train Libre, sourced from the app icon.
  static const Color brandAccentColor = Color(0xFFDDFF00);

  /// A darkened version of the brand color for better contrast in Light Mode.
  static const Color brandAccentColorLightMode = Color(0xFF8B9E00);

  /// A rich, saturated red used for destructive actions and errors.
  /// Chosen for maximum visual impact: vivid, warm, and unmistakably urgent.
  static const Color brandRedColor = Color(0xFFE5253A);

  /// The standard colors used for AI-related gradients and accents.
  static const List<Color> aiGradientColors = [
    Color(0xFFE88DCC),
    Color(0xFFF4A77A),
    Color(0xFFF7D06B),
    Color(0xFF7DDEAE),
    Color(0xFF6DC8D9),
  ];

  /// Creates a linear gradient shader for AI-themed icons and elements.
  static Shader createAiGradientShader(Rect bounds) {
    return const LinearGradient(
      colors: aiGradientColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bounds);
  }

  static const Color summaryCardWhiteMode = Color.fromARGB(255, 235, 235, 235);
}

/// A custom clipper that clips out the inner area of a shape, leaving only
/// the outer boundary visible. Used to draw drop shadows around transparent
/// widgets without darkening the widgets themselves.
class ShadowOuterClipper extends CustomClipper<Path> {
  final double borderRadius;
  final bool isOval;

  ShadowOuterClipper({required this.borderRadius, this.isOval = false});

  @override
  Path getClip(Size size) {
    final Path outer = Path()
      ..addRect(Rect.fromLTWH(-100, -100, size.width + 200, size.height + 200));
    final Path inner = Path();
    if (isOval) {
      inner.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      inner.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));
    }
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(covariant ShadowOuterClipper oldClipper) {
    return oldClipper.borderRadius != borderRadius ||
        oldClipper.isOval != isOval;
  }
}
