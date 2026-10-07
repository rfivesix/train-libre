import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import '../../util/design_constants.dart';

/// A standardized card for displaying summary information with a glass aesthetic.
///
/// Automatically adapts its background color and transparency to the current theme.
class SummaryCard extends StatelessWidget {
  /// The main content to display inside the card.
  final Widget child;

  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// Optional margin for the card container.
  final EdgeInsetsGeometry margin;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  /// Whether to disable the drop shadow.
  final bool disableShadow;

  /// Optional background color override.
  final Color? backgroundColor;

  /// Whether to use the secondary surface color (tertiarySystemGroupedBackground in iOS).
  final bool useSecondarySurface;

  /// Optional outline for emphasizing a summary card.
  final Color? borderColor;

  /// Outline width when [borderColor] is provided.
  final double borderWidth;

  const SummaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignConstants.spacingM),
    this.margin = const EdgeInsets.symmetric(vertical: 6.0),
    this.onTap,
    this.disableShadow = false,
    this.backgroundColor,
    this.useSecondarySurface = false,
    this.borderColor,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBg = isDark
        ? (useSecondarySurface
            ? DesignConstants.summaryCardSecondaryDarkMode
            : DesignConstants.summaryCardDarkMode)
        : (useSecondarySurface
            ? DesignConstants.summaryCardSecondaryLightMode
            : Colors.white);
    final cardBg = backgroundColor ?? defaultBg;

    // True Apple-style squircle using the figma_squircle package.
    // smoothness: 0.6 matches iOS system cards exactly.
    // Unlike Flutter's ContinuousRectangleBorder, this superellipse
    // stays tight to the corner instead of creeping along the edge.
    final squircleRadius = SmoothBorderRadius(
      cornerRadius: DesignConstants.borderRadiusL,
      cornerSmoothing: 0.6,
    );
    final squircle = SmoothRectangleBorder(borderRadius: squircleRadius);
    final clipper = ShapeBorderClipper(shape: squircle);

    final Color inputFill;
    if (isDark) {
      inputFill =
          theme.inputDecorationTheme.fillColor ?? const Color(0xFF2C2C2E);
    } else {
      // In light mode:
      // If the card background is white (the default for summary cards),
      // nested form inputs and dropdowns must take the contrasting secondary
      // surface color (#F2F2F7) to prevent white-on-white blending.
      // If the card already uses the secondary surface (#F2F2F7), nested inputs
      // take white.
      final isWhiteCard = (cardBg == Colors.white ||
              cardBg.toARGB32() == 0xFFFFFFFF ||
              cardBg.computeLuminance() > 0.95) &&
          cardBg != DesignConstants.summaryCardSecondaryLightMode;
      inputFill = isWhiteCard
          ? DesignConstants.summaryCardSecondaryLightMode
          : Colors.white;
    }

    final cardTheme = theme.copyWith(
      cardColor: cardBg,
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        fillColor: inputFill,
      ),
    );

    final card = Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
          // Summary cards stay flat in both themes. The surface contrast and
          // grouped-page background provide their separation.
          boxShadow: null,
        ),
        child: ClipPath(
          clipper: clipper,
          child: Container(
            padding: padding,
            decoration: ShapeDecoration(
              color: cardBg,
              shape: squircle.copyWith(
                side: borderColor == null
                    ? BorderSide.none
                    : BorderSide(color: borderColor!, width: borderWidth),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Theme(
                data: cardTheme,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }
    return card;
  }
}
