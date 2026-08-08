import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:intl/intl.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../sleep/data/sleep_hub_summary_repository.dart';
import '../statistics_hub_view_model.dart';
import 'analytics_card_base.dart';

class SleepSectionCard extends StatelessWidget {
  final SectionLoadState<SleepHubSummary> state;
  final String? rangeLabel;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const SleepSectionCard({
    super.key,
    required this.state,
    this.rangeLabel,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sectionId = StatisticsHubSectionId.sleep;
    final title = l10n.sleepHubScoreLabel;


    if (state.hasError && !state.hasData) {
      return AnalyticsCardBase.buildSectionErrorCard(
        context,
        l10n,
        onRetry,
        sectionId,
        title,
      );
    }

    final summary = state.data;
    final score = summary?.averageScore;
    final scoreText = score == null ? '--' : score.round().toString();
    final scoreValue =
        score == null ? 0.0 : (score.clamp(0.0, 100.0) / 100.0).toDouble();
    final durationText = _formatSleepDuration(l10n, summary?.averageDuration);
    final bedtimeText = _formatBedtime(summary?.averageBedtimeMinutes);
    final interruptionsCount = summary?.averageInterruptions?.round();
    final interruptionsValue =
        interruptionsCount == null ? '--' : interruptionsCount.toString();
    final interruptionsSubtitle =
        (interruptionsCount == null || summary?.averageWakeDuration == null)
            ? l10n.sleepHubAverageLabel
            : l10n.sleepHubInterruptionsSummary(
                interruptionsCount,
                _formatSleepDuration(l10n, summary!.averageWakeDuration),
              );

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
              Row(
                children: [
                  const Spacer(),
                  if (rangeLabel != null && rangeLabel!.isNotEmpty)
                    AnalyticsCardBase.buildRangeChip(context, rangeLabel!),
                  const SizedBox(width: DesignConstants.spacingS),
                  AnalyticsCardBase.buildDrillDownHint(context),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingM),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSleepScoreRing(
                    context,
                    scoreValue: scoreValue,
                    scoreText: scoreText,
                  ),
                  const SizedBox(width: DesignConstants.spacingL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepHubScoreLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: DesignConstants.spacingXS),
                        Text(
                          l10n.sleepMeanScoreLabel(scoreText),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingM),
              _buildTwoColumnGrid([
                ValueSummaryCard(
                  label: l10n.durationLabel,
                  value: durationText,
                  subtitle: l10n.sleepHubAverageLabel,
                  disableShadow: true,
                  useSecondarySurface: true,
                ),
                ValueSummaryCard(
                  label: l10n.sleepHubBedtimeLabel,
                  value: bedtimeText,
                  subtitle: l10n.sleepHubAverageLabel,
                  disableShadow: true,
                  useSecondarySurface: true,
                ),
                ValueSummaryCard(
                  label: l10n.sleepHubInterruptionsLabel,
                  value: interruptionsValue,
                  subtitle: interruptionsSubtitle,
                  disableShadow: true,
                  useSecondarySurface: true,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepScoreRing(
    BuildContext context, {
    required double scoreValue,
    required String scoreText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      width: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          SizedBox(
            height: 72,
            width: 72,
            child: CircularProgressIndicator(
              value: scoreValue,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              backgroundColor: Colors.transparent,
            ),
          ),
          Text(
            scoreText,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnGrid(List<Widget> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : const SizedBox();
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

  String _formatSleepDuration(AppLocalizations l10n, Duration? value) {
    if (value == null) return '--';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatBedtime(int? minutes) {
    if (minutes == null) return '--';
    final normalized = minutes % 1440;
    final dateTime = DateTime(2020, 1, 1, normalized ~/ 60, normalized % 60);
    return DateFormat.Hm().format(dateTime);
  }
}
