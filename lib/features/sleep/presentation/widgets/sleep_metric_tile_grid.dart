import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../domain/sleep_domain.dart';
import '../../data/sleep_day_repository.dart';
import '../sleep_navigation.dart';

class SleepMetricTileGrid extends StatelessWidget {
  const SleepMetricTileGrid({super.key, required this.overview});

  final SleepDayOverviewData overview;

  Widget _buildTwoColumnGrid(List<Widget> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: DesignConstants.spacingS,
          mainAxisSpacing: DesignConstants.spacingS,
          childAspectRatio: 2.45,
          children: items,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final regularitySubtitle = overview.regularityNights.isEmpty
        ? l10n.sleepMetricUnavailable
        : l10n.sleepRegularityNightView(
            overview.regularityNights.length.clamp(0, 7),
          );

    return _buildTwoColumnGrid([
      ValueSummaryCard(
        label: l10n.sleepMetricDurationTitle,
        value: '${overview.totalSleepDuration.inHours}h ${overview.totalSleepDuration.inMinutes.remainder(60)}m',
        onTap: () => SleepNavigation.openDurationDetail(context, overview: overview),
      ),
      ValueSummaryCard(
        label: l10n.sleepMetricHeartRateTitle,
        value: overview.sleepHrAvg == null
            ? l10n.sleepMetricUnavailable
            : '${overview.sleepHrAvg!.round()}',
        subtitle: overview.sleepHrAvg == null ? null : l10n.sleepBpmUnit,
        onTap: () => SleepNavigation.openHeartRateDetail(context, overview: overview),
      ),
      ValueSummaryCard(
        label: l10n.sleepMetricRegularityTitle,
        value: regularitySubtitle,
        onTap: () => SleepNavigation.openRegularityDetail(context, overview: overview),
      ),
      ValueSummaryCard(
        label: l10n.sleepMetricDepthTitle,
        value: overview.stageDataConfidence == SleepStageConfidence.low
            ? l10n.sleepMetricDepthLowConfidence
            : (overview.hasStageData
                ? l10n.sleepMetricDepthStagesAvailable
                : l10n.sleepMetricUnavailable),
        onTap: () => SleepNavigation.openDepthDetail(context, overview: overview),
      ),
      ValueSummaryCard(
        label: l10n.sleepMetricInterruptionsTitle,
        value: overview.interruptionsCount == null
            ? l10n.sleepMetricUnavailable
            : '${overview.interruptionsCount}',
        onTap: () => SleepNavigation.openInterruptionsDetail(context, overview: overview),
      ),
    ]);
  }
}
