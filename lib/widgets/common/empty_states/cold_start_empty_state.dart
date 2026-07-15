import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../util/design_constants.dart';
import 'curved_arrow.dart';

class ColdStartEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String callToAction;

  const ColdStartEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.callToAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
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
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
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
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXXL),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingL),
            child: Text(
              callToAction,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: DesignConstants.spacingM),
          const Expanded(
            flex: 4,
            child: CurvedArrow(key: ValueKey('cold_start_curved_arrow')),
          ),
        ],
      ),
    );
  }
}
