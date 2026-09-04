import 'package:flutter/material.dart';
import '../../../../util/design_constants.dart';

import 'package:provider/provider.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../services/unit_service.dart';
import '../../domain/classification/exercise_log_mask.dart';
import '../../domain/models/routine_exercise.dart';
import '../../domain/models/set_log.dart';
import '../live_workout_view_model.dart';

/// A widget that calculates and displays the best Estimated 1-Rep Max (e1RM)
/// for the current session and compares it against the previous session.
class ExerciseE1rmSummary extends StatelessWidget {
  final RoutineExercise routineExercise;
  final LiveWorkoutViewModel manager;

  const ExerciseE1rmSummary({
    super.key,
    required this.routineExercise,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<LiveWorkoutViewModel, List<SetLog>>(
      selector: (context, vm) {
        final list = <SetLog>[];
        for (final template in routineExercise.setTemplates) {
          final log = vm.setLogs[template.id];
          if (log != null) {
            list.add(log);
          }
        }
        return list;
      },
      shouldRebuild: (prev, next) {
        if (prev.length != next.length) return true;
        for (int i = 0; i < prev.length; i++) {
          if (prev[i].isCompleted != next[i].isCompleted ||
              prev[i].weightKg != next[i].weightKg ||
              prev[i].reps != next[i].reps ||
              prev[i].setType != next[i].setType) {
            return true;
          }
        }
        return false;
      },
      builder: (context, sessionSetLogs, child) {
        final l10n = AppLocalizations.of(context)!;
        final unitService = context.read<UnitService>();

        double? sessionBest;
        for (final log in sessionSetLogs) {
          final value = _e1rm(log, requireCompleted: true);
          if (value == null) continue;
          if (sessionBest == null || value > sessionBest) {
            sessionBest = value;
          }
        }

        if (sessionBest == null) return const SizedBox.shrink();

        final lastSessionBest = _getLastSessionBestE1rm(
          routineExercise.exercise.canonicalName,
        );
        final hasDelta = lastSessionBest != null;
        final delta = hasDelta ? sessionBest - lastSessionBest : null;

        final theme = Theme.of(context);
        final isPositive = (delta ?? 0) >= 0;
        final deltaPrefix = isPositive ? '+' : '-';

        return Padding(
          padding: const EdgeInsets.only(
              left: DesignConstants.spacingL,
              right: DesignConstants.spacingL,
              bottom: DesignConstants.spacingS),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.liveWorkoutE1rmBestSession(
                    unitService.formatDisplayWeight(sessionBest),
                    unitService.suffixFor(UnitDimension.weight),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasDelta)
                Text(
                  l10n.liveWorkoutE1rmVsLastSession(
                    '$deltaPrefix${unitService.formatDisplayWeight(delta!.abs())}',
                    unitService.suffixFor(UnitDimension.weight),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPositive
                        ? Colors.green.shade700
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- e1RM Calculation Helpers ---

  /// The estimated 1RM of one set, or null when the set does not qualify.
  ///
  /// This line used to run the Brzycki formula on `setLog.weightKg` directly,
  /// which is the one thing the shared helper exists to prevent. On an
  /// assisted pull-up the logged number is a *reduction* of resistance, so the
  /// header read "best e1RM this session: 13.3 kg" while the badge on the very
  /// set it came from read 105.7 kg — the same set, two formulas, one of them
  /// reading assistance as load.
  double? _e1rm(SetLog setLog, {required bool requireCompleted}) {
    if (setLog.setType == 'warmup') return null;
    if (requireCompleted && setLog.isCompleted != true) return null;

    return ExerciseLogMask.forExercise(routineExercise.exercise)
        .estimatedOneRepMax(
      loggedWeightKg: setLog.weightKg,
      reps: setLog.reps,
      bodyweightKg: manager.bodyweightKg,
    );
  }

  double? _getLastSessionBestE1rm(String exerciseName) {
    final lastSets = manager.lastPerformances[exerciseName] ?? const <SetLog>[];
    double? best;

    for (final setLog in lastSets) {
      final value = _e1rm(setLog, requireCompleted: true);
      if (value == null) continue;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }
}
