import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../util/design_constants.dart';
import 'summary_card.dart';

/// A reusable progress display widget featuring an icon badge, title, optional detail,
/// horizontal progress bar, and percentage indicator enclosed in a [SummaryCard].
///
/// Designed to provide a consistent visual presentation across operations such as
/// database downloads, backup imports/exports, and sync tasks.
class OperationProgressWidget extends StatefulWidget {
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
  State<OperationProgressWidget> createState() =>
      _OperationProgressWidgetState();
}

class _OperationProgressWidgetState extends State<OperationProgressWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDeterminate = widget.progress != null &&
        widget.progress! >= 0.0 &&
        widget.progress! <= 1.0;
    final normalizedProgress =
        isDeterminate ? widget.progress!.clamp(0.0, 1.0) : null;
    final percentageText =
        isDeterminate ? '${(normalizedProgress! * 100).round()}%' : null;
    final statusText =
        (widget.detail != null && widget.detail!.trim().isNotEmpty)
            ? widget.detail!.trim().replaceFirst(RegExp(r'(\.{1,3}|…)\s*$'), '')
            : null;
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
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.iconColor ?? theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          SummaryCard(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
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
                          child: AnimatedBuilder(
                            animation: _dotsController,
                            builder: (context, _) => Text.rich(
                              TextSpan(
                                text: statusText,
                                children: [
                                  TextSpan(
                                    text: '.' *
                                        ((_dotsController.value * 4)
                                            .floor()
                                            .clamp(0, 3)),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                if (widget.action != null) ...[
                  const SizedBox(height: DesignConstants.spacingL),
                  Center(child: widget.action!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
