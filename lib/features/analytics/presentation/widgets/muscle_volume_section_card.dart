import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class MuscleVolumeSectionCard extends StatelessWidget {
  final SectionLoadState<VolumeMusclesSectionData> state;
  final VoidCallback onRetry;
  final VoidCallback onTap;
  static const int _fixedMuscleWeeks = 8;

  const MuscleVolumeSectionCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.volumeMuscles;
    final title = l10n.analyticsMuscleGroups;

    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final data = state.data;
    final muscleAnalytics = data?.muscleAnalytics ?? const {};

    final muscles =
        (muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .where((m) {
              final group = m['muscleGroup'] as String?;
              return group != 'unclassified' &&
                  !StatisticsPresentationFormatter.isOtherCategoryLabel(group);
            })
            .toList()
          ..sort(
            (a, b) => ((b['equivalentSets'] as num?)?.toDouble() ?? 0)
                .compareTo((a['equivalentSets'] as num?)?.toDouble() ?? 0),
          );
    final topMuscles = muscles.take(3).toList(growable: false);
    final topMuscle = topMuscles.isNotEmpty ? topMuscles.first : null;
    final totalEquivalentSets = muscles.fold<double>(
      0,
      (total, muscle) =>
          total + ((muscle['equivalentSets'] as num?)?.toDouble() ?? 0),
    );
    final weeklySets = totalEquivalentSets / _fixedMuscleWeeks;
    final topMuscleSets =
        ((topMuscle?['equivalentSets'] as num?)?.toDouble() ?? 0) /
        _fixedMuscleWeeks;
    final theme = Theme.of(context);

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(DesignConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnalyticsCardBase.buildHeaderWithChevron(
                context,
                label: title,
                trailingIcon: true,
                chipText: l10n.analyticsLastWeeks(_fixedMuscleWeeks),
              ),
              const SizedBox(height: DesignConstants.spacingXS),
              Text(
                topMuscle == null
                    ? '–'
                    : '${weeklySets.toStringAsFixed(1)} ${l10n.analyticsUnitSets} / ${l10n.analyticsPerWeekAbbrev}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: DesignConstants.spacingS),
              if (topMuscles.isEmpty)
                Text(
                  l10n.exerciseAnalyticsNoData,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < topMuscles.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _buildMuscleBarRow(
                        context,
                        label: _formatMuscleLabel(
                          l10n,
                          topMuscles[i]['muscleGroup'] as String?,
                        ),
                        setsPerWeek:
                            ((topMuscles[i]['equivalentSets'] as num?)
                                    ?.toDouble() ??
                                0) /
                            _fixedMuscleWeeks,
                        maxSetsPerWeek: topMuscleSets > 0 ? topMuscleSets : 1.0,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleBarRow(
    BuildContext context, {
    required String label,
    required double setsPerWeek,
    required double maxSetsPerWeek,
  }) {
    final theme = Theme.of(context);
    final ratio = (setsPerWeek / maxSetsPerWeek).clamp(0.08, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignConstants.spacingS),
        SizedBox(
          width: 44,
          child: Text(
            setsPerWeek.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatMuscleLabel(AppLocalizations l10n, String? label) {
    if (label == null || label.trim().isEmpty) {
      return _noClearFocusLabel(l10n);
    }
    final normalized = label.trim();
    if (StatisticsPresentationFormatter.isOtherCategoryLabel(normalized)) {
      return _noClearFocusLabel(l10n);
    }
    return StatisticsPresentationFormatter.muscleGroupLabel(l10n, normalized);
  }

  String _noClearFocusLabel(AppLocalizations l10n) {
    final source = l10n.analyticsGuidanceNoClearWeakPoint;
    final stripped = source.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    return stripped.trim().isEmpty ? source : stripped.trim();
  }
}
