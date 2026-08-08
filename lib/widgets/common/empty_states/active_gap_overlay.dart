import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../util/design_constants.dart';

class ActiveGapOverlay extends StatelessWidget {
  final Widget background;
  final String message;

  const ActiveGapOverlay({
    super.key,
    required this.background,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        background,
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignConstants.spacingL,
                      vertical: DesignConstants.spacingM,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
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
