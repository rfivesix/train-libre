import 'package:flutter/material.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../../util/design_constants.dart';

import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/health/workout_heart_rate_models.dart';
import '../../../analytics/domain/models/chart_data_point.dart';
import '../../../profile/presentation/widgets/measurement_chart_widget.dart';

/// A self-contained section to display heart rate metrics and charts for a workout window.
class WorkoutHeartRateSection extends StatelessWidget {
  final WorkoutHeartRateSummary summary;
  final bool pulseTrackingEnabled;

  const WorkoutHeartRateSection({
    super.key,
    required this.summary,
    required this.pulseTrackingEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final timeFormatter = DateFormat.Hm(locale);
    final points = summary.chartSamples
        .map(
          (sample) => ChartDataPoint(
            date: sample.sampledAtUtc.toLocal(),
            value: sample.bpm,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.workoutHeartRateSectionTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (summary.hasSummaryMetrics)
                _buildTwoColumnGrid([
                  ValueSummaryCard(
                    label: l10n.workoutHeartRateAverageLabel,
                    value: '${summary.averageBpm!.round()}',
                    subtitle: l10n.sleepBpmUnit,
                  ),
                  ValueSummaryCard(
                    label: l10n.workoutHeartRateMaxLabel,
                    value: '${summary.maxBpm!.round()}',
                    subtitle: l10n.sleepBpmUnit,
                  ),
                  ValueSummaryCard(
                    label: l10n.workoutHeartRateMinLabel,
                    value: '${summary.minBpm!.round()}',
                    subtitle: l10n.sleepBpmUnit,
                  ),
                ])
              else
                Text(
                  _heartRateNoDataMessage(l10n, summary.noDataReason),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (summary.canRenderChart)
          MeasurementChartWidget.fromData(
            dataPoints: points,
            unit: l10n.sleepBpmUnit,
            axisMode: MeasurementChartAxisMode.time,
            valueFractionDigits: 0,
            valueLabelBuilder: (value, unit) => '${value.round()} $unit',
            selectedDateLabelBuilder: (value) => timeFormatter.format(value),
            axisLabelBuilder: (value, _) => timeFormatter.format(value),
            edgeToEdge: true,
          )
        else if (summary.hasSummaryMetrics)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.screenPaddingHorizontal,
            ),
            child: Text(
              summary.quality == WorkoutHeartRateDataQuality.insufficient
                  ? l10n.workoutHeartRateLimitedChartHint
                  : _heartRateNoDataMessage(l10n, summary.noDataReason),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
        const SizedBox(height: DesignConstants.spacingS),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.screenPaddingHorizontal,
          ),
          child: Text(
            '${l10n.workoutHeartRateSampleCount(summary.sampleCount)} • ${_heartRateQualityLabel(l10n, summary.quality)}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    List<Widget> rows = [];
    for (int i = 0; i < items.length; i += 2) {
      Widget left = items[i];
      Widget right = i + 1 < items.length ? items[i + 1] : const SizedBox();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(child: right),
            ],
          ),
        ),
      );
      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: DesignConstants.spacingS));
      }
    }
    return Column(children: rows);
  }

  String _heartRateQualityLabel(
    AppLocalizations l10n,
    WorkoutHeartRateDataQuality quality,
  ) {
    return switch (quality) {
      WorkoutHeartRateDataQuality.ready => l10n.workoutHeartRateQualityReady,
      WorkoutHeartRateDataQuality.limited =>
        l10n.workoutHeartRateQualityLimited,
      WorkoutHeartRateDataQuality.insufficient =>
        l10n.workoutHeartRateQualityInsufficient,
      WorkoutHeartRateDataQuality.noData => l10n.workoutHeartRateQualityNoData,
    };
  }

  String _heartRateNoDataMessage(
    AppLocalizations l10n,
    WorkoutHeartRateNoDataReason reason,
  ) {
    return switch (reason) {
      WorkoutHeartRateNoDataReason.permissionDenied =>
        l10n.workoutHeartRateNoDataPermission,
      WorkoutHeartRateNoDataReason.platformUnavailable =>
        l10n.workoutHeartRateNoDataUnavailable,
      WorkoutHeartRateNoDataReason.workoutNotFinished =>
        l10n.workoutHeartRateNoDataWorkoutNotFinished,
      WorkoutHeartRateNoDataReason.invalidWorkoutWindow =>
        l10n.workoutHeartRateNoDataInvalidWindow,
      WorkoutHeartRateNoDataReason.queryFailed =>
        l10n.workoutHeartRateNoDataQueryFailed,
      _ => l10n.workoutHeartRateNoDataGeneral,
    };
  }
}
