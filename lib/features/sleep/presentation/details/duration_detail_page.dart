import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/metrics/sleep_thresholds.dart';
import 'sleep_data_unavailable_card.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';
import 'widgets/sleep_benchmark_bar.dart';

class DurationDetailPage extends StatelessWidget {
  const DurationDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sleepMetricDurationTitle)),
        body: Padding(
          padding: EdgeInsets.all(DesignConstants.spacingL),
          child: SleepDataUnavailableCard(
            message: l10n.sleepDurationUnavailable,
          ),
        ),
      );
    }
    final duration = overview.totalSleepDuration;
    if (duration <= Duration.zero) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.sleepMetricDurationTitle)),
        body: Padding(
          padding: EdgeInsets.all(DesignConstants.spacingL),
          child: SleepDataUnavailableCard(
            message: l10n.sleepDurationUnavailable,
          ),
        ),
      );
    }
    final status = duration.inHours >= SleepDurationThresholds.optimalLowerHours
        ? l10n.sleepDurationStatusWithinTarget
        : l10n.sleepDurationStatusBelowTarget;
        
    final min = SleepDurationThresholds.minDisplayHours.toDouble() * 60.0;
    final max = SleepDurationThresholds.maxDisplayHours.toDouble() * 60.0;
    
    return SleepDetailPageShell(
      title: l10n.sleepMetricDurationTitle,
      value: formatDuration(duration),
      statusLabel: status,
      subtitle: l10n.sleepDurationSubtitle,
      statusColor: SleepDurationThresholds.getColorForHours(duration.inMinutes / 60.0),
      children: [
        SleepBenchmarkBar(
          min: min,
          max: max,
          value: duration.inMinutes.toDouble(),
          minLabel: '${SleepDurationThresholds.minDisplayHours}h',
          maxLabel: '${SleepDurationThresholds.maxDisplayHours}h',
          segments: [
            BenchmarkSegment(
              limit: SleepDurationThresholds.criticalLowerHours * 60.0,
              color: Colors.red,
              label: '${SleepDurationThresholds.criticalLowerHours.toInt()}h',
            ),
            BenchmarkSegment(
              limit: SleepDurationThresholds.optimalLowerHours * 60.0,
              color: Colors.orange,
              label: '${SleepDurationThresholds.optimalLowerHours.toInt()}h',
            ),
            BenchmarkSegment(
              limit: SleepDurationThresholds.optimalUpperHours * 60.0,
              color: Colors.green,
              label: '${SleepDurationThresholds.optimalUpperHours.toInt()}h',
            ),
            BenchmarkSegment(
              limit: SleepDurationThresholds.criticalUpperHours * 60.0,
              color: Colors.orange,
              label: '${SleepDurationThresholds.criticalUpperHours.toStringAsFixed(1).replaceAll('.0', '')}h',
            ),
            BenchmarkSegment(
              limit: max,
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingM),
        Text(l10n.sleepDurationBenchmarkHint),
      ],
    );
  }
}
