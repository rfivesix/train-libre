import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../util/design_constants.dart';

class CardEmptyStateOverlay extends StatelessWidget {
  final Widget child;
  final String message;
  final bool isEmpty;

  const CardEmptyStateOverlay({
    super.key,
    required this.child,
    required this.message,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEmpty) return child;

    return Stack(
      children: [
        Skeletonizer(
          enabled: true,
          child: IgnorePointer(
            child: child,
          ),
        ),
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignConstants.borderRadiusL),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.35),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingL,
                      vertical: DesignConstants.spacingM,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.spacingM,
                        vertical: DesignConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
