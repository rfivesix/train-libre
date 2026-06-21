import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/glass_progress_bar.dart';
import '../../../../widgets/common/summary_card.dart';
import '../../../steps/presentation/steps_module_screen.dart';
import '../../../steps/domain/steps_models.dart';
import '../../../../services/health/steps_sync_service.dart';
import '../diary_view_model.dart';

class StepsSummaryCard extends StatelessWidget {
  const StepsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Selector<DiaryViewModel, ({
      bool isStepsWidgetLoading,
      int? stepsForSelectedDay,
      int targetSteps,
      DateTime selectedDate,
    })>(
      selector: (context, vm) => (
        isStepsWidgetLoading: vm.isStepsWidgetLoading,
        stepsForSelectedDay: vm.stepsForSelectedDay,
        targetSteps: vm.targetSteps,
        selectedDate: vm.selectedDate,
      ),
      builder: (context, data, child) {
        if (data.isStepsWidgetLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: SummaryCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: DesignConstants.spacingM),
                    Text(l10n.diarySyncingSteps),
                  ],
                ),
              ),
            ),
          );
        }

        if ((data.stepsForSelectedDay ?? 0) <= 0) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StepsModuleScreen(
                      initialScope: StepsScope.day,
                      initialDate: data.selectedDate,
                    ),
                  ),
                );
              },
              child: GlassProgressBar(
                label: l10n.steps,
                unit: 'steps',
                value: (data.stepsForSelectedDay ?? 0).toDouble(),
                target: (data.targetSteps > 0
                        ? data.targetSteps
                        : StepsSyncService.defaultStepsGoal)
                    .toDouble(),
                color: theme.colorScheme.primary,
                height: 54,
                borderRadius: DesignConstants.borderRadiusL,
              ),
            ),
          ),
        );
      },
    );
  }
}
