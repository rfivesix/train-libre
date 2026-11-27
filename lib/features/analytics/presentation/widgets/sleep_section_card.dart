import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/empty_states/card_empty_state_overlay.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../../widgets/common/value_summary_card.dart';
import '../../../sleep/data/sleep_hub_summary_repository.dart';
import '../../../sleep/presentation/widgets/sleep_score_card.dart';
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
    final theme = Theme.of(context);
    final sectionId = StatisticsHubSectionId.sleep;
    final title = l10n.sleepSectionTitle;

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
    final isEmpty =
        !state.isLoading &&
        !state.hasError &&
        state.hasData &&
        !(summary?.hasData ?? false);
    final isInitialLoading = state.isLoading && !state.hasData;
    final displaySummary = (isEmpty || isInitialLoading)
        ? const SleepHubSummary(
            averageScore: 82,
            averageDuration: Duration(hours: 7, minutes: 38),
            averageBedtimeMinutes: 23 * 60 + 15,
            nightsCount: 7,
          )
        : summary;
    final score = displaySummary?.averageScore;
    final scoreText = score == null ? '--' : score.round().toString();
    final scoreValue = score == null
        ? 0.0
        : (score.clamp(0.0, 100.0) / 100.0).toDouble();
    final qualityLabel = score == null
        ? l10n.sleepQualityUnavailable
        : score >= 80
        ? l10n.sleepQualityGood
        : score >= 60
        ? l10n.sleepQualityAverage
        : l10n.sleepQualityPoor;
    final durationText = _formatSleepDuration(displaySummary?.averageDuration);
    final bedtimeText = _formatBedtime(displaySummary?.averageBedtimeMinutes);

    Widget bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    qualityLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: DesignConstants.spacingXS),
                  Text(
                    displaySummary != null && displaySummary.nightsCount > 0
                        ? l10n.sleepHubNightsLogged(displaySummary.nightsCount)
                        : l10n.sleepMeanScoreLabel(scoreText),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingM),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.sleepDashboardAsleep,
                  value: durationText,
                  subtitle: l10n.sleepHubAverageLabel,
                  disableShadow: true,
                  useSecondarySurface: true,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingS),
              Expanded(
                child: ValueSummaryCard(
                  label: l10n.sleepHubBedtimeLabel,
                  value: bedtimeText,
                  subtitle: l10n.sleepHubAverageLabel,
                  disableShadow: true,
                  useSecondarySurface: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isEmpty) {
      bodyContent = CardEmptyStateOverlay(
        isEmpty: true,
        message: l10n.statisticsEmptySleep,
        borderRadius: BorderRadius.circular(DesignConstants.borderRadiusM),
        child: bodyContent,
      );
    } else if (isInitialLoading) {
      bodyContent = Skeletonizer(
        enabled: true,
        child: IgnorePointer(child: bodyContent),
      );
    }

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
                chipText: (rangeLabel != null && rangeLabel!.isNotEmpty)
                    ? rangeLabel
                    : null,
              ),
              const SizedBox(height: DesignConstants.spacingM),
              bodyContent,
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
    final segments = <SleepScoreRingSegment>[
      SleepScoreRingSegment(
        weight: 0.45,
        fillRatio: scoreValue,
        color: SleepContributorColors.duration,
      ),
      SleepScoreRingSegment(
        weight: 0.25,
        fillRatio: scoreValue,
        color: SleepContributorColors.continuity,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio: scoreValue,
        color: SleepContributorColors.deep,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio: scoreValue,
        color: SleepContributorColors.rem,
      ),
      SleepScoreRingSegment(
        weight: 0.10,
        fillRatio: scoreValue,
        color: SleepContributorColors.regularity,
      ),
    ];

    return SizedBox(
      height: 76,
      width: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CustomPaint(
              painter: SleepScoreRingPainter(
                segments: segments,
                maxStrokeWidth: 12.0,
                cornerRadius: 3.5,
                gapPixels: 2.5,
              ),
            ),
          ),
          Text(
            scoreText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSleepDuration(Duration? value) {
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
