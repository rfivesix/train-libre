import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../util/design_constants.dart';
import '../../../../widgets/common/card_morph_route.dart';
import '../../../../widgets/common/morph_source.dart';
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
        showSkeleton: !vm.hasDataForSelectedDate,
      ),
      builder: (context, data, child) {
        final showSkeleton = data.showSkeleton;
        final steps = showSkeleton ? 5000 : (data.stepsForSelectedDay ?? 0);

        // While loading but skeleton is not shown AND there's no prior value to
        // display yet, show the slim spinner card (same as before).
        if (data.isStepsWidgetLoading && !showSkeleton && steps <= 0) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
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

        // No steps at all — hide the card entirely.
        if (steps <= 0) {
          return const SizedBox.shrink();
        }

        // Keep GlassProgressBar permanently in the tree once we have a value so
        // its StatefulWidget state survives across loading transitions and the
        // TweenAnimationBuilder can smoothly animate from the old step count
        // to the new one instead of jumping or resetting to zero.
        final target = (data.targetSteps > 0
                ? data.targetSteps
                : StepsSyncService.defaultStepsGoal)
            .toDouble();

        return RepaintBoundary(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: DesignConstants.spacingXS),
            child: MorphSourceScope(
              builder: (context, setHidden) => Builder(
                builder: (sourceCtx) {
                  Widget buildBar() => GlassProgressBar(
                        label: l10n.steps,
                        unit: 'steps',
                        value: (data.stepsForSelectedDay ?? 0).toDouble(),
                        target: target,
                        color: theme.colorScheme.primary,
                        height: 54,
                        borderRadius: DesignConstants.borderRadiusL,
                      );

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        CardMorphRoute(
                          sourceContext: sourceCtx,
                          sourceBuilder: (_) => buildBar(),
                          sourceBorderRadius: DesignConstants.borderRadiusL,
                          onSourceVisibilityChanged: setHidden,
                          builder: (_) => StepsModuleScreen(
                            initialScope: StepsScope.day,
                            initialDate: data.selectedDate,
                          ),
                        ),
                      );
                    },
                    child: buildBar(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
