import 'package:flutter/material.dart';
import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/experience_level_service.dart';
import '../../../../services/profile_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/dual_body_highlighter.dart';
import '../../domain/body_slug_mapper.dart';
import '../../domain/models/exercise.dart';
import '../../domain/muscle_vocabulary.dart';

/// Displays front + back [BodyHighlighter] views side by side, plus a compact
/// chip legend listing primary and secondary muscle names.
class ExerciseMuscleBodyView extends StatelessWidget {
  final Exercise exercise;
  final MuscleVocabulary vocabulary;
  final bool showExerciseTitle;

  const ExerciseMuscleBodyView({
    super.key,
    required this.exercise,
    required this.vocabulary,
    this.showExerciseTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (exercise.isCardio) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Muscle ids are the precise annotation; the legacy name columns are what
    // the fifteen-name vocabulary could still express. 38 active exercises
    // have the former and nothing in the latter.
    final useIds = !vocabulary.isEmpty && exercise.primaryMuscleIds.isNotEmpty;
    final primaryLabels = useIds
        ? exercise.primaryMuscleIds
        : exercise.primaryMuscles;
    final secondaryLabels = useIds
        ? exercise.secondaryMuscleIds
        : exercise.secondaryMuscles;
    final hasMuscles = primaryLabels.isNotEmpty || secondaryLabels.isNotEmpty;

    if (!hasMuscles) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingS),
        child: Text(
          l10n.noMusclesSpecified,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    final allHighlights = useIds
        ? BodySlugMapper.mergedHighlightsFromIds(
            primaryMuscleIds: exercise.primaryMuscleIds,
            secondaryMuscleIds: exercise.secondaryMuscleIds,
            vocabulary: vocabulary,
          )
        : BodySlugMapper.mergedHighlights(
            primaryMuscles: exercise.primaryMuscles,
            secondaryMuscles: exercise.secondaryMuscles,
          );

    final frontHighlights = BodySlugMapper.forSide(
      allHighlights,
      BodySide.front,
    );
    final backHighlights = BodySlugMapper.forSide(allHighlights, BodySide.back);

    // The names are coarsened, the highlights above are not: a beginner reads
    // "shoulders" while the body map still paints the single head that works.
    final coarse = context
        .watch<ExperienceLevelService>()
        .usesCoarseMuscleNames;
    final resolvedVocabulary = useIds ? vocabulary : null;
    final primaryNames = BodySlugMapper.localizeAll(
      context,
      primaryLabels,
      vocabulary: resolvedVocabulary,
      coarse: coarse,
    );
    // A secondary muscle that coarsens into a primary region says nothing —
    // "shoulders" cannot be both the point of the exercise and an aside.
    final secondaryNames = BodySlugMapper.localizeAll(
      context,
      secondaryLabels,
      vocabulary: resolvedVocabulary,
      coarse: coarse,
    ).where((name) => !primaryNames.contains(name)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Body diagrams ──────────────────────────────────────────────
        DualBodyHighlighter(
          gender: context.watch<ProfileService>().gender.toBodyGender(),
          frontHighlights: frontHighlights,
          backHighlights: backHighlights,
        ),
        if (showExerciseTitle)
          Padding(
            padding: const EdgeInsets.only(top: DesignConstants.spacingL),
            child: Text(
              exercise.getLocalizedName(context),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        // ── Legend ─────────────────────────────────────────────────────
        const SizedBox(height: DesignConstants.spacingS),
        MuscleChipRow(
          label: l10n.primaryLabel,
          names: primaryNames,
          color: theme.colorScheme.primary,
        ),
        if (secondaryNames.isNotEmpty) ...[
          const SizedBox(height: 6),
          MuscleChipRow(
            label: l10n.secondaryLabel,
            names: secondaryNames,
            color: theme.colorScheme.primary.withValues(alpha: 0.45),
          ),
        ],
      ],
    );
  }
}

/// A labelled row of muscle names used as a text legend.
///
/// Takes names, not ids: which name a muscle gets — the head or its region —
/// is decided by the caller, together with the de-duplication that decision
/// makes necessary.
class MuscleChipRow extends StatelessWidget {
  final String label;
  final List<String> names;
  final Color color;

  const MuscleChipRow({
    super.key,
    required this.label,
    required this.names,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: names.map((name) {
                return Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
