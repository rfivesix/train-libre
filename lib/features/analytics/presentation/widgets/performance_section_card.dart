import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class PerformanceSectionCard extends StatelessWidget {
  final SectionLoadState<PerformanceRecordsSectionData> state;
  final String? chipText;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const PerformanceSectionCard({
    super.key,
    required this.state,
    this.chipText,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.performanceRecords;
    final title = l10n.analyticsNewBestPerformances;

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
    final notableImprovements = data?.notableImprovements ?? const [];

    final strongestImprovement = notableImprovements.isEmpty
        ? null
        : notableImprovements.reduce(
            (strongest, candidate) =>
                ((candidate['improvementPct'] as num?)?.toDouble() ?? 0) >
                        ((strongest['improvementPct'] as num?)?.toDouble() ?? 0)
                    ? candidate
                    : strongest,
          );
    final momentumValue = strongestImprovement == null
        ? '-'
        : '+${((strongestImprovement['improvementPct'] as num).toDouble()).toStringAsFixed(1)}%';
    final topExerciseName = strongestImprovement == null
        ? l10n.metricsMostImproved
        : (strongestImprovement['exerciseName'] as String? ??
            l10n.metricsMostImproved);
    final momentumColor = strongestImprovement == null
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).colorScheme.primary;

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
                chipText: chipText,
              ),
              const SizedBox(height: DesignConstants.spacingXS),
              Text(
                '${notableImprovements.length} ${l10n.analyticsInTimeframe.toLowerCase()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.analyticsTop}: $topExerciseName · $momentumValue',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: momentumColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
