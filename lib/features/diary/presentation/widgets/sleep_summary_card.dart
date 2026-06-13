import 'package:flutter/material.dart';
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
        })>(
      selector: (context, vm) => (
        isSleepWidgetLoading: vm.isSleepWidgetLoading,
        sleepOverview: vm.sleepOverview,
        selectedDate: vm.selectedDate,
      ),
      builder: (context, data, child) {
        if (data.isSleepWidgetLoading) {
          return SummaryCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
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
        if (overview == null) {
          return const SizedBox.shrink();
        }

        final durationText = _formatSleepDuration(overview.totalSleepDuration);
        final score = overview.analysis.score;
        final scoreText = score == null ? '--' : score.round().toString();

        return RepaintBoundary(
          child: SummaryCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              onTap: () =>
                  SleepNavigation.openDayForDate(context, data.selectedDate),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
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
                  const SizedBox(width: 8),
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
