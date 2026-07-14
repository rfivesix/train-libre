import 'package:flutter/material.dart';

class BenchmarkSegment {
  /// The upper bound of this segment (in the same units as min/max)
  final double limit;
  final Color color;
  /// Optional label to draw exactly at this boundary (e.g., '7h')
  final String? label;

  const BenchmarkSegment({
    required this.limit,
    required this.color,
    this.label,
  });
}

class SleepBenchmarkBar extends StatelessWidget {
  const SleepBenchmarkBar({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.segments,
    this.minLabel,
    this.maxLabel,
  });

  final double min;
  final double max;
  final double? value;
  final List<BenchmarkSegment> segments;
  final String? minLabel;
  final String? maxLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final range = (max - min).abs() < 0.0001 ? 1.0 : (max - min);
    final marker =
        value == null ? null : ((value! - min) / range).clamp(0.0, 1.0);
    final trackRadius = BorderRadius.circular(999);
    final trackColor = isDark
        ? const Color(0xFF4A4F57)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final markerColor = Theme.of(context).colorScheme.primary;
    final markerWidth = 7.0;

    final sortedSegments = List<BenchmarkSegment>.from(segments)
      ..sort((a, b) => a.limit.compareTo(b.limit));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: trackRadius,
                child: Container(height: 10, color: trackColor),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final children = <Widget>[];

                    double currentLeft = 0.0;
                    for (final segment in sortedSegments) {
                      final segmentFraction =
                          ((segment.limit - min) / range).clamp(0.0, 1.0);
                      final rightFraction = 1.0 - segmentFraction;

                      children.add(
                        Positioned(
                          left: currentLeft * constraints.maxWidth,
                          right: rightFraction * constraints.maxWidth,
                          top: 12,
                          bottom: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: segment.color.withValues(
                                alpha: isDark ? 0.78 : 0.6,
                              ),
                              borderRadius: currentLeft == 0.0 && segmentFraction == 1.0
                                  ? trackRadius
                                  : BorderRadius.horizontal(
                                      left: currentLeft == 0.0
                                          ? const Radius.circular(999)
                                          : Radius.zero,
                                      right: segmentFraction == 1.0
                                          ? const Radius.circular(999)
                                          : Radius.zero,
                                    ),
                            ),
                          ),
                        ),
                      );
                      currentLeft = segmentFraction;
                    }

                    if (marker != null) {
                      final outlineColor = Theme.of(context).scaffoldBackgroundColor;
                      children.add(
                        Positioned(
                          left: marker * constraints.maxWidth - (markerWidth / 2),
                          top: 4,
                          bottom: 4,
                          child: Container(
                            width: markerWidth,
                            decoration: BoxDecoration(
                              color: markerColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: outlineColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Stack(clipBehavior: Clip.none, children: children);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final labels = <Widget>[];
            final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                );

            if (minLabel != null) {
              labels.add(
                Positioned(
                  left: 0,
                  child: Text(minLabel!, style: textStyle),
                ),
              );
            }

            if (maxLabel != null) {
              labels.add(
                Positioned(
                  right: 0,
                  child: Text(maxLabel!, style: textStyle),
                ),
              );
            }

            for (final segment in sortedSegments) {
              if (segment.label != null && segment.limit > min && segment.limit < max) {
                final fraction = ((segment.limit - min) / range).clamp(0.0, 1.0);
                labels.add(
                  Positioned(
                    left: fraction * constraints.maxWidth,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(segment.label!, style: textStyle),
                    ),
                  ),
                );
              }
            }

            return SizedBox(
              height: 16,
              child: Stack(
                clipBehavior: Clip.none,
                children: labels,
              ),
            );
          },
        ),
      ],
    );
  }
}
