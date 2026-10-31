import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';
import '../../domain/exercise_classification_labels.dart';
import '../../domain/models/exercise.dart';

/// What the catalog knows about the movement, as a row of chips.
///
/// Five axes the data repo annotates on 877 of 909 exercises. This screen is
/// the only place any of them is read: they are description, not machinery,
/// and nothing filters, groups or computes on the two added last.
///
/// [ExerciseClassificationLabels.forceVector] is derived upstream from
/// [ExerciseClassificationLabels.movementPattern], so where both exist the
/// pair reads a little doubled — "Ziehen · Vertikales Ziehen". Kept because
/// the force vector survives 62 static exercises that have no pattern anyone
/// would call a direction, and because the shorter word is the one a reader
/// scanning the row actually takes in.
///
/// Renders nothing at all when none of the five is set — a user-created
/// exercise, or one of the 32 unclassified catalog rows — rather than drawing
/// an empty strip above the description.
class ExerciseClassificationChips extends StatelessWidget {
  final Exercise exercise;

  const ExerciseClassificationChips({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      for (final label in [
        ExerciseClassificationLabels.mechanic(context, exercise.mechanic),
        ExerciseClassificationLabels.forceVector(context, exercise.forceVector),
        ExerciseClassificationLabels.movementPattern(
          context,
          exercise.movementPattern,
        ),
        ExerciseClassificationLabels.laterality(context, exercise.laterality),
        ExerciseClassificationLabels.difficulty(context, exercise.difficulty),
      ])
        if (label != null) label,
    ];
    if (labels.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Pill, outline and full-strength text. The first cut used
    // surfaceContainerHighest with onSurfaceVariant on top, which against the
    // near-black scaffold was an unlit rectangle behind grey text — three
    // words that read as a leftover rather than as the exercise's own
    // description of itself.
    //
    // Not the category badge's treatment either: that one is filled with the
    // accent colour and there is exactly one of it per screen, so three more
    // in the same paint would turn the top of the page into a traffic light.
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignConstants.spacingXL),
      child: Wrap(
        spacing: DesignConstants.spacingS,
        runSpacing: DesignConstants.spacingS,
        children: [
          for (final label in labels)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: DesignConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ExerciseCategoryBadge extends StatelessWidget {
  final String text;
  const ExerciseCategoryBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary.withValues(alpha: 0.15);
    final fg = theme.colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: DesignConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
