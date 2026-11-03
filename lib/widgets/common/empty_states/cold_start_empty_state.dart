import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../util/design_constants.dart';
import 'curved_arrow.dart';

class ColdStartEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? callToAction;
  final bool targetCenter;
  final double? customEndXOffset;
  final double? customTargetYOffset;
  final bool showArrow;

  const ColdStartEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.callToAction,
    this.targetCenter = false,
    this.customEndXOffset,
    this.customTargetYOffset,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScaler = MediaQuery.textScalerOf(context);
    final hasCta = callToAction != null && callToAction!.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;
        final textScale = textScaler.scale(1.0);
        final isTight = availableHeight < 560 || textScale > 1.15;
        final estimatedContentHeight =
            (isTight ? 190.0 : 240.0) +
            (hasCta ? (isTight ? 45.0 : 70.0) : 0.0);
        final totalNeededHeight = (estimatedContentHeight * textScale) + 120.0;
        final shouldShowArrow =
            showArrow && availableHeight >= totalNeededHeight;

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingL,
              ),
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
                  padding: EdgeInsets.all(
                    isTight
                        ? DesignConstants.spacingL
                        : DesignConstants.spacingXL,
                  ),
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
                    size: isTight ? 36 : 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: isTight
                  ? DesignConstants.spacingM
                  : DesignConstants.spacingL,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingL,
              ),
              child: Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: DesignConstants.spacingS),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingL,
              ),
              child: Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasCta) ...[
              SizedBox(
                height: isTight
                    ? DesignConstants.spacingL
                    : DesignConstants.spacingXXL,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingL,
                ),
                child: Text(
                  callToAction!.trim(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        );

        if (!constraints.hasBoundedHeight) {
          return Center(child: SingleChildScrollView(child: content));
        }

        if (shouldShowArrow) {
          return Column(
            children: [
              if (!isTight)
                const Spacer(flex: 1)
              else
                const SizedBox(height: DesignConstants.spacingS),
              content,
              if (hasCta) const SizedBox(height: DesignConstants.spacingS),
              Expanded(
                flex: isTight ? 2 : 4,
                child: CurvedArrow(
                  key: const ValueKey('cold_start_curved_arrow'),
                  targetCenter: targetCenter,
                  customEndXOffset: customEndXOffset,
                  customTargetYOffset: customTargetYOffset,
                ),
              ),
            ],
          );
        }

        return Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              vertical: DesignConstants.spacingM,
            ),
            child: content,
          ),
        );
      },
    );
  }
}
