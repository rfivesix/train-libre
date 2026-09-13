// lib/widgets/glass_progress_bar.dart
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

import '../../util/design_constants.dart';

/// A progress bar widget with a glass background and a solid fill color.
///
/// Displays a [label], [unit], current [value], and optional [target].
///
/// When [value] or [target] change, the fill bar and the displayed numeric
/// value animate smoothly to the new position instead of jumping instantly.
class GlassProgressBar extends StatefulWidget {
  /// The descriptive label for the progress (e.g., 'Calories').
  final String label;

  /// The unit of measurement (e.g., 'kcal').
  final String unit;

  /// The current value to display.
  final double value;

  /// The goal or target value; used to calculate progress percentage.
  final double target;

  /// The color of the progress fill.
  final Color color;

  /// The fixed height of the progress bar.
  final double height;

  /// The corner radius for the bar.
  final double borderRadius;

  /// Whether to disable the drop shadow.
  final bool disableShadow;

  /// Optional custom subtitle to display instead of the default "value / target unit".
  final String? customSubtitle;

  const GlassProgressBar({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    this.height = 54.0,
    this.borderRadius = DesignConstants.borderRadiusL,
    this.disableShadow = false,
    this.customSubtitle,
  });

  @override
  State<GlassProgressBar> createState() => _GlassProgressBarState();
}

class _GlassProgressBarState extends State<GlassProgressBar> {
  // Track the value we are tweening FROM so we can hand it to
  // TweenAnimationBuilder as the starting point on every change.
  late double _previousValue;
  late double _previousTarget;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _previousTarget = widget.target;
  }

  @override
  void didUpdateWidget(GlassProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Store the old rendered values so the tween starts from where the bar
    // visually was, not from 0.
    if (oldWidget.value != widget.value || oldWidget.target != widget.target) {
      _previousValue = oldWidget.value;
      _previousTarget = oldWidget.target;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // Tween the raw value (not the clamped progress ratio) so the
      // displayed text number also animates smoothly.
      tween: Tween<double>(begin: _previousValue, end: widget.value),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: _previousTarget, end: widget.target),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animatedTarget, _) {
            return _GlassProgressBarPainter(
              label: widget.label,
              unit: widget.unit,
              value: animatedValue,
              target: animatedTarget,
              color: widget.color,
              height: widget.height,
              borderRadius: widget.borderRadius,
              disableShadow: widget.disableShadow,
              customSubtitle: widget.customSubtitle,
            );
          },
        );
      },
    );
  }
}

/// Pure-display layer — receives already-tweened values and just renders.
class _GlassProgressBarPainter extends StatelessWidget {
  final String label;
  final String unit;
  final double value;
  final double target;
  final Color color;
  final double height;
  final double borderRadius;
  final bool disableShadow;
  final String? customSubtitle;

  const _GlassProgressBarPainter({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    required this.height,
    required this.borderRadius,
    required this.disableShadow,
    this.customSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (value / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);


    // Text color follows theme brightness: black in light mode, white in dark mode.
    final Color textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    // Identical to SummaryCard: same cornerRadius, same cornerSmoothing.
    // NOTE: do not wrap this widget in a LayoutBuilder to derive the radius from
    // the laid-out height — LayoutBuilder reports 0 for intrinsic dimensions, and
    // NutritionSummaryWidget puts these bars inside an IntrinsicHeight, which
    // then collapses the whole grid to zero height.
    final squircleRadius = SmoothBorderRadius(
      cornerRadius: borderRadius,
      cornerSmoothing: 0.6,
    );
    final squircle = SmoothRectangleBorder(borderRadius: squircleRadius);
    final clipper = ShapeBorderClipper(shape: squircle);

    return Container(
      decoration: ShapeDecoration(
        shape: squircle,
        // This is the compact progress-card variant used beside summary
        // cards, so it follows the same flat surface treatment.
        shadows: null,
      ),
      child: ClipPath(
        clipper: clipper,
        child: Container(
          height: height,
          decoration: ShapeDecoration(
            color: isDark ? DesignConstants.summaryCardDarkMode : Colors.white,
            shape: squircle.copyWith(
              side: BorderSide.none,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              Widget buildTextContent({required bool isFilled}) {
                final colorScheme = theme.colorScheme;
                final primaryColor = textColor;
                final secondaryColor = isFilled
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : const Color(0xFF1C1C1E).withValues(alpha: 0.85))
                    : colorScheme.onSurface.withValues(alpha: 0.8);

                // Subtle shadow only in dark mode on filled bar to enhance edge definition
                final shadows = (isFilled && isDark && value > 0)
                    ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 1),
                          blurRadius: 2.0,
                        ),
                      ]
                    : null;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingM,
                    vertical: DesignConstants.spacingXS,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          shadows: shadows,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customSubtitle ??
                            (hasTarget
                                ? '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'
                                : '${value.toStringAsFixed(1)} $unit'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryColor,
                          shadows: shadows,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Unfilled background text content
                  Positioned.fill(
                    child: buildTextContent(isFilled: false),
                  ),

                  // Layer 2: Clipped progress bar + filled text content
                  if (progress > 0)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _HorizontalProgressClipper(progress),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                              ),
                            ),
                            if (isDark && value > 0)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.6],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: buildTextContent(isFilled: true),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HorizontalProgressClipper extends CustomClipper<Rect> {
  final double progress;

  _HorizontalProgressClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_HorizontalProgressClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
