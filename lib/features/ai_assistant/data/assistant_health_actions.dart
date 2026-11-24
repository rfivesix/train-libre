import 'dart:async';

import '../../../data/drift_database.dart';
import '../../nutrition_recommendation/data/recommendation_repository.dart';
import '../../nutrition_recommendation/data/recommendation_scheduler.dart';
import '../../profile/domain/repositories/goal_repository.dart';
import '../../profile/domain/repositories/profile_repository.dart';
import '../../sleep/data/repository/sleep_query_repository.dart';
import '../../sleep/platform/sleep_sync_service.dart';
import '../../steps/data/steps_aggregation_repository.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

class AssistantHealthActions implements AssistantDataAction {
  AssistantHealthActions({
    required this.database,
    required this.steps,
    required this.profile,
    required this.goals,
    SleepSettingsService? sleepSync,
    RecommendationRepository? recommendations,
    this.syncTimeout = const Duration(seconds: 4),
  }) : _sleepSync = sleepSync ?? SleepSyncService(database: database),
       _recommendations = recommendations ?? RecommendationRepository();

  final AppDatabase database;
  final StepsAggregationRepository steps;
  final IProfileRepository profile;
  final IGoalRepository goals;
  final SleepSettingsService _sleepSync;
  final RecommendationRepository _recommendations;
  final Duration syncTimeout;

  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.steps,
    AssistantDataCategory.sleep,
    AssistantDataCategory.measurements,
    AssistantDataCategory.goals,
    AssistantDataCategory.profile,
    AssistantDataCategory.supplements,
    AssistantDataCategory.recipes,
    AssistantDataCategory.exerciseCatalog,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    switch (category) {
      case AssistantDataCategory.steps:
        return _readSteps(scope!);
      case AssistantDataCategory.sleep:
        return _readSleep(scope!);
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
          ],
        );
      case AssistantDataCategory.goals:
        return _readGoals();
      case AssistantDataCategory.profile:
      case AssistantDataCategory.supplements:
      case AssistantDataCategory.recipes:
      case AssistantDataCategory.exerciseCatalog:
        return AssistantActionResult(
          category: category,
          status: AssistantActionStatus.success,
        );
      default:
        throw ArgumentError.value(category);
    }
  }

  Future<AssistantActionResult> _readSteps(AssistantDateScope scope) async {
    final enabled = await steps.isTrackingEnabled();
    if (!enabled) {
      return const AssistantActionResult(
        category: AssistantDataCategory.steps,
        status: AssistantActionStatus.unavailable,
        sourceStatus: {
          'status': 'disabled',
          'tracking_enabled': 0,
          'permission_state': null,
          'last_synced_at': null,
          'detail': 'Step tracking is disabled in Health settings.',
        },
        error: 'Step tracking is disabled.',
      );
    }

    var syncTimedOut = false;
    try {
      await steps.refresh(force: false).timeout(syncTimeout);
    } on TimeoutException {
      syncTimedOut = true;
    } catch (_) {
      // Fall back to locally cached step segments.
    }

    final lastSync = await _safeLastStepsSync();
    final earliest = await steps.getEarliestAvailableDate();
    if (earliest == null || _dayDate(earliest).isAfter(scope.end)) {
      return AssistantActionResult(
        category: AssistantDataCategory.steps,
        status: AssistantActionStatus.success,
        sourceStatus: {
          'status': syncTimedOut ? 'cached_timeout' : 'available',
          'tracking_enabled': 1,
          'permission_state': 'granted',
          'last_synced_at': lastSync?.toIso8601String(),
          'detail': 'No step records found in the approved range.',
        },
      );
    }

    final days =
        DateTime.utc(scope.end.year, scope.end.month, scope.end.day)
            .difference(
              DateTime.utc(
                scope.start.year,
                scope.start.month,
                scope.start.day,
              ),
            )
            .inDays +
        1;
    final result = await steps.getRangeAggregation(
      endDate: scope.end,
      daysBack: days,
    );
    final defaultTarget = await steps.getCurrentTargetStepsOrDefault();
    final goalTimeline = await _loadStepTargetHistory();

    int targetForDay(DateTime day) {
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
      int? matched;
      for (final entry in goalTimeline) {
        if (!entry.createdAt.isAfter(endOfDay)) {
          matched = entry.targetSteps;
        } else {
          break;
        }
      }
      return matched ?? defaultTarget;
    }

    final dailySummary = <Map<String, dynamic>>[];
    final records = <Map<String, dynamic>>[];
    for (final bucket in result.dailyTotals) {
      if (_dayDate(bucket.start).isBefore(_dayDate(earliest))) continue;
      final date = _day(bucket.start);
      final target = targetForDay(bucket.start);
      dailySummary.add({
        'date': date,
        'steps': bucket.steps,
        'target_steps': target,
        'goal_met': bucket.steps >= target ? 1 : 0,
        'delta_to_target': bucket.steps - target,
      });
      records.add({
        'ref': 'steps:$date',
        'date': date,
        'steps': bucket.steps,
        'targetSteps': target,
      });
    }

    final hourlySummary = <Map<String, dynamic>>[];
    if (days <= 3) {
      for (
        var day = _dayDate(scope.start);
        !day.isAfter(_dayDate(scope.end));
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        if (day.isBefore(_dayDate(earliest))) continue;
        final dayAgg = await steps.getDayAggregation(day);
        final dateKey = _day(day);
        for (final bucket in dayAgg.hourlyBuckets) {
          if (bucket.steps <= 0) continue;
          hourlySummary.add({
            'date': dateKey,
            'hour': bucket.start.hour,
            'steps': bucket.steps,
          });
        }
      }
    }

    return AssistantActionResult(
      category: AssistantDataCategory.steps,
      status: AssistantActionStatus.success,
      records: records,
      tables: {
        if (dailySummary.isNotEmpty) 'steps_daily_summary': dailySummary,
        if (hourlySummary.isNotEmpty) 'steps_hourly_summary': hourlySummary,
      },
      tableColumns: {
        if (dailySummary.isNotEmpty)
          'steps_daily_summary': const {
            'date': 'TEXT',
            'steps': 'INTEGER',
            'target_steps': 'INTEGER',
            'goal_met': 'INTEGER',
            'delta_to_target': 'INTEGER',
          },
        if (hourlySummary.isNotEmpty)
          'steps_hourly_summary': const {
            'date': 'TEXT',
            'hour': 'INTEGER',
            'steps': 'INTEGER',
          },
      },
      sourceStatus: {
        'status': syncTimedOut ? 'cached_timeout' : 'available',
        'tracking_enabled': 1,
        'permission_state': 'granted',
        'last_synced_at': lastSync?.toIso8601String(),
        'detail': syncTimedOut
            ? 'Used cached step totals after platform sync timeout.'
            : 'Steps loaded.',
      },
    );
  }

  Future<AssistantActionResult> _readSleep(AssistantDateScope scope) async {
    var trackingEnabled = false;
    try {
      trackingEnabled = await _sleepSync.isTrackingEnabled();
    } catch (_) {
      trackingEnabled = false;
    }

    String? permissionState;
    String? syncMessage;
    var syncTimedOut = false;
    if (trackingEnabled) {
      try {
        final syncResult = await _sleepSync
            .importRecentIfDue(minInterval: const Duration(minutes: 30))
            .timeout(syncTimeout);
        if (syncResult != null) {
          permissionState = syncResult.permissionState.name;
          syncMessage = syncResult.message;
        }
      } on TimeoutException {
        syncTimedOut = true;
      } catch (_) {
        // Fall back to locally persisted sleep analyses.
      }
    }

    final analyses = await DriftSleepQueryRepository(database: database)
        .getAnalysesInRange(
          fromInclusive: scope.start,
          toInclusive: scope.end,
        );

    if (!trackingEnabled && analyses.isEmpty) {
      return const AssistantActionResult(
        category: AssistantDataCategory.sleep,
        status: AssistantActionStatus.unavailable,
        sourceStatus: {
          'status': 'disabled',
          'tracking_enabled': 0,
          'permission_state': null,
          'last_synced_at': null,
          'detail': 'Sleep tracking is disabled in Health settings.',
        },
        error: 'Sleep tracking is disabled.',
      );
    }

    if (analyses.isEmpty &&
        permissionState != null &&
        permissionState != 'ready') {
      return AssistantActionResult(
        category: AssistantDataCategory.sleep,
        status: AssistantActionStatus.unavailable,
        sourceStatus: {
          'status': permissionState,
          'tracking_enabled': trackingEnabled ? 1 : 0,
          'permission_state': permissionState,
          'last_synced_at':
              SleepSyncService.lastImportAtListenable.value?.toIso8601String(),
          'detail':
              syncMessage ??
              'Sleep read permission is unavailable ($permissionState).',
        },
        error: syncMessage ?? 'Sleep permission unavailable ($permissionState).',
      );
    }

    return AssistantActionResult(
      category: AssistantDataCategory.sleep,
      status: AssistantActionStatus.success,
      records: [
        for (final analysis in analyses)
          {
            'ref': 'sleep:${analysis.id}',
            'nightDate': _day(analysis.nightDate),
            'totalSleepMinutes': analysis.totalSleepMinutes,
            'score': analysis.score,
            'sleepEfficiencyPct': analysis.sleepEfficiencyPct,
            'averageSleepHeartRateBpm': analysis.restingHeartRateBpm,
            'interruptions': analysis.interruptionsCount,
          },
      ],
      sourceStatus: {
        'status': syncTimedOut
            ? 'cached_timeout'
            : (trackingEnabled ? 'available' : 'cached_disabled'),
        'tracking_enabled': trackingEnabled ? 1 : 0,
        'permission_state': permissionState ?? (trackingEnabled ? 'ready' : null),
        'last_synced_at':
            SleepSyncService.lastImportAtListenable.value?.toIso8601String(),
        'detail': syncTimedOut
            ? 'Used cached sleep analyses after platform sync timeout.'
            : (analyses.isEmpty
                  ? 'No sleep nights found in the approved range.'
                  : 'Sleep data loaded.'),
      },
    );
  }

  Future<AssistantActionResult> _readGoals() async {
    final active = await goals.getActiveGoal();
    final retired = await goals.getRetiredGoals();
    final all = [?active, ...retired];

    final adaptiveRows = <Map<String, dynamic>>[];
    try {
      final snapshot = await _recommendations.getLatestRecommendationSnapshot();
      final applied = await _recommendations.getLatestAppliedRecommendation();
      final dietPhase = await _recommendations.getDietPhaseTrackingState();
      final priorActivity = await _recommendations.getPriorActivityLevel();
      final extraCardio = await _recommendations.getExtraCardioHoursOption();
      final lastDueWeekKey = await _recommendations.getLastGeneratedDueWeekKey();
      final storedGoal = await _recommendations.getGoal();
      final storedRate = await _recommendations.getTargetRateKgPerWeek();
      final checkInWeekday = active?.startDate.weekday ?? DateTime.monday;
      final now = DateTime.now();
      final nextDueAt = RecommendationScheduler.nextDueAt(
        now: now,
        lastGeneratedDueWeekKey: lastDueWeekKey,
        checkInWeekday: checkInWeekday,
      );
      final isDueNow = RecommendationScheduler.isDueNow(
        now: now,
        lastGeneratedDueWeekKey: lastDueWeekKey,
        checkInWeekday: checkInWeekday,
      );

      final rec = snapshot?.recommendation;
      final est = snapshot?.maintenanceEstimate;
      if (snapshot != null || applied != null || active != null) {
        adaptiveRows.add({
          'goal_direction': (rec?.goal ?? storedGoal).name,
          'target_rate_kg_per_week': rec?.targetRateKgPerWeek ?? storedRate,
          'estimated_tdee_kcal':
              est?.posteriorMaintenanceCalories.round() ??
              rec?.estimatedMaintenanceCalories,
          'tdee_std_dev_kcal': est == null
              ? null
              : (est.posteriorStdDevCalories * 10).roundToDouble() / 10,
          'tdee_confidence': (est?.confidence ?? rec?.confidence)?.name,
          'prior_source': est?.priorSource.name,
          'observed_intake_kcal': est?.observedIntakeCalories?.round(),
          'observed_weight_slope_kg_per_week':
              est?.observedWeightSlopeKgPerWeek == null
              ? null
              : (est!.observedWeightSlopeKgPerWeek! * 100).roundToDouble() / 100,
          'effective_sample_size': est?.effectiveSampleSize,
          'recommended_calories': rec?.recommendedCalories,
          'recommended_protein_g': rec?.recommendedProteinGrams,
          'recommended_carbs_g': rec?.recommendedCarbsGrams,
          'recommended_fat_g': rec?.recommendedFatGrams,
          'applied_calories': applied?.recommendedCalories,
          'applied_protein_g': applied?.recommendedProteinGrams,
          'applied_carbs_g': applied?.recommendedCarbsGrams,
          'applied_fat_g': applied?.recommendedFatGrams,
          'prior_activity_level': priorActivity.name,
          'extra_cardio_hours_option': extraCardio.name,
          'diet_phase': dietPhase?.confirmedPhase.name,
          'diet_phase_start_day': dietPhase == null
              ? null
              : _day(dietPhase.confirmedPhaseStartDay),
          'pending_diet_phase': dietPhase?.pendingPhase?.name,
          'warning_state': rec?.warningState.warningLevel.name,
          'quality_flags': est?.qualityFlags.join(', '),
          'latest_generated_at': rec?.generatedAt.toIso8601String(),
          'next_check_in_at': nextDueAt.toIso8601String(),
          'is_check_in_due': isDueNow ? 1 : 0,
        });
      }
    } catch (_) {
      // SharedPreferences may be unavailable in minimal unit tests.
    }

    return AssistantActionResult(
      category: AssistantDataCategory.goals,
      status: AssistantActionStatus.success,
      records: [
        for (final goal in all)
          {
            'ref': 'goal:${goal.id}',
            'title': goal.title,
            'status': goal.status.name,
            'startDate': _day(goal.startDate),
            'targetDate': goal.targetDate == null
                ? null
                : _day(goal.targetDate!),
            'targetMetric': goal.targetMetric,
            'targetValue': goal.targetValue,
            'targetUnit': goal.targetUnit,
          },
      ],
      tables: {
        if (adaptiveRows.isNotEmpty) 'adaptive_nutrition_state': adaptiveRows,
      },
      tableColumns: {
        if (adaptiveRows.isNotEmpty)
          'adaptive_nutrition_state': const {
            'goal_direction': 'TEXT',
            'target_rate_kg_per_week': 'REAL',
            'estimated_tdee_kcal': 'INTEGER',
            'tdee_std_dev_kcal': 'REAL',
            'tdee_confidence': 'TEXT',
            'prior_source': 'TEXT',
            'observed_intake_kcal': 'INTEGER',
            'observed_weight_slope_kg_per_week': 'REAL',
            'effective_sample_size': 'REAL',
            'recommended_calories': 'INTEGER',
            'recommended_protein_g': 'INTEGER',
            'recommended_carbs_g': 'INTEGER',
            'recommended_fat_g': 'INTEGER',
            'applied_calories': 'INTEGER',
            'applied_protein_g': 'INTEGER',
            'applied_carbs_g': 'INTEGER',
            'applied_fat_g': 'INTEGER',
            'prior_activity_level': 'TEXT',
            'extra_cardio_hours_option': 'TEXT',
            'diet_phase': 'TEXT',
            'diet_phase_start_day': 'TEXT',
            'pending_diet_phase': 'TEXT',
            'warning_state': 'TEXT',
            'quality_flags': 'TEXT',
            'latest_generated_at': 'TEXT',
            'next_check_in_at': 'TEXT',
            'is_check_in_due': 'INTEGER',
          },
      },
    );
  }

  Future<DateTime?> _safeLastStepsSync() async {
    try {
      return await steps.getLastUpdatedAt();
    } catch (_) {
      return null;
    }
  }

  Future<List<({DateTime createdAt, int targetSteps})>>
  _loadStepTargetHistory() async {
    try {
      final rows = await database
          .customSelect(
            'SELECT created_at, target_steps FROM daily_goals_history WHERE deleted_at IS NULL ORDER BY created_at ASC, local_id ASC',
          )
          .get();
      return [
        for (final row in rows)
          (
            createdAt: _fromEpoch(row.read<int>('created_at')),
            targetSteps: row.read<int>('target_steps'),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  DateTime _fromEpoch(int raw) {
    final ms = raw.abs() < 100000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  }

  DateTime _dayDate(DateTime date) => DateTime(date.year, date.month, date.day);
  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
