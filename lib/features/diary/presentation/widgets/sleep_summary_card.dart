import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import 'diary_health_summary_card.dart';
import '../../../sleep/data/sleep_day_repository.dart';
import '../../../sleep/presentation/sleep_navigation.dart';
import '../../../sleep/presentation/day/sleep_day_overview_page.dart';
import '../../../sleep/presentation/widgets/sleep_period_scope_layout.dart';
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
        showSkeleton: !vm.hasDataForSelectedDate && !vm.isSelectedDateToday,
      ),
      builder: (context, data, child) {
        final showSkeleton = data.showSkeleton;
        if (data.isSleepWidgetLoading && !showSkeleton) {
          return DiaryHealthSummaryCard(
            title: l10n.sleepSectionTitle,
            subtitle: l10n.diaryLoadingSleep,
          );
        }

        final overview = data.sleepOverview;
        if (overview == null && !showSkeleton) {
          return const SizedBox.shrink();
        }

        final durationText = showSkeleton
            ? '8h 0m'
            : _formatSleepDuration(overview!.totalSleepDuration);
        final score = showSkeleton ? 100.0 : overview!.analysis.score;
        final scoreText = score == null ? '--' : score.round().toString();

        return DiaryHealthSummaryCard(
          title: l10n.sleepSectionTitle,
          subtitle: '${l10n.durationLabel}: $durationText',
          routeSettings: RouteSettings(
            name: SleepRouteNames.day,
            arguments: data.selectedDate,
          ),
          destinationBuilder: (_) => SleepDayOverviewPage(
            selectedDay: data.selectedDate,
            initialScope: SleepPeriodScope.day,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.sleepHubScoreLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scoreText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
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
        );
      },
    );
  }
}
