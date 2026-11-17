import 'package:material_ui/material_ui.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/app_section_header.dart';
import '../../domain/scoring/sleep_scoring_engine.dart';
import 'sleep_score_card.dart';

class SleepScoreBreakdownCard extends StatelessWidget {
  const SleepScoreBreakdownCard({super.key, required this.scoringResult});

  final SleepScoringResult scoringResult;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rows = <(String, double?, int, Color)>[
      (
        l10n.sleepMetricDurationTitle,
        scoringResult.durationScore,
        45,
        SleepContributorColors.duration,
      ),
      (
        l10n.sleepMetricContinuityLabel,
        scoringResult.continuityScore,
        25,
        SleepContributorColors.continuity,
      ),
      (
        l10n.sleepStageDeepLabel,
        scoringResult.deepScore,
        10,
        SleepContributorColors.deep,
      ),
      (
        l10n.sleepStageRemLabel,
        scoringResult.remScore,
        10,
        SleepContributorColors.rem,
      ),
      (
        l10n.sleepMetricRegularityTitle,
        scoringResult.regularityScore,
        10,
        SleepContributorColors.regularity,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: l10n.sleepDashboardContributors,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: DesignConstants.spacingS),
        if (scoringResult.durationScoreCap != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignConstants.spacingXS),
            child: Text(
              '${l10n.sleepDashboardDurationCap}: ${scoringResult.durationScoreCap!.round()} / 100',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final (label, value, weight, color) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: DesignConstants.spacingXS,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingS),
                Expanded(
                  child: Text(
                    '$label · $weight%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  value == null
                      ? l10n.sleepMetricUnavailable
                      : '${value.round()} / 100',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
