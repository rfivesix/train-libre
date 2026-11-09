import 'package:flutter/material.dart';

import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import 'diary_health_summary_card.dart';
import '../../../pulse/domain/pulse_models.dart';
import '../../../pulse/presentation/pulse_analysis_screen.dart';
import '../../../sleep/presentation/widgets/sleep_period_scope_layout.dart';
import '../diary_view_model.dart';

import 'package:flutter_lucide/flutter_lucide.dart';

class PulseSummaryCard extends StatelessWidget {
  const PulseSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Selector<
        DiaryViewModel,
        ({
          bool isPulseWidgetLoading,
          PulseAnalysisSummary? pulseSummary,
          DateTime selectedDate,
          bool showSkeleton,
        })>(
      selector: (context, vm) => (
        isPulseWidgetLoading: vm.isPulseWidgetLoading,
        pulseSummary: vm.pulseSummary,
        selectedDate: vm.selectedDate,
        showSkeleton: !vm.hasDataForSelectedDate && !vm.isSelectedDateToday,
      ),
      builder: (context, data, child) {
        final showSkeleton = data.showSkeleton;
        if (data.isPulseWidgetLoading && !showSkeleton) {
          return DiaryHealthSummaryCard(
            title: l10n.pulseTitle,
            subtitle: l10n.load_dots,
          );
        }

        final summary = data.pulseSummary;
        if ((summary == null || !summary.hasData) && !showSkeleton) {
          return const SizedBox.shrink();
        }

        final rangeText = showSkeleton
            ? '60-120 ${l10n.sleepBpmUnit}'
            : (summary!.hasCoreMetrics
                ? '${summary.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}'
                : '--');
        final restingText = showSkeleton
            ? '65 ${l10n.sleepBpmUnit}'
            : (summary!.restingBpm != null
                ? '${summary.restingBpm!.round()} ${l10n.sleepBpmUnit}'
                : '--');

        return DiaryHealthSummaryCard(
          title: l10n.pulseTitle,
          subtitle: '${l10n.pulseRangeLabel}: $rangeText',
          destinationBuilder: (_) => PulseAnalysisScreen(
            initialDate: data.selectedDate,
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
                    l10n.pulseRestingLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restingText,
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
