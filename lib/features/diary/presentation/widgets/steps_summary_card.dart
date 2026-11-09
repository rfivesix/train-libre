import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../../../steps/domain/steps_models.dart';
import '../../../steps/presentation/steps_module_screen.dart';
import '../diary_view_model.dart';
import 'diary_health_summary_card.dart';

class StepsSummaryCard extends StatelessWidget {
  const StepsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Selector<
        DiaryViewModel,
        ({
          bool isStepsWidgetLoading,
          int? stepsForSelectedDay,
          int targetSteps,
          DateTime selectedDate,
          bool showSkeleton,
        })>(
      selector: (context, vm) => (
        isStepsWidgetLoading: vm.isStepsWidgetLoading,
        stepsForSelectedDay: vm.stepsForSelectedDay,
        targetSteps: vm.targetSteps,
        selectedDate: vm.selectedDate,
        showSkeleton: !vm.hasDataForSelectedDate && !vm.isSelectedDateToday,
      ),
      builder: (context, data, child) {
        if (data.isStepsWidgetLoading &&
            !data.showSkeleton &&
            data.stepsForSelectedDay == null) {
          return DiaryHealthSummaryCard(
            title: l10n.steps,
            subtitle: l10n.diarySyncingSteps,
          );
        }
        final steps = data.showSkeleton ? 5000 : data.stepsForSelectedDay;
        final target = data.targetSteps > 0
            ? data.targetSteps
            : StepsSyncService.defaultStepsGoal;
        final format = NumberFormat.decimalPattern(
          Localizations.localeOf(context).toString(),
        );
        return DiaryHealthSummaryCard(
          title: l10n.steps,
          subtitle: steps == null
              ? l10n.statisticsNoStepDataYet
              : '${format.format(steps)} / ${format.format(target)}',
          trailing: Icon(
            LucideIcons.chevron_right,
            color: theme.colorScheme.onSurface,
          ),
          destinationBuilder: (_) => StepsModuleScreen(
            initialScope: StepsScope.day,
            initialDate: data.selectedDate,
          ),
        );
      },
    );
  }
}
