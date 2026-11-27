// UNUSED SCREEN: No longer linked from the sleep UI. Retained temporarily;
// review and remove once the replacement has been verified. The named route
// remains registered for compatibility.

import 'package:material_ui/material_ui.dart';

import '../../../../util/design_constants.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/sleep_day_repository.dart';
import '../../domain/sleep_enums.dart';
import 'sleep_detail_page_shell.dart';
import 'sleep_metric_formatters.dart';

class DepthDetailPage extends StatelessWidget {
  const DepthDetailPage({super.key, this.overview});

  final SleepDayOverviewData? overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = this.overview;
    if (overview == null) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthUnavailable,
      );
    }

    final hasReliableStageData =
        overview.hasStageData &&
        overview.stageDataConfidence != SleepStageConfidence.low;

    if (!hasReliableStageData) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthConfidenceTooLow,
      );
    }

    if (!overview.hasStageDurations) {
      return SleepDetailUnavailablePage(
        title: l10n.sleepMetricDepthTitle,
        message: l10n.sleepDepthBreakdownUnavailable,
      );
    }

    final deepDuration = overview.deepDuration;
    final lightDuration = overview.lightDuration;
    final remDuration = overview.remDuration;
    final totalMinutes = overview.totalSleepMinutes;
    double? percentage(Duration? value) =>
        value == null || totalMinutes == null || totalMinutes <= 0
        ? null
        : value.inMinutes / totalMinutes * 100;

    return SleepDetailPageShell(
      title: l10n.sleepMetricDepthTitle,
      value: l10n.sleepDashboardStageEstimate,
      statusLabel: l10n.sleepDepthStageConfidenceLabel(
        overview.stageDataConfidence.name,
      ),
      subtitle: l10n.sleepDepthSubtitle,
      children: [
        SizedBox(
          height: 16,
          child: Row(
            children: [
              Expanded(
                flex: deepDuration?.inMinutes ?? 0,
                child: Container(color: Colors.indigo),
              ),
              Expanded(
                flex: lightDuration?.inMinutes ?? 0,
                child: Container(color: Colors.blue),
              ),
              Expanded(
                flex: remDuration?.inMinutes ?? 0,
                child: Container(color: Colors.purple),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignConstants.spacingM),
        _DepthRow(
          label: l10n.sleepStageDeepLabel,
          duration: deepDuration,
          percent: percentage(deepDuration),
        ),
        _DepthRow(
          label: l10n.sleepStageLightLabel,
          duration: lightDuration,
          percent: percentage(lightDuration),
        ),
        _DepthRow(
          label: l10n.sleepStageRemLabel,
          duration: remDuration,
          percent: percentage(remDuration),
        ),
      ],
    );
  }
}

class _DepthRow extends StatelessWidget {
  const _DepthRow({
    required this.label,
    required this.duration,
    required this.percent,
  });

  final String label;
  final Duration? duration;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            duration == null
                ? '–'
                : '${formatDuration(duration!)}${percent == null ? '' : ' • ${percent!.toStringAsFixed(0)}%'}',
          ),
        ],
      ),
    );
  }
}
