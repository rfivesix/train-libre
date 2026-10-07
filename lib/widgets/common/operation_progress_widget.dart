import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../util/design_constants.dart';
import 'summary_card.dart';

/// A reusable progress display widget featuring an icon badge, title, optional detail,
/// horizontal progress bar, and percentage indicator enclosed in a [SummaryCard].
///
/// Designed to provide a consistent visual presentation across operations such as
/// database downloads, backup imports/exports, and sync tasks.
class OperationProgressWidget extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final String title;
  final String? detail;
  final double? progress;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const OperationProgressWidget({
    super.key,
    required this.icon,
    this.iconColor,
    this.iconSize = 48,
    required this.title,
    this.detail,
    this.progress,
    this.action,
    this.padding = const EdgeInsets.all(DesignConstants.spacingXL),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDeterminate =
        progress != null && progress! >= 0.0 && progress! <= 1.0;
    final normalizedProgress = isDeterminate ? progress!.clamp(0.0, 1.0) : null;
    final percentageText =
        isDeterminate ? '${(normalizedProgress! * 100).round()}%' : null;
    final statusText =
        (detail != null && detail!.trim().isNotEmpty) ? detail! : null;
    final hasStatusRow = statusText != null || percentageText != null;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AdaptiveGlass(
              settings: LiquidGlassSettings(
                thickness: 0,
                blur: 8,
                glassColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.02),
                lightIntensity: isDark ? 0 : 0.4,
                saturation: 1.2,
              ),
              shape: const LiquidRoundedSuperellipse(borderRadius: 100),
              child: Container(
                padding: const EdgeInsets.all(DesignConstants.spacingXL),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor ?? theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          SummaryCard(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasStatusRow) ...[
                  const SizedBox(height: DesignConstants.spacingL),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (statusText != null)
                        Expanded(
                          child: Text(
                            statusText,
                            textAlign: TextAlign.left,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      if (percentageText != null) ...[
                        const SizedBox(width: DesignConstants.spacingS),
                        Text(
                          percentageText,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignConstants.spacingS),
                ] else ...[
                  const SizedBox(height: DesignConstants.spacingL),
                ],
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: normalizedProgress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: DesignConstants.spacingL),
                  Center(child: action!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
