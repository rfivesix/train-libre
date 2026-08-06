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

  const SummaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignConstants.spacingM),
    this.margin = const EdgeInsets.symmetric(vertical: 6.0),
    this.onTap,
    this.disableShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
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

    final card = Padding(
      padding: margin,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
          boxShadow: (disableShadow || !isDark)
              ? null
              : [
                  BoxShadow(
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                    color: cs.shadow.withValues(alpha: 0.2),
                  ),
                ],
        ),
        child: ClipPath(
          clipper: clipper,
          child: Container(
            padding: padding,
            decoration: ShapeDecoration(
              color: isDark
                  ? DesignConstants.summaryCardDarkMode
                  : Colors.white,
              shape: squircle.copyWith(
                side: isDark
                    ? BorderSide(
                        color: cs.onSurface.withValues(alpha: 0.08),
                        width: 1,
                      )
                    : BorderSide.none,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
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
