import 'package:flutter/material.dart';

import '../../util/design_constants.dart';

/// A background widget used for [Dismissible] swipe actions.
///
/// Provides a consistent look with outer rounded clipped corners matching summary cards/tiles,
/// while keeping inner edges flat so the background sits seamlessly underneath swiping cards.
class SwipeActionBackground extends StatelessWidget {
  /// The background color (e.g., [Theme.of(context).colorScheme.error] for delete).
  final Color color;

  /// The icon representing the action.
  final IconData icon;

  /// Anchors the icon to a side (e.g., [Alignment.centerLeft]).
  final Alignment alignment;

  /// Optional custom corner radius. Defaults to [DesignConstants.borderRadiusL].
  final BorderRadius? borderRadius;

  /// Optional vertical/horizontal margin matching the target card/tile. Defaults to [EdgeInsets.zero].
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

    // Only round outer corners in the direction of the action alignment
    // so the inner edge sits flat and seamless underneath the swiping card.
    final BorderRadius clippedRadius;
    if (alignment == Alignment.centerRight || alignment.x > 0) {
      clippedRadius = BorderRadius.only(
        topRight: baseRadius.topRight,
        bottomRight: baseRadius.bottomRight,
      );
    } else if (alignment == Alignment.centerLeft || alignment.x < 0) {
      clippedRadius = BorderRadius.only(
        topLeft: baseRadius.topLeft,
        bottomLeft: baseRadius.bottomLeft,
      );
    } else {
      clippedRadius = baseRadius;
    }

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: clippedRadius,
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




