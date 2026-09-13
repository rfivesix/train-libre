import 'package:flutter/material.dart';
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

    final muscles = (muscleAnalytics['muscles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .where((m) {
      final group = m['muscleGroup'] as String?;
      return group != 'unclassified' &&
          !StatisticsPresentationFormatter.isOtherCategoryLabel(group);
    }).toList()
      ..sort(
        (a, b) => ((b['equivalentSets'] as num?)?.toDouble() ?? 0).compareTo(
          (a['equivalentSets'] as num?)?.toDouble() ?? 0,
        ),
      );
    final topMuscle = muscles.isNotEmpty ? muscles.first : null;
    final totalEquivalentSets = muscles.fold<double>(
      0,
      (total, muscle) =>
          total + ((muscle['equivalentSets'] as num?)?.toDouble() ?? 0),
    );
    final weeklySets = totalEquivalentSets / _fixedMuscleWeeks;
    final topMuscleSets =
        ((topMuscle?['equivalentSets'] as num?)?.toDouble() ?? 0) /
            _fixedMuscleWeeks;

    return AnalyticsCardBase.decorateSectionCard(
      context,
      state: state,
      child: SummaryCard(
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                topMuscle == null
                    ? l10n.exerciseAnalyticsNoData
                    : '${_formatMuscleLabel(l10n, topMuscle['muscleGroup'] as String?)} · ${topMuscleSets.toStringAsFixed(1)} ${l10n.analyticsUnitSets} / ${l10n.analyticsPerWeekAbbrev}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
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
    return normalized;
  }

  String _noClearFocusLabel(AppLocalizations l10n) {
    final source = l10n.analyticsGuidanceNoClearWeakPoint;
    final stripped = source.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
    return stripped.trim().isEmpty ? source : stripped.trim();
  }
}
