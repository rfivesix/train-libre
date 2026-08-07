import 'package:flutter/material.dart';
import '../../util/design_constants.dart';
import 'summary_card.dart';

class ValueSummaryCard extends StatelessWidget {
  final String label;
  final String value;

  /// Optional colour override for the value text.
  final Color? valueColor;

  /// Optional third line rendered below the label in a smaller style.
  final String? subtitle;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to disable the drop shadow.
  final bool disableShadow;

  /// Whether to use the secondary surface color (tertiarySystemGroupedBackground) for contrast inside parent cards.
  final bool useSecondarySurface;

  /// Optional custom background color override.
  final Color? backgroundColor;

  const ValueSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.onTap,
    this.disableShadow = false,
    this.useSecondarySurface = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SummaryCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      disableShadow: disableShadow,
      useSecondarySurface: useSecondarySurface,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignConstants.spacingM,
        vertical: DesignConstants.spacingS,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
