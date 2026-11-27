import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/presentation/statistics_formatter.dart';
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

    final unitService = context.watch<UnitService>();
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
    final String momentumValue;
    if (strongestImprovement == null) {
      momentumValue = '-';
    } else {
      final weightKg =
          (strongestImprovement['weightKg'] as num?)?.toDouble() ??
          (strongestImprovement['newBestWeight'] as num?)?.toDouble() ??
          0.0;
      final reps = (strongestImprovement['reps'] as num?)?.toInt();
      final displayWeight = unitService.convertDisplayValue(
        weightKg,
        UnitDimension.weight,
      );
      final weightText =
          '${StatisticsPresentationFormatter.formatWeight(displayWeight)} ${unitService.suffixFor(UnitDimension.weight)}';
      momentumValue = reps != null && reps > 0
          ? '$weightText × $reps'
          : weightText;
    }
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
                chipText: chipText,
              ),
              const SizedBox(height: DesignConstants.spacingXS),
              Text(
                l10n.statisticsBestPerformancesCount(notableImprovements.length),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignConstants.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: momentumColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${l10n.analyticsTop}: $topExerciseName · $momentumValue',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: momentumColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
