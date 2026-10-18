import 'package:flutter/material.dart';
import '../../util/design_constants.dart';
import 'summary_card.dart';

class ValueSummaryCard extends StatelessWidget {
  final String label;
  final String value;

  /// Optional colour override for the value text.
  final Color? valueColor;

  /// Optional colour override for the label text.
  final Color? labelColor;

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

  /// Optional outline color for emphasizing a value.
  final Color? borderColor;

  /// Optional overlay used to add the same subtle shading as filled diary bars.
  final Gradient? backgroundOverlayGradient;

  /// Optional shadow applied to the value and label text.
  final List<Shadow>? textShadows;

  /// Vertical alignment of the card content. Defaults to center; use
  /// [MainAxisAlignment.start] to top-align the value/label/subtitle when the
  /// card is stretched to match a taller sibling in the same row.
  final MainAxisAlignment mainAxisAlignment;

  const ValueSummaryCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
    this.subtitle,
    this.onTap,
    this.disableShadow = false,
    this.useSecondarySurface = false,
    this.backgroundColor,
    this.borderColor,
    this.backgroundOverlayGradient,
    this.textShadows,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: SummaryCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        disableShadow: disableShadow,
        useSecondarySurface: useSecondarySurface,
        backgroundColor: backgroundColor,
        backgroundGradient: backgroundOverlayGradient,
        borderColor: borderColor,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignConstants.spacingM,
          vertical: DesignConstants.spacingS,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: mainAxisAlignment,
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
                    shadows: textShadows,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: labelColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  shadows: textShadows,
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
                    shadows: textShadows,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
