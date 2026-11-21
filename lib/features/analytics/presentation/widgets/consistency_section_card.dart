import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class ConsistencySectionCard extends StatelessWidget {
  final SectionLoadState<ConsistencySectionData> state;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  static const int _fixedConsistencyWeeks = 6;

  const ConsistencySectionCard({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.consistency;
    final title = l10n.consistencyTrackerTitle;

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
    final workoutsPerWeek = data?.workoutsPerWeek ?? const [];
    final trainingStats = data?.trainingStats;
    final totalWorkouts =
        data?.recentWorkoutCount ??
        workoutsPerWeek.fold<int>(
          0,
          (total, week) => total + ((week['count'] as num?)?.toInt() ?? 0),
        );
    final streakText = trainingStats == null
        ? '${l10n.streakLabel}: -'
        : '${l10n.streakLabel}: ${trainingStats.streakWeeks} ${l10n.weeksLabel}';
    final weeklyBarValues = (data?.weeklyConsistencyMetrics.isNotEmpty ?? false)
        ? data!.weeklyConsistencyMetrics
              .map((w) => w.count.toDouble())
              .toList(growable: false)
        : workoutsPerWeek
              .map((w) => ((w['count'] as num?)?.toDouble() ?? 0.0))
              .toList(growable: false);

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
                chipText: _fixedWeeksChipLabel(l10n, _fixedConsistencyWeeks),
              ),
              const SizedBox(height: DesignConstants.spacingS),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainingStats == null
                              ? '-'
                              : '$totalWorkouts ${l10n.workoutsLabel}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streakText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (weeklyBarValues.isNotEmpty) ...[
                    const SizedBox(width: DesignConstants.spacingM),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 36,
                        child: AnalyticsCardBase.buildMiniBars(
                          context,
                          values: weeklyBarValues,
                          color: Theme.of(context).colorScheme.primary,
                          semanticsLabel: title,
                        ),
                      ),
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

  String _fixedWeeksChipLabel(AppLocalizations l10n, int weeks) {
    return l10n.analyticsLastWeeks(weeks);
  }
}
