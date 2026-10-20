import '../../../data/drift_database.dart';
import '../../workout/data/manual_training_plan_repository.dart';
import '../../workout/domain/models/manual_training_plan.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../../workout/domain/repositories/workout_repository.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

class AssistantTrainingActions implements AssistantDataAction {
  AssistantTrainingActions({
    required this.workouts,
    required this.database,
  });
  final IWorkoutRepository workouts;
  final AppDatabase database;

  @override
  Set<AssistantDataCategory> get categories => const {
        AssistantDataCategory.workouts,
        AssistantDataCategory.routines,
        AssistantDataCategory.trainingPlans,
        AssistantDataCategory.recovery,
      };

  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    switch (category) {
      case AssistantDataCategory.workouts:
        final logs =
            await workouts.getWorkoutLogsForDateRange(scope!.start, scope.end);
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final log in logs)
                {
                  'ref': 'workout:${log.id}',
                  'startedAt': log.startTime.toIso8601String(),
                  'endedAt': log.endTime?.toIso8601String(),
                  'routine': log.routineName,
                  'notes': log.notes,
                  'sets': [
                    for (final set in log.sets)
                      {
                        'ref': 'set:${set.id}',
                        'exercise': set.exerciseName,
                        'type': set.setType,
                        'reps': set.reps,
                        'weightKg': set.weightKg,
                        'durationSeconds': set.durationSeconds,
                      }
                  ],
                }
            ]);
      case AssistantDataCategory.routines:
        final routines = await workouts.watchAllRoutinesWithDetails().first;
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final routine in routines)
                {
                  'ref': 'routine:${routine.id}',
                  'name': routine.name,
                  'exerciseCount': routine.exercises.length,
                  'exercises': [
                    for (final exercise in routine.exercises)
                      exercise.exercise.canonicalName
                  ],
                }
            ]);
      case AssistantDataCategory.trainingPlans:
        final repository = ManualTrainingPlanRepository(database: database);
        final plans = await repository.allPlans();
        final planDetails = <String, ManualTrainingPlan?>{};
        for (final plan in plans) {
          planDetails[plan.id] = await repository.loadPlan(plan.id);
        }
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final plan in plans)
                {
                  'ref': 'trainingPlan:${plan.id}',
                  'name': plan.name,
                  'kind': plan.kind,
                  'active': plan.isActive,
                  'startedOn': plan.startedOn?.toIso8601String(),
                  'revisionRef': planDetails[plan.id]?.revisionId == null
                      ? null
                      : 'trainingPlanRevision:${planDetails[plan.id]!.revisionId}',
                  'revisionNumber': planDetails[plan.id]?.revisionNumber,
                  'templateDays': [
                    for (final day in planDetails[plan.id]?.days ??
                        const <TrainingPlanDay>[])
                      {
                        'rest': day.isRest,
                        'routine': day.routineName,
                        'routineRef': day.routineUuid == null
                            ? null
                            : 'routine:${day.routineUuid}',
                      },
                  ],
                }
            ]);
      case AssistantDataCategory.recovery:
        final today = DateTime.now();
        if (scope != null && !_sameDay(scope.end, today)) {
          return AssistantActionResult(
              category: category,
              status: AssistantActionStatus.error,
              error: 'Historical recovery snapshots are not available.');
        }
        final days = scope == null
            ? 14
            : DateTime.utc(scope.end.year, scope.end.month, scope.end.day)
                    .difference(DateTime.utc(
                        scope.start.year, scope.start.month, scope.start.day))
                    .inDays +
                1;
        final recovery = await WorkoutLocalDataSource(database)
            .getRecoveryAnalytics(lookbackDays: days);
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              {'ref': 'recovery:current', ...recovery}
            ]);
      default:
        throw ArgumentError.value(category);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
