import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/infrastructure/import_manager.dart';
import '../../../generated/app_localizations.dart';
import '../../../services/telemetry/telemetry_service.dart';
import '../../../util/design_constants.dart';
import '../../app/presentation/widgets/glass_bottom_menu.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/long_running_operation_overlay.dart';
import '../../exercise_catalog/presentation/exercise_mapping_screen.dart';
import '../../workout/data/sources/workout_local_data_source.dart';

Future<void> performWorkoutImport(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;

  // 1. Ask for unit
  final bool? isImperial = await showGlassBottomMenu<bool>(
    context: context,
    title: l10n.importUnitSelectionTitle,
    contentBuilder: (ctx, close) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.importUnitSelectionDescription),
        const SizedBox(height: DesignConstants.spacingM),
        Text(
          '${l10n.workoutImportHevyInstructions}\n${l10n.workoutImportStrongInstructions}',
          style: Theme.of(ctx).textTheme.bodySmall,
        ),
        const SizedBox(height: DesignConstants.spacingL),
        Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                onPressed: () => Navigator.of(ctx).pop(false),
                label: l10n.unitMetricLabel,
                tooltip: l10n.unitMetricLabel,
              ),
            ),
            const SizedBox(width: DesignConstants.spacingM),
            Expanded(
              child: AppButton.secondary(
                onPressed: () => Navigator.of(ctx).pop(true),
                label: l10n.unitImperialLabel,
                tooltip: l10n.unitImperialLabel,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (isImperial == null) return;

  int count = 0;
  bool wasCanceled = false;

  if (!context.mounted) return;
  try {
    final success = await LongRunningOperationOverlay.run(
      context: context,
      title: l10n.workoutImportButton,
      initialStatus: l10n.workoutImportButton,
      icon: LucideIcons.download,
      operation: (token, updateProgress) async {
        updateProgress(l10n.workoutImportButton, 0.2);
        count = await ImportManager().importWorkoutFile(
          isImperial: isImperial,
          defaultWorkoutTitle: l10n.importedWorkout,
          defaultExerciseName: l10n.unknownExercise,
          confirmImport: (workouts, duplicateCount) async {
            final setCount = workouts.fold<int>(
              0,
              (sum, workout) => sum + workout.sets.length,
            );
            final profile = workouts.first.sourceProfile;
            final instructions = switch (profile) {
              WorkoutImportProfile.hevy => l10n.workoutImportHevyInstructions,
              WorkoutImportProfile.strong =>
                l10n.workoutImportStrongInstructions,
              WorkoutImportProfile.generic =>
                l10n.workoutImportGenericInstructions,
            };
            return await showGlassBottomMenu<bool>(
                  context: context,
                  title: l10n.workoutImportTitle,
                  contentBuilder: (sheetContext, close) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(instructions),
                      const SizedBox(height: DesignConstants.spacingM),
                      Text(l10n.workoutImportPreviewSummary(
                        workouts.length,
                        setCount,
                        duplicateCount,
                      )),
                      if (workouts.first.skippedInvalidRows > 0) ...[
                        const SizedBox(height: DesignConstants.spacingS),
                        Text(l10n.workoutImportPreviewInvalidRows(
                          workouts.first.skippedInvalidRows,
                        )),
                      ],
                      const SizedBox(height: DesignConstants.spacingS),
                      for (final workout in workouts.take(5))
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: DesignConstants.spacingXS,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.title,
                                style:
                                    Theme.of(sheetContext).textTheme.titleSmall,
                              ),
                              Text(
                                '${MaterialLocalizations.of(sheetContext).formatMediumDate(workout.startTime)} · ${workout.sets.length}',
                                style:
                                    Theme.of(sheetContext).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: DesignConstants.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              label: l10n.cancel,
                              tooltip: l10n.cancel,
                            ),
                          ),
                          const SizedBox(width: DesignConstants.spacingM),
                          Expanded(
                            child: AppButton.primary(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(true),
                              label: l10n.workoutImportButton,
                              tooltip: l10n.workoutImportButton,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ) ??
                false;
          },
        );
        if (count > 0) {
          unawaited(TelemetryService.instance
              .trackFeatureUsed(featureKey: FeatureKey.workoutImported));
        }
        updateProgress(l10n.workoutImportButton, 1.0);
      },
    );
    if (!success) wasCanceled = true;
  } catch (e) {
    count = -1;
  }

  if (!context.mounted || wasCanceled) return;
  if (count == -2) return;
  if (count == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.workoutImportZeroNew)),
    );
    return;
  }
  if (count == -1) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.workoutImportFailed),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }

  final unknown =
      await WorkoutLocalDataSource.instance.findUnknownExerciseNames();

  if (context.mounted && unknown.isNotEmpty) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseMappingScreen(unknownNames: unknown),
      ),
    );
  }

  if (!context.mounted) return;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.workoutImportSuccess(count))));
}
