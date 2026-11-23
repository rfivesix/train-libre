import 'package:flutter_body_highlighter/flutter_body_highlighter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/profile_service.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/time_util.dart';
import '../../../../widgets/common/dual_body_highlighter.dart';
import '../../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../exercise_catalog/domain/body_slug_mapper.dart';
import '../../../exercise_catalog/domain/muscle_group_normalizer.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_log.dart';
import '../live_workout_view_model.dart';

/// The live workout's progress; the history summary has a separate layout.
class LiveWorkoutSummaryBar extends StatelessWidget {
  static const double preferredHeight = 70.0;

  const LiveWorkoutSummaryBar({super.key, required this.workout});

  final LiveWorkoutViewModel workout;

  @override
  Widget build(BuildContext context) {
    final units = context.watch<UnitService>();
    final completed = workout.setLogs.values
        .where((s) => s.isCompleted == true)
        .length;
    final total = workout.setLogs.length;
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    final trackBg = Color.alphaBlend(
      color.onSurface.withValues(alpha: 0.16),
      theme.scaffoldBackgroundColor,
    ).withValues(alpha: 0.65);
    final badgeBg = Color.alphaBlend(
      color.onSurface.withValues(alpha: 0.12),
      theme.scaffoldBackgroundColor,
    ).withValues(alpha: 0.72);
    final muscles = SessionMuscleCoverage.fromWorkout(
      workout.exercises,
      workout.setLogs,
    );
    final highlights = muscles.highlights(color.primary);
    final gender = context.watch<ProfileService>().gender.toBodyGender();
    final volume = units.convertDisplayValue(
      workout.totalVolume,
      UnitDimension.weight,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : completed / total,
                      minHeight: 6,
                      backgroundColor: trackBg,
                      color: color.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${volume.toStringAsFixed(0)} ${units.suffixFor(UnitDimension.weight)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatDuration(workout.elapsedDuration),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      total == 0 ? '0' : '$completed / $total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      button: true,
                      label: AppLocalizations.of(context)!.sessionMusclesTitle,
                      child: InkWell(
                        key: const ValueKey('session-muscle-badge'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showGlassBottomMenu<void>(
                          context: context,
                          contentBuilder: (context, close) =>
                              _SessionMuscleSheet(close: close),
                        ),
                        child: Container(
                          width: 54,
                          height: 36,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DualBodyHighlighter(
                            gender: gender,
                            height: 32,
                            outlineWidth: 0.4,
                            frontHighlights: BodySlugMapper.forSide(
                              highlights,
                              BodySide.front,
                            ),
                            backHighlights: BodySlugMapper.forSide(
                              highlights,
                              BodySide.back,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MuscleCoverageCount {
  MuscleCoverageCount();
  int completed = 0;
  int total = 0;
}

/// Each exercise contributes each of its sets once to every targeted muscle.
class SessionMuscleCoverage {
  SessionMuscleCoverage(this.counts);
  final Map<String, MuscleCoverageCount> counts;

  factory SessionMuscleCoverage.fromWorkout(
    List<RoutineExercise> exercises,
    Map<int, SetLog> logs,
  ) {
    final counts = <String, MuscleCoverageCount>{};
    for (final block in exercises) {
      if (block.exercise.isCardio) continue;
      final sets = block.setTemplates
          .map((t) => logs[t.id])
          .whereType<SetLog>()
          .toList();
      if (sets.isEmpty) continue;
      final names = {
        ...block.exercise.primaryMuscles,
        ...block.exercise.secondaryMuscles,
      }.map(coarseMuscleGroupKey).where((name) => name.isNotEmpty).toSet();
      for (final name in names) {
        final count = counts.putIfAbsent(name, MuscleCoverageCount.new);
        count.total += sets.length;
        count.completed += sets.where((s) => s.isCompleted == true).length;
      }
    }
    return SessionMuscleCoverage(counts);
  }

  List<BodyPartHighlightData> highlights(Color primary) {
    final bySlug = <BodyPartSlug, bool>{};
    for (final entry in counts.entries) {
      for (final slug in BodySlugMapper.fromRawName(entry.key)) {
        bySlug[slug] = (bySlug[slug] ?? false) || entry.value.completed > 0;
      }
    }
    return bySlug.entries
        .map(
          (e) => BodyPartHighlightData(
            slug: e.key,
            color: primary.withValues(alpha: e.value ? 1 : 0.3),
          ),
        )
        .toList();
  }
}

class _SessionMuscleSheet extends StatefulWidget {
  const _SessionMuscleSheet({required this.close});
  final VoidCallback close;
  @override
  State<_SessionMuscleSheet> createState() => _SessionMuscleSheetState();
}

class _SessionMuscleSheetState extends State<_SessionMuscleSheet> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final workout = context.watch<LiveWorkoutViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final coverage = SessionMuscleCoverage.fromWorkout(
      workout.exercises,
      workout.setLogs,
    );
    final entries = coverage.counts.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final highlights = coverage.highlights(primary);
    final gender = context.watch<ProfileService>().gender.toBodyGender();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.sessionMusclesTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.close,
              child: Text(l10n.doneButtonLabel),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DualBodyHighlighter(
          gender: gender,
          height: 270,
          frontHighlights: BodySlugMapper.forSide(highlights, BodySide.front),
          backHighlights: BodySlugMapper.forSide(highlights, BodySide.back),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            _Legend(color: primary, label: l10n.sessionMusclesWorked),
            _Legend(
              color: primary.withValues(alpha: 0.3),
              label: l10n.sessionMusclesRemaining,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          Text(l10n.noMusclesSpecified, style: theme.textTheme.bodyMedium),
        for (final entry in expanded ? entries : entries.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    BodySlugMapper.localize(context, entry.key),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: entry.value.total == 0
                          ? 0
                          : entry.value.completed / entry.value.total,
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.15,
                      ),
                      color: primary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    '${entry.value.completed}/${entry.value.total}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (entries.length > 6)
          Center(
            child: TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              child: Text(expanded ? l10n.showLess : l10n.showMoreDetails),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 7),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
