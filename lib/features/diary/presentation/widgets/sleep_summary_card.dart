import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../sleep/data/sleep_day_repository.dart';
import '../../../sleep/presentation/sleep_navigation.dart';
import '../diary_view_model.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SleepSummaryCard extends StatelessWidget {
  const SleepSummaryCard({super.key});

  String _formatSleepDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Selector<
        DiaryViewModel,
        ({
          bool isSleepWidgetLoading,
          SleepDayOverviewData? sleepOverview,
          DateTime selectedDate,
          bool showSkeleton,
        })>(
      selector: (context, vm) => (
        isSleepWidgetLoading: vm.isSleepWidgetLoading,
        sleepOverview: vm.sleepOverview,
        selectedDate: vm.selectedDate,
        showSkeleton: !vm.hasDataForSelectedDate,
      ),
      builder: (context, data, child) {
        final showSkeleton = data.showSkeleton;
        if (data.isSleepWidgetLoading && !showSkeleton) {
          return SummaryCard(
            padding: EdgeInsets.zero,
            margin:
                const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: ListTile(
              contentPadding: DesignConstants.screenPadding,
              title: Text(
                l10n.sleepSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                l10n.diaryLoadingSleep,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final overview = data.sleepOverview;
        if (overview == null && !showSkeleton) {
          return const SizedBox.shrink();
        }

        final durationText = showSkeleton ? '8h 0m' : _formatSleepDuration(overview!.totalSleepDuration);
        final score = showSkeleton ? 100.0 : overview!.analysis.score;
        final scoreText = score == null ? '--' : score.round().toString();

        return RepaintBoundary(
          child: SummaryCard(
            padding: EdgeInsets.zero,
            margin:
                const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: ListTile(
              onTap: () =>
                  SleepNavigation.openDayForDate(context, data.selectedDate),
              contentPadding: DesignConstants.screenPadding,
              title: Text(
                l10n.sleepSectionTitle,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${l10n.durationLabel}: $durationText',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.sleepHubScoreLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scoreText,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: DesignConstants.spacingS),
                  Icon(
                    LucideIcons.chevron_right,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
