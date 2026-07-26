// lib/widgets/glass_progress_bar.dart
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

  const GlassProgressBar({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    this.height = 54.0,
    this.borderRadius = DesignConstants.borderRadiusL,
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
    if (oldWidget.value != widget.value ||
        oldWidget.target != widget.target) {
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

  const _GlassProgressBarPainter({
    required this.label,
    required this.unit,
    required this.value,
    required this.target,
    required this.color,
    required this.height,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hasTarget = target > 0;
    final rawProgress = hasTarget ? (value / target) : 0.0;
    final progress = rawProgress.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(borderRadius);

    // Crisp, minimal text shadow for edge definition, only if bar has progress
    final textShadows = value > 0
        ? [
            Shadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 1),
              blurRadius: 2.0,
            ),
          ]
        : null;

    // Heuristic for readability: if the bar color contrast with text is low,
    // we add a subtle readability scrim behind the text area.
    // Only applied if there is actual progress color to contrast with.
    final luminance = color.computeLuminance();
    final bool isLowContrast = isDark ? (luminance > 0.5) : (luminance < 0.5);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            blurRadius: 7,
            offset: const Offset(0, 2),
            color: cs.shadow.withValues(alpha: isDark ? 0.2 : 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : cs.surface.withValues(alpha: 0.95),
            borderRadius: radius,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              Widget buildTextContent({required bool withShadow}) {
                final colorScheme = theme.colorScheme;
                final Color filledTextColor =
                    theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black;

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
                          color: filledTextColor,
                          shadows: withShadow ? textShadows : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTarget
                            ? '${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'
                            : '${value.toStringAsFixed(1)} $unit',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: withShadow
                              ? filledTextColor.withValues(alpha: 0.9)
                              : colorScheme.onSurface,
                          shadows: withShadow ? textShadows : null,
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
                  // Layer 1: Unfilled background text content (no shadow, track color)
                  Positioned.fill(
                    child: buildTextContent(withShadow: false),
                  ),

                  // Layer 2: Clipped progress bar + filled text content (with shadow)
                  if (progress > 0)
                    Positioned.fill(
                      child: ClipRect(
                        clipper: _HorizontalProgressClipper(progress),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: color),
                            if ((isLowContrast || isDark) && value > 0)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.1,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.6],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned.fill(
                              child: buildTextContent(withShadow: true),
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
