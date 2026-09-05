// lib/widgets/workout_card.dart
import 'package:flutter/material.dart';

/// A transparent container for workout items with rounded corners.
///
/// Used to group workout elements while maintaining layout consistency.
class WorkoutCard extends StatelessWidget {
  /// Internal padding for the [child].
  final EdgeInsetsGeometry padding;

  /// External margin for the card.
  final EdgeInsetsGeometry margin;

  /// The content within the card.
  final Widget child;
  final Color? accentColor;

  /// Whether the superset group starts above this card, i.e. the accent
  /// bracket runs in from the previous card instead of opening here.
  final bool continuesSupersetAbove;

  /// Whether the superset group continues below this card.
  final bool continuesSupersetBelow;

  const WorkoutCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.accentColor,
    this.continuesSupersetAbove = false,
    this.continuesSupersetBelow = false,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = accentColor != null;
    // The bracket is drawn once around the whole group: only its outer ends
    // are rounded, the edges facing a sibling card stay square.
    final borderRadius = BorderRadius.vertical(
      top: Radius.circular(grouped && continuesSupersetAbove ? 0 : 20),
      bottom: Radius.circular(grouped && continuesSupersetBelow ? 0 : 20),
    );
    final card = Container(
      key: key, // Pass key to the container
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: accentColor?.withValues(alpha: 0.06) ?? Colors.transparent,
        border: accentColor == null
            ? null
            : Border(left: BorderSide(color: accentColor!, width: 3)),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        // Ensures child corners stay rounded.
        borderRadius: borderRadius,
        child: child,
      ),
    );
    if (!continuesSupersetBelow || accentColor == null) return card;

    // Keep the group's rail and tint continuous through the space between two
    // cards, so the bracket reads as one shape across all members.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: accentColor!.withValues(alpha: 0.06),
            border: Border(left: BorderSide(color: accentColor!, width: 3)),
          ),
        ),
      ],
    );
  }
}
