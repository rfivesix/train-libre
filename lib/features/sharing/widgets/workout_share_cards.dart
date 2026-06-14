part of '../share_card_renderer.dart';

class _WorkoutSummaryCard extends StatelessWidget {
  const _WorkoutSummaryCard({required this.stats, required this.labels});

  final WorkoutShareStats stats;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageSummary),
        const SizedBox(height: 30),
        _Title(stats.title),
        const SizedBox(height: 22),
        _Subtitle(stats.date),
        const SizedBox(height: 68),
        _MetricGrid(
          metrics: [
            _Metric(labels.duration, stats.duration ?? '-'),
            _Metric(labels.volume, stats.volume ?? '-'),
            _Metric(labels.exercises, '${stats.exerciseCount}'),
            _Metric(labels.sets, '${stats.setCount}'),
          ],
        ),
      ],
    );
  }
}

class _WorkoutExerciseListCard extends StatelessWidget {
  const _WorkoutExerciseListCard({
    required this.stats,
    required this.rows,
    required this.remainingCount,
    required this.labels,
  });

  final WorkoutShareStats stats;
  final List<WorkoutShareExerciseSummary> rows;
  final int remainingCount;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageExercises),
        const SizedBox(height: 26),
        _Title(stats.title, maxLines: 2),
        const SizedBox(height: 22),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            if (stats.volume != null) stats.volume,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const SizedBox(height: 50),
        for (final row in rows)
          _ExercisePill(count: row.detail, name: row.name),
        if (remainingCount > 0) _MoreLine(labels.moreExercises(remainingCount)),
      ],
    );
  }
}

class _WorkoutMuscleFocusCard extends StatelessWidget {
  const _WorkoutMuscleFocusCard({
    required this.stats,
    required this.muscles,
    required this.labels,
  });

  final WorkoutShareStats stats;
  final List<MuscleVolumeSummary> muscles;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    final maxVolume =
        muscles.isEmpty ? 0.0 : muscles.map((m) => m.volume).reduce(math.max);
    final showRadar = muscles.length >= 3 && maxVolume > 0;
    final visibleMuscles = muscles.take(showRadar ? 3 : 4);
    final workload = <String, double>{};
    for (final m in muscles) {
      workload[m.name] = m.volume;
    }
    final highlights = MuscleColorHelper.mapVolumeToPrimaryColors(context, workload);

    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageMuscleFocus),
        const SizedBox(height: 26),
        _Title(stats.title, maxLines: 2),
        const SizedBox(height: 22),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            if (stats.volume != null) stats.volume,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const SizedBox(height: 34),
        if (showRadar)
          Center(
            child: SizedBox(
              width: 700,
              height: 400,
              child: Row(
                children: [
                  Expanded(
                    child: BodyHighlighter(
                      gender: context.read<ProfileService>().gender.toBodyGender(),
                      side: BodySide.front,
                      highlightedParts: BodySlugMapper.forSide(highlights, BodySide.front),
                      outlineWidth: 2.0,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: BodyHighlighter(
                      gender: context.read<ProfileService>().gender.toBodyGender(),
                      side: BodySide.back,
                      highlightedParts: BodySlugMapper.forSide(highlights, BodySide.back),
                      outlineWidth: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        for (final muscle in visibleMuscles)
          _MuscleVolumePill(muscle: muscle, maxVolume: maxVolume),
      ],
    );
  }
}

class _WorkoutMinimalCard extends StatelessWidget {
  const _WorkoutMinimalCard({required this.stats, required this.labels});

  final WorkoutShareStats stats;
  final ShareLabels labels;

  @override
  Widget build(BuildContext context) {
    return _ShareScaffold(
      labels: labels,
      children: [
        _Kicker(labels.shareImageMinimal),
        const Spacer(),
        _Title(stats.title, maxLines: 3),
        const SizedBox(height: 46),
        _HugeMetric(stats.volume ?? stats.duration ?? '${stats.setCount}'),
        const SizedBox(height: 18),
        _Subtitle(
          [
            if (stats.duration != null) stats.duration,
            '${stats.setCount} ${labels.sets}',
          ].join(' · '),
        ),
        const Spacer(),
      ],
    );
  }
}
