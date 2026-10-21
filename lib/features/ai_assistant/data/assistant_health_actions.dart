import '../../../data/drift_database.dart';
import '../../profile/domain/repositories/goal_repository.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../sleep/data/repository/sleep_query_repository.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

class AssistantHealthActions implements AssistantDataAction {
  AssistantHealthActions(
      {required this.database,
      required this.steps,
      required this.profile,
      required this.goals});
  final AppDatabase database;
  final StepsAggregationRepository steps;
  final IProfileRepository profile;
  final IGoalRepository goals;

  @override
  Set<AssistantDataCategory> get categories => const {
        AssistantDataCategory.steps,
        AssistantDataCategory.sleep,
        AssistantDataCategory.measurements,
        AssistantDataCategory.goals,
        AssistantDataCategory.profile,
        AssistantDataCategory.supplements,
      };

  @override
  Future<AssistantActionResult> read(
      AssistantDataCategory category, AssistantDateScope? scope) async {
    switch (category) {
      case AssistantDataCategory.steps:
        if (!await steps.isTrackingEnabled()) {
          return AssistantActionResult(
              category: category,
              status: AssistantActionStatus.error,
              error: 'Step tracking is disabled.');
        }
        final earliest = await steps.getEarliestAvailableDate();
        if (earliest == null || _dayDate(earliest).isAfter(scope!.end)) {
          return AssistantActionResult(
              category: category, status: AssistantActionStatus.success);
        }
        final days =
            DateTime.utc(scope.end.year, scope.end.month, scope.end.day)
                    .difference(DateTime.utc(
                        scope.start.year, scope.start.month, scope.start.day))
                    .inDays +
                1;
        final result =
            await steps.getRangeAggregation(endDate: scope.end, daysBack: days);
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final bucket in result.dailyTotals)
                if (!_dayDate(bucket.start).isBefore(_dayDate(earliest)))
                  {
                    'ref': 'steps:${_day(bucket.start)}',
                    'date': _day(bucket.start),
                    'steps': bucket.steps,
                  }
            ]);
      case AssistantDataCategory.sleep:
        final analyses = await DriftSleepQueryRepository(database: database)
            .getAnalysesInRange(
                fromInclusive: scope!.start, toInclusive: scope.end);
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final analysis in analyses)
                {
                  'ref': 'sleep:${analysis.id}',
                  'nightDate': _day(analysis.nightDate),
                  'totalSleepMinutes': analysis.totalSleepMinutes,
                  'score': analysis.score,
                  'sleepEfficiencyPct': analysis.sleepEfficiencyPct,
                  'restingHeartRateBpm': analysis.restingHeartRateBpm,
                  'interruptions': analysis.interruptionsCount,
                }
            ]);
      case AssistantDataCategory.measurements:
        final sessions = await profile.getMeasurementSessions();
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final session in sessions)
                if (!_dayDate(session.timestamp).isBefore(scope!.start) &&
                    !_dayDate(session.timestamp).isAfter(scope.end))
                  for (final measurement in session.measurements)
                    {
                      'ref': 'measurement:${measurement.id}',
                      'date': _day(session.timestamp),
                      'type': measurement.type,
                      'value': measurement.value,
                      'unit': measurement.unit,
                    },
            ]);
      case AssistantDataCategory.goals:
        final active = await goals.getActiveGoal();
        final retired = await goals.getRetiredGoals();
        final all = [if (active != null) active, ...retired];
        return AssistantActionResult(
            category: category,
            status: AssistantActionStatus.success,
            records: [
              for (final goal in all)
                {
                  'ref': 'goal:${goal.id}',
                  'title': goal.title,
                  'status': goal.status.name,
                  'startDate': _day(goal.startDate),
                  'targetDate':
                      goal.targetDate == null ? null : _day(goal.targetDate!),
                  'targetMetric': goal.targetMetric,
                  'targetValue': goal.targetValue,
                  'targetUnit': goal.targetUnit,
                }
            ]);
      case AssistantDataCategory.profile:
      case AssistantDataCategory.supplements:
        return AssistantActionResult(
          category: category,
          status: AssistantActionStatus.success,
        );
      default:
        throw ArgumentError.value(category);
    }
  }

  DateTime _dayDate(DateTime date) => DateTime(date.year, date.month, date.day);
  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
