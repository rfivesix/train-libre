import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../widgets/common/summary_card.dart';
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
        })>(
      selector: (context, vm) => (
        isPulseWidgetLoading: vm.isPulseWidgetLoading,
        pulseSummary: vm.pulseSummary,
        selectedDate: vm.selectedDate,
      ),
      builder: (context, data, child) {
        if (data.isPulseWidgetLoading) {
          return SummaryCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: ListTile(
              contentPadding: DesignConstants.screenPadding,
              title: Text(
                l10n.pulseTitle,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                l10n.load_dots,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final summary = data.pulseSummary;
        if (summary == null || !summary.hasData) {
          return const SizedBox.shrink();
        }

        final rangeText = summary.hasCoreMetrics
            ? '${summary.minBpm!.round()}-${summary.maxBpm!.round()} ${l10n.sleepBpmUnit}'
            : '--';
        final restingText = summary.restingBpm != null
            ? '${summary.restingBpm!.round()} ${l10n.sleepBpmUnit}'
            : '--';

        return RepaintBoundary(
          child: SummaryCard(
            padding: EdgeInsets.zero,
            margin: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: ListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PulseAnalysisScreen(
                      initialDate: data.selectedDate,
                      initialScope: SleepPeriodScope.day,
                    ),
                  ),
                );
              },
              contentPadding: DesignConstants.screenPadding,
              title: Text(
                l10n.pulseTitle,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${l10n.pulseRangeLabel}: $rangeText',
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
                        l10n.pulseRestingLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        restingText,
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
