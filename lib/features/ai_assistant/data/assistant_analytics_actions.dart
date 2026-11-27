import 'package:material_ui/material_ui.dart';

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart';
import '../../diary/data/sources/product_local_data_source.dart';
import '../../exercise_catalog/domain/exercise_metrics.dart';
import '../../statistics/data/body_nutrition_analytics_data_adapter.dart';
import '../../statistics/domain/body_nutrition_analytics_engine.dart';
import '../../statistics/domain/timeframe_block.dart';
import '../../workout/data/sources/workout_local_data_source.dart';
import '../domain/assistant_data_action.dart';
import '../domain/assistant_data_request.dart';

/// Exposes app-computed all-time and rolling analytics for the AI assistant:
/// training overview stats, all-time & period personal records, weekly
/// consistency/volume, muscle-group volume, and smoothed body-nutrition trends.
class AssistantAnalyticsActions implements AssistantDataAction {
  AssistantAnalyticsActions({required this.database, this.nowProvider});

  final AppDatabase database;
  final DateTime Function()? nowProvider;

  static const Map<String, Map<String, String>> tableColumnSchemas = {
    'training_overview_stats': {
      'total_workouts': 'INTEGER',
      'this_week_workouts': 'INTEGER',
      'avg_workouts_per_week_4w': 'REAL',
      'current_streak_weeks': 'INTEGER',
      'first_workout_date': 'TEXT',
      'last_workout_date': 'TEXT',
    },
    'personal_records': {
      'record_scope': 'TEXT',
      'metric': 'TEXT',
      'rep_bracket': 'TEXT',
      'exercise_name': 'TEXT',
      'weight_kg': 'REAL',
      'reps': 'INTEGER',
      'duration_seconds': 'INTEGER',
      'previous_value': 'REAL',
      'delta_value': 'REAL',
      'improvement_pct': 'REAL',
      'achieved_at': 'TEXT',
    },
    'weekly_training_consistency': {
      'week_start': 'TEXT',
      'workout_count': 'INTEGER',
      'total_sets': 'INTEGER',
      'total_tonnage_kg': 'REAL',
      'total_duration_minutes': 'INTEGER',
    },
    'muscle_group_volume_summary': {
      'muscle_group': 'TEXT',
      'total_sets': 'REAL',
      'weekly_avg_sets': 'REAL',
      'share_pct': 'REAL',
      'period_days': 'INTEGER',
    },
    'body_nutrition_trend': {
      'window_start': 'TEXT',
      'window_end': 'TEXT',
      'total_days': 'INTEGER',
      'smoothed_current_weight_kg': 'REAL',
      'weight_change_kg': 'REAL',
      'weight_slope_kg_per_week': 'REAL',
      'weight_trend_direction': 'TEXT',
      'avg_daily_calories_kcal': 'REAL',
      'calorie_trend_direction': 'TEXT',
      'relationship_type': 'TEXT',
      'confidence': 'TEXT',
      'insight_type': 'TEXT',
      'weight_days': 'INTEGER',
      'logged_calorie_days': 'INTEGER',
      'incomplete_days_excluded': 'INTEGER',
    },
  };

  @override
  Set<AssistantDataCategory> get categories => const {
    AssistantDataCategory.analytics,
  };

  @override
  Future<AssistantActionResult> read(
    AssistantDataCategory category,
    AssistantDateScope? scope,
  ) async {
    if (category != AssistantDataCategory.analytics) {
      throw ArgumentError.value(category);
    }

    final now = (nowProvider?.call() ?? DateTime.now()).toLocal();
    final workoutDataSource = WorkoutLocalDataSource(database);

    final periodDays = scope == null
        ? 30
        : (DateTime.utc(scope.end.year, scope.end.month, scope.end.day)
                      .difference(
                        DateTime.utc(
                          scope.start.year,
                          scope.start.month,
                          scope.start.day,
                        ),
                      )
                      .inDays +
                  1)
              .clamp(1, 366);
    final periodStart = scope?.start ?? now.subtract(const Duration(days: 29));
    final periodEnd = DateTime(
      (scope?.end ?? now).year,
      (scope?.end ?? now).month,
      (scope?.end ?? now).day,
      23,
      59,
      59,
      999,
    );

    final trainingStats = await workoutDataSource.getTrainingStats();
    final workoutBounds = await _workoutDateBounds();
    final overviewRows = <Map<String, dynamic>>[
      {
        'total_workouts': (trainingStats['totalWorkouts'] as num?)?.toInt() ?? 0,
        'this_week_workouts':
            (trainingStats['thisWeekCount'] as num?)?.toInt() ?? 0,
        'avg_workouts_per_week_4w': _round2(
          (trainingStats['avgPerWeek'] as num?)?.toDouble() ?? 0.0,
        ),
        'current_streak_weeks':
            (trainingStats['streakWeeks'] as num?)?.toInt() ?? 0,
        'first_workout_date': workoutBounds.firstDate,
        'last_workout_date': workoutBounds.lastDate,
      },
    ];

    final prRows = <Map<String, dynamic>>[];
    final globalPrs = await workoutDataSource.getAllTimeGlobalPRs(limit: 50);
    for (final pr in globalPrs) {
      prRows.add({
        'record_scope': 'all_time_exercise',
        'metric': 'maxWeight',
        'rep_bracket': null,
        'exercise_name': pr['exerciseName'],
        'weight_kg': _round2((pr['weight'] as num?)?.toDouble()),
        'reps': (pr['reps'] as num?)?.toInt(),
        'duration_seconds': null,
        'previous_value': null,
        'delta_value': null,
        'improvement_pct': null,
        'achieved_at': null,
      });
    }
    final bracketPrs = await workoutDataSource.getAllTimePRsByRepBracket();
    for (final entry in bracketPrs.entries) {
      final pr = entry.value;
      if (pr == null) continue;
      prRows.add({
        'record_scope': 'rep_bracket',
        'metric': 'maxWeight',
        'rep_bracket': entry.key,
        'exercise_name': pr['exerciseName'],
        'weight_kg': _round2((pr['weight'] as num?)?.toDouble()),
        'reps': (pr['reps'] as num?)?.toInt(),
        'duration_seconds': null,
        'previous_value': null,
        'delta_value': null,
        'improvement_pct': null,
        'achieved_at': null,
      });
    }
    try {
      final periodPrs = await workoutDataSource.getPeriodPersonalRecords(
        start: DateTime(periodStart.year, periodStart.month, periodStart.day),
        end: periodEnd,
      );
      for (final metricEntry in periodPrs.recordsByMetric.entries) {
        final metricName = metricEntry.key.name;
        for (final record in metricEntry.value.take(30)) {
          prRows.add({
            'record_scope': 'period_pr',
            'metric': metricName,
            'rep_bracket': null,
            'exercise_name': record.exerciseName,
            'weight_kg': _round2(
              record.weightKg ??
                  (metricEntry.key == ExerciseMetric.maxWeight
                      ? record.newValue
                      : null),
            ),
            'reps': record.reps,
            'duration_seconds': record.durationSeconds,
            'previous_value': _round2(record.previousValue),
            'delta_value': _round2(record.deltaValue),
            'improvement_pct': _round1(record.improvementPct),
            'achieved_at': _day(record.achievedAt.toLocal()),
          });
        }
      }
    } catch (_) {
      // Optional period PR enrichment.
    }

    final weeklyRows = <Map<String, dynamic>>[];
    try {
      final weeksBack = (periodDays / 7).ceil().clamp(6, 26);
      final consistency = await workoutDataSource.getWeeklyConsistencyMetrics(
        weeksBack: weeksBack,
      );
      final volumes = await workoutDataSource.getWeeklyVolumeData(
        weeksBack: weeksBack,
      );
      final setsByWeek = <String, int>{};
      for (final row in volumes) {
        final ws = row['weekStart'];
        if (ws is DateTime) {
          setsByWeek[_day(ws)] = (row['setCount'] as num?)?.toInt() ?? 0;
        }
      }
      for (final row in consistency) {
        final ws = row['weekStart'];
        final key = ws is DateTime ? _day(ws) : ws?.toString() ?? '';
        weeklyRows.add({
          'week_start': key,
          'workout_count': (row['workoutCount'] as num?)?.toInt() ?? 0,
          'total_sets': setsByWeek[key] ?? 0,
          'total_tonnage_kg': _round1(
            (row['tonnage'] as num?)?.toDouble() ?? 0.0,
          ),
          'total_duration_minutes':
              (row['totalDurationMinutes'] as num?)?.toInt() ?? 0,
        });
      }
    } catch (_) {}

    final muscleRows = <Map<String, dynamic>>[];
    try {
      final muscleAnalytics = await workoutDataSource.getMuscleGroupAnalytics(
        daysBack: periodDays,
        weeksBack: (periodDays / 7).ceil().clamp(4, 16),
      );
      final groups = muscleAnalytics['muscleGroups'];
      if (groups is List) {
        final weeksDivisor = (periodDays / 7.0).clamp(1.0, 52.0);
        for (final item in groups) {
          if (item is! Map) continue;
          final totalSets =
              (item['equivalentSets'] as num?)?.toDouble() ??
              (item['setCount'] as num?)?.toDouble() ??
              (item['sets'] as num?)?.toDouble() ??
              0.0;
          muscleRows.add({
            'muscle_group': item['muscleGroup'] ?? item['name'] ?? '',
            'total_sets': _round1(totalSets),
            'weekly_avg_sets': _round2(totalSets / weeksDivisor),
            'share_pct': _round1(
              (item['percentage'] as num?)?.toDouble() ??
                  (item['sharePct'] as num?)?.toDouble(),
            ),
            'period_days': periodDays,
          });
        }
      }
    } catch (_) {}

    final bodyTrendRows = <Map<String, dynamic>>[];
    try {
      final dbHelper = DatabaseHelper.forTesting(database);
      final adapter = BodyNutritionAnalyticsDataAdapter(
        databaseHelper: dbHelper,
        productDatabaseHelper: ProductLocalDataSource(database),
      );
      final blockType = periodDays <= 10
          ? TimeframeBlock.week
          : periodDays <= 45
          ? TimeframeBlock.month
          : periodDays <= 120
          ? TimeframeBlock.threeMonths
          : periodDays <= 200
          ? TimeframeBlock.sixMonths
          : TimeframeBlock.year;
      final raw = await adapter.fetch(
        selectedBlockType: blockType,
        anchorDate: scope?.end ?? now,
        isRolling: true,
      );
      final trend = BodyNutritionAnalyticsEngine.build(
        range: DateTimeRange(start: raw.range.start, end: raw.range.end),
        weightPoints: raw.weightPoints,
        caloriesByDay: raw.caloriesByDay,
        incompleteDays: raw.incompleteDays,
      );
      if (trend.hasAnyData) {
        bodyTrendRows.add({
          'window_start': _day(trend.range.start),
          'window_end': _day(trend.range.end),
          'total_days': trend.totalDays,
          'smoothed_current_weight_kg': _round2(trend.currentWeightKg),
          'weight_change_kg': _round2(trend.weightChangeKg),
          'weight_slope_kg_per_week': _round2(trend.weightTrend.slopePerWeek),
          'weight_trend_direction': trend.weightTrend.direction.name,
          'avg_daily_calories_kcal': _round1(trend.avgDailyCalories),
          'calorie_trend_direction': trend.calorieTrend.direction.name,
          'relationship_type': trend.relationship.name,
          'confidence': trend.confidence.name,
          'insight_type': trend.insightType.name,
          'weight_days': trend.weightDays,
          'logged_calorie_days': trend.loggedCalorieDays,
          'incomplete_days_excluded': trend.incompleteNutritionDays.length,
        });
      }
    } catch (_) {}

    final tables = <String, List<Map<String, dynamic>>>{
      'training_overview_stats': overviewRows,
      if (prRows.isNotEmpty) 'personal_records': prRows,
      if (weeklyRows.isNotEmpty) 'weekly_training_consistency': weeklyRows,
      if (muscleRows.isNotEmpty) 'muscle_group_volume_summary': muscleRows,
      if (bodyTrendRows.isNotEmpty) 'body_nutrition_trend': bodyTrendRows,
    };
    final tableColumns = <String, Map<String, String>>{
      for (final key in tables.keys)
        key: Map<String, String>.from(tableColumnSchemas[key]!),
    };

    return AssistantActionResult(
      category: category,
      status: AssistantActionStatus.success,
      records: [
        {'ref': 'analytics:overview', ...overviewRows.first},
        if (bodyTrendRows.isNotEmpty)
          {'ref': 'analytics:bodyNutritionTrend', ...bodyTrendRows.first},
      ],
      tables: tables,
      tableColumns: tableColumns,
    );
  }

  Future<({String? firstDate, String? lastDate})> _workoutDateBounds() async {
    try {
      final row = await database
          .customSelect(
            "SELECT MIN(start_time) AS first_ts, MAX(start_time) AS last_ts FROM workout_logs WHERE deleted_at IS NULL AND status = 'completed'",
          )
          .getSingleOrNull();
      final firstRaw = row?.readNullable<int>('first_ts');
      final lastRaw = row?.readNullable<int>('last_ts');
      return (
        firstDate: firstRaw == null ? null : _day(_fromEpoch(firstRaw)),
        lastDate: lastRaw == null ? null : _day(_fromEpoch(lastRaw)),
      );
    } catch (_) {
      return (firstDate: null, lastDate: null);
    }
  }

  DateTime _fromEpoch(int raw) {
    final ms = raw.abs() < 100000000000 ? raw * 1000 : raw;
    return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  }

  double? _round1(double? v) =>
      v == null || !v.isFinite ? null : (v * 10).roundToDouble() / 10;
  double? _round2(double? v) =>
      v == null || !v.isFinite ? null : (v * 100).roundToDouble() / 100;
  String _day(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
