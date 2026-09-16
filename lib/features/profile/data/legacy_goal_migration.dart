import 'package:drift/drift.dart' as drift;

import '../../../data/database_helper.dart';
import '../../../data/drift_database.dart' as db;
import '../../nutrition_recommendation/data/recommendation_repository.dart';
import '../../nutrition_recommendation/domain/goal_models.dart';
import '../domain/models/goal_model.dart';
import 'goal_repository_impl.dart';

/// One-way, idempotent bridge from the former preference-backed weight goal.
///
/// A legacy goal is deliberately left untouched until a real weight
/// measurement exists. This avoids inventing a baseline and lets the migration
/// retry safely on the next launch or immediately after a backup restore.
class LegacyGoalMigration {
  final db.AppDatabase _database;
  final RecommendationRepository _legacyRepository;
  final GoalRepositoryImpl _goalRepository;

  LegacyGoalMigration({
    db.AppDatabase? database,
    RecommendationRepository? legacyRepository,
    GoalRepositoryImpl? goalRepository,
  })  : _database = database ?? DatabaseHelper.instance.dbInstance,
        _legacyRepository = legacyRepository ?? RecommendationRepository(),
        _goalRepository = goalRepository ??
            GoalRepositoryImpl(
              database: database ?? DatabaseHelper.instance.dbInstance,
            );

  Future<bool> run({DateTime? now}) async {
    final existing = await (_database.select(_database.userGoals)..limit(1))
        .getSingleOrNull();
    if (existing != null) return false;

    final activation = now ?? DateTime.now();
    final measurementQuery = _database.select(_database.measurements)
      ..where((row) =>
          row.type.equals('weight') &
          row.date.isSmallerOrEqualValue(activation))
      ..orderBy([(row) => drift.OrderingTerm.desc(row.date)])
      ..limit(1);
    final baseline = await measurementQuery.getSingleOrNull();
    if (baseline == null || baseline.value <= 0) return false;

    final legacyGoal = await _legacyRepository.getGoal();
    final rate = await _legacyRepository.getTargetRateKgPerWeek();
    final preset = switch (legacyGoal) {
      BodyweightGoal.loseWeight => GoalPreset.loseWeight,
      BodyweightGoal.gainWeight => GoalPreset.gainWeight,
      BodyweightGoal.maintainWeight => GoalPreset.maintainWeight,
    };
    final title = switch (preset) {
      GoalPreset.loseWeight => 'Lose weight',
      GoalPreset.gainWeight => 'Gain weight',
      _ => 'Maintain weight',
    };

    await _goalRepository.createGoal(
      preset: preset,
      title: title,
      startDate: activation,
      trackingMode: GoalTrackingMode.weeklyRate,
      baselineMeasurementId: baseline.id,
      baselineValueKg: baseline.value,
      baselineDate: baseline.date,
      targetMetric: 'weight',
      targetUnit: 'kg',
      desiredWeeklyRateKg: rate,
      isNutritionDriver: true,
    );
    return true;
  }
}
