// lib/util/design_constants.dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Central source of truth for design tokens including spacing, radii, and padding.
///
/// Ensures visual consistency across the application by providing standardized constants.
class DesignConstants {
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
  static const double sectionHeaderLetterSpacing = 1.0;

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
    top: 4.0,
  );

  // === GLASSMORPHISM ===
  /// Unified shadow for glassmorphic elements.
  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          blurRadius: 12,
          offset: const Offset(0, 6),
          color: Colors.black.withValues(alpha: 0.30),
        ),
      ];

  /// Unified neutral background color tint for glassmorphic elements.
  static Color glassNeutralTint(bool isDark) =>
      (isDark ? Colors.white : Colors.white).withValues(alpha: 0.10);

  /// Unified base color tint for the glass shader.
  static Color glassColor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.12)
      : Colors.white.withValues(alpha: 0.15);

  /// Unified settings for liquid glassmorphic rendering.
  static LiquidGlassSettings liquidGlassSettings(bool isDark) =>
      LiquidGlassSettings(
        thickness: 30,
        blur: 2.0,
        glassColor: glassColor(isDark),
        lightIntensity: isDark ? 0.55 : 0.80,
        saturation: 1.20,
      );
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
