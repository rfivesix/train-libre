import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../statistics/domain/recovery_domain_service.dart';
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
        })
        .toList(growable: false);
    final totalEquivalentSets = muscles.fold<double>(
      0,
      (total, muscle) =>
          total + ((muscle['equivalentSets'] as num?)?.toDouble() ?? 0),
    );
    final muscleGroupCount = RecoveryDomainService.trackedMuscleGroups.isNotEmpty
        ? RecoveryDomainService.trackedMuscleGroups.length
        : muscles.length;
    final weeklySetsPerMuscle = muscles.isEmpty || muscleGroupCount <= 0
        ? 0.0
        : (totalEquivalentSets / _fixedMuscleWeeks) / muscleGroupCount;
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
                muscles.isEmpty
                    ? '–'
                    : '${weeklySetsPerMuscle.toStringAsFixed(1)} ${l10n.analyticsUnitSets} / ${l10n.analyticsPerWeekAbbrev}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (muscles.isEmpty) ...[
                const SizedBox(height: DesignConstants.spacingS),
                Text(
                  l10n.exerciseAnalyticsNoData,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
