import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../util/design_constants.dart';

class CardEmptyStateOverlay extends StatelessWidget {
  final Widget child;
  final String message;
  final bool isEmpty;
  final BorderRadius? borderRadius;

  const CardEmptyStateOverlay({
    super.key,
    required this.child,
    required this.message,
    required this.isEmpty,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEmpty) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(DesignConstants.borderRadiusL);

    return Stack(
      alignment: Alignment.center,
      children: [
        Skeletonizer(enabled: true, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: effectiveRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingM,
            vertical: DesignConstants.spacingS,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingM,
              vertical: DesignConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(
                DesignConstants.borderRadiusM,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
