import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import '../../../exercise_catalog/domain/body_slug_mapper.dart';

/// Helper utility to map muscle volumes/workloads to dynamic Material Theme primary colors.
class MuscleColorHelper {
  const MuscleColorHelper._();

  /// Maps a workload dictionary of raw muscle names to [BodyPartHighlightData]
  /// objects colored according to the context primary color's alpha tiers.
  static List<BodyPartHighlightData> mapVolumeToPrimaryColors(
    BuildContext context,
    Map<String, double> rawWorkload,
  ) {
    final slugWorkload = <BodyPartSlug, double>{};
    for (final entry in rawWorkload.entries) {
      final slugs = BodySlugMapper.fromRawName(entry.key);
      for (final slug in slugs) {
        slugWorkload[slug] = (slugWorkload[slug] ?? 0.0) + entry.value;
      }
    }
    return mapSlugWorkloadToPrimaryColors(context, slugWorkload);
  }

  /// Maps a workload dictionary of [BodyPartSlug]s to [BodyPartHighlightData]
  /// objects colored according to the context primary color's alpha tiers.
  static List<BodyPartHighlightData> mapSlugWorkloadToPrimaryColors(
    BuildContext context,
    Map<BodyPartSlug, double> slugWorkload,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = [
      primary.withValues(alpha: 0.15),
      primary.withValues(alpha: 0.35),
      primary.withValues(alpha: 0.55),
      primary.withValues(alpha: 0.75),
      primary,
    ];

    final maxVal = slugWorkload.isEmpty
        ? 0.0
        : slugWorkload.values.reduce((a, b) => a > b ? a : b);

    return slugWorkload.entries.map((entry) {
      final intensity =
          maxVal > 0.0 ? (entry.value / maxVal * 5).ceil().clamp(1, 5) : 1;
      final color = colors[intensity - 1];
      return BodyPartHighlightData(
        slug: entry.key,
        color: color,
      );
    }).toList();
  }
}
