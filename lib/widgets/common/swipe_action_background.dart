import 'package:flutter/material.dart';

import '../../util/design_constants.dart';

/// A background widget used for [Dismissible] swipe actions.
///
/// Clips only the *outer* corners (the far edge away from the sliding card)
/// so the colour sits flush behind the card at its inner edge.
/// Shadow bleed from the sliding card is prevented separately by [ClipRect]
/// in [GlassActionableCard].
class SwipeActionBackground extends StatelessWidget {
  /// The background color (e.g., [DesignConstants.brandRedColor] for delete).
  final Color color;

  /// The icon representing the action.
  final IconData icon;

  /// Anchors the icon to a side (e.g., [Alignment.centerLeft]).
  final Alignment alignment;

  /// Optional custom corner radius. Defaults to [DesignConstants.borderRadiusL].
  final BorderRadius? borderRadius;

  /// Optional vertical/horizontal margin matching the target card/tile.
  final EdgeInsetsGeometry margin;

  const SwipeActionBackground({
    super.key,
    required this.color,
    required this.icon,
    required this.alignment,
    this.borderRadius,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final baseRadius =
        borderRadius ?? BorderRadius.circular(DesignConstants.borderRadiusL);

    // Only round the OUTER corners – the visible far edge.
    // The inner edge stays flat so the colour fills all the way to where the
    // sliding card's rounded corner is (preventing a dark gap).
    final BorderRadius outerRadius;
    if (alignment.x > 0) {
      // Right-aligned (delete / red): outer corners are on the right.
      outerRadius = BorderRadius.only(
        topRight: baseRadius.topRight,
        bottomRight: baseRadius.bottomRight,
      );
    } else if (alignment.x < 0) {
      // Left-aligned (edit / blue): outer corners are on the left.
      outerRadius = BorderRadius.only(
        topLeft: baseRadius.topLeft,
        bottomLeft: baseRadius.bottomLeft,
      );
    } else {
      outerRadius = baseRadius;
    }

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: outerRadius,
        child: Container(
          color: color,
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
