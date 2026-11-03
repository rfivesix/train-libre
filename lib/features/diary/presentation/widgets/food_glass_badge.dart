import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Dietary Badge — Liquid Glass Aesthetic
// ═══════════════════════════════════════════════════════════════════════════
class FoodGlassBadge extends StatelessWidget {
  final String label;
  final bool isVegan; // Or status enum

  const FoodGlassBadge({super.key, required this.label}) : isVegan = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Uses defined app colors for badge tinting
    final primaryBadgeColor = Colors.green;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingS,
        vertical: DesignConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        // Light glass tint depending on dark/light mode
        color: isDarkMode
            ? primaryBadgeColor.withValues(alpha: 0.15)
            : primaryBadgeColor.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusS),
        border: Border.all(
          // Border uses badge color with higher opacity
          color: primaryBadgeColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        //.toUpperCase(), // Optional: Often looks cleaner on badges
        style: theme.textTheme.labelSmall?.copyWith(
          color: isDarkMode ? primaryBadgeColor : primaryBadgeColor.shade800,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
