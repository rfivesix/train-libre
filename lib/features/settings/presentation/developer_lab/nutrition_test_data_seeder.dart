// lib/features/settings/presentation/developer_lab/nutrition_test_data_seeder.dart

import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../../../data/database_helper.dart';
import '../../../../data/drift_database.dart' as db;
import 'canonical_scenarios.dart';
import 'nutrition_sandbox_state.dart';

class NutritionTestDataSeeder {
  static const String testFixtureBarcode = 'test_dev_lab_meal_item';
  static const String testGoalPrefix = '[DevLab] ';
  static const _uuid = Uuid();

  /// Injects a canonical scenario into the Drift database.
  static Future<void> seedScenario(
    CanonicalNutritionScenario scenario, {
    DatabaseHelper? dbHelper,
  }) async {
    final helper = dbHelper ?? DatabaseHelper.instance;
    final database = helper.dbInstance;

    // Apply to temporary state to derive all values accurately
    final sandbox = NutritionSandboxState();
    scenario.applyToSandbox(sandbox);
    final assessment = sandbox.evaluateAssessment();
    final now = DateTime.now();

    await database.transaction(() async {
      // 1. Clean previous test data
      await _cleanTestDataInternal(database);

      // 2. Mark any currently active real goals as superseded
      final activeGoals = await (database.select(database.userGoals)
            ..where((t) => t.status.equals('active')))
          .get();
      for (final g in activeGoals) {
        await (database.update(database.userGoals)
              ..where((t) => t.id.equals(g.id)))
            .write(db.UserGoalsCompanion(
          status: const drift.Value('superseded'),
          retiredAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ));
      }

      // 3. Create the test UserGoal
      final goalId = 'test-goal-${_uuid.v4()}';
      final startDate = sandbox.baselineDate;
      final targetDate = sandbox.targetDate;

      await database.into(database.userGoals).insert(
            db.UserGoalsCompanion.insert(
              id: drift.Value(goalId),
              preset: sandbox.preset.key,
              title: '$testGoalPrefix${scenario.title}',
              reason: const drift.Value('Injiziertes DevLab Testszenario'),
              status: const drift.Value('active'),
              startDate: startDate,
              targetDate: drift.Value(targetDate),
              targetMetric: const drift.Value('weight'),
              targetValue: drift.Value(sandbox.targetWeightKg),
              targetUnit: const drift.Value('kg'),
              desiredWeeklyRateKg: drift.Value(sandbox.desiredWeeklyRateKg),
              isNutritionDriver: const drift.Value(true),
              createdAt: drift.Value(startDate),
              updatedAt: drift.Value(now),
            ),
          );

      // 4. Ensure test product exists (lookup by barcode or ID to avoid UNIQUE constraint conflicts)
      final existingProduct = await (database.select(database.products)
            ..where((t) =>
                t.barcode.equals(testFixtureBarcode) |
                t.id.equals('test-product-dev-lab')))
          .getSingleOrNull();

      if (existingProduct != null) {
        await (database.update(database.products)
              ..where((t) => t.localId.equals(existingProduct.localId)))
            .write(db.ProductsCompanion(
          name: const drift.Value('DevLab Standardportion (100g = 100 kcal)'),
          calories: const drift.Value(100),
          protein: const drift.Value(8.0),
          carbs: const drift.Value(12.0),
          fat: const drift.Value(2.0),
          updatedAt: drift.Value(now),
        ));
      } else {
        await database.into(database.products).insert(
              db.ProductsCompanion.insert(
                id: const drift.Value('test-product-dev-lab'),
                barcode: testFixtureBarcode,
                name: 'DevLab Standardportion (100g = 100 kcal)',
                calories: 100,
                protein: 8.0,
                carbs: 12.0,
                fat: 2.0,
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
              ),
            );
      }

      // 5. Seed weight measurements
      final elapsedDays = sandbox.elapsedWeeks * 7;
      final startWeight = sandbox.baselineWeightKg;
      final endWeight = sandbox.currentWeightKg;
      final totalSlope = elapsedDays > 0 ? (endWeight - startWeight) / elapsedDays : 0.0;

      // Seed historical weight measurements leading up to today
      for (int day = elapsedDays; day >= 7; day -= 3) {
        final date = now.subtract(Duration(days: day));
        final weight = startWeight + (totalSlope * (elapsedDays - day));
        await database.into(database.measurements).insert(
              db.MeasurementsCompanion.insert(
                id: drift.Value('test-weight-${_uuid.v4()}'),
                type: 'weight',
                value: (weight * 10).roundToDouble() / 10.0,
                unit: 'kg',
                date: date,
                createdAt: drift.Value(date),
                updatedAt: drift.Value(date),
              ),
            );
      }

      // Seed current 7-day window weights according to weightObservationCount
      final obsCount = sandbox.weightObservationCount.clamp(0, 7);
      for (int i = 0; i < obsCount; i++) {
        final dayOffset = (6 - i);
        final date = now.subtract(Duration(days: dayOffset));
        final weight = endWeight - (sandbox.recentRateKgPerWeek / 7.0 * dayOffset);
        await database.into(database.measurements).insert(
              db.MeasurementsCompanion.insert(
                id: drift.Value('test-weight-${_uuid.v4()}'),
                type: 'weight',
                value: (weight * 10).roundToDouble() / 10.0,
                unit: 'kg',
                date: date,
                createdAt: drift.Value(date),
                updatedAt: drift.Value(date),
              ),
            );
      }

      // 6. Seed nutrition logs for the past 7 days according to nutritionLoggedDays
      final logDaysCount = sandbox.nutritionLoggedDays.clamp(0, 7);
      for (int i = 0; i < logDaysCount; i++) {
        final dayOffset = (6 - i);
        final date = now.subtract(Duration(days: dayOffset, hours: 2));
        final targetCalories = sandbox.averageLoggedCalories;
        // Amount in grams (product has 100 kcal per 100g, so amount = targetCalories)
        await database.into(database.nutritionLogs).insert(
              db.NutritionLogsCompanion.insert(
                id: drift.Value('test-log-${_uuid.v4()}'),
                productId: const drift.Value('test-product-dev-lab'),
                consumedAt: date,
                amount: targetCalories.toDouble(),
                mealType: const drift.Value('Lunch'),
                createdAt: drift.Value(date),
                updatedAt: drift.Value(date),
              ),
            );
      }

      // 7. Save user daily goals
      await helper.saveUserGoals(
        calories: sandbox.currentCalories,
        protein: 150,
        carbs: 220,
        fat: 65,
        water: 2500,
        steps: 8000,
      );

      // 8. Insert the GoalReviewRecord
      final canAdjust = assessment.nutritionAction == 'adjust_targets';
      final reviewId = 'test-review-$goalId';
      await database.into(database.goalReviews).insert(
            db.GoalReviewsCompanion.insert(
              id: drift.Value(reviewId),
              goalId: goalId,
              windowStart: now.subtract(const Duration(days: 7)),
              windowEnd: now,
              status: const drift.Value('pending'),
              trajectoryStatus: drift.Value(assessment.overallStatus),
              observedRateKgPerWeek: drift.Value(sandbox.recentRateKgPerWeek),
              confidenceLevel: drift.Value(
                  assessment.dataQuality == 'sufficient' ? 'high' : 'uncalibrated'),
              tdeeEstimate: drift.Value(sandbox.tdeeEstimate),
              recommendedCalories: canAdjust
                  ? drift.Value(sandbox.recommendedCalories)
                  : const drift.Value(null),
              recommendedProtein: canAdjust
                  ? drift.Value(sandbox.recommendedProtein)
                  : const drift.Value(null),
              recommendedCarbs: canAdjust
                  ? drift.Value(sandbox.recommendedCarbs)
                  : const drift.Value(null),
              recommendedFat: canAdjust
                  ? drift.Value(sandbox.recommendedFat)
                  : const drift.Value(null),
              algorithmVersion: 'weekly_goal_review_2_0',
              explanation: drift.Value(sandbox.buildExplanation(assessment)),
              assessmentJson: drift.Value(jsonEncode(assessment.toMap())),
              createdAt: drift.Value(now),
            ),
          );
    });
  }

  /// Removes all DevLab test data from the database.
  static Future<void> clearNutritionTestData({DatabaseHelper? dbHelper}) async {
    final helper = dbHelper ?? DatabaseHelper.instance;
    final database = helper.dbInstance;
    await database.transaction(() => _cleanTestDataInternal(database));
  }

  static Future<void> _cleanTestDataInternal(db.AppDatabase database) async {
    // 1. Delete test reviews
    await (database.delete(database.goalReviews)
          ..where((t) => t.id.like('test-review%')))
        .go();

    // 2. Delete test user goals & associated events
    final testGoals = await (database.select(database.userGoals)
          ..where((t) => t.title.like('$testGoalPrefix%') | t.id.like('test-goal%')))
        .get();
    for (final g in testGoals) {
      await (database.delete(database.goalEvents)
            ..where((t) => t.goalId.equals(g.id)))
          .go();
      await (database.delete(database.userGoals)
            ..where((t) => t.id.equals(g.id)))
          .go();
    }

    // 3. Delete test measurements
    await (database.delete(database.measurements)
          ..where((t) => t.id.like('test-weight%')))
        .go();

    // 4. Delete test nutrition logs
    await (database.delete(database.nutritionLogs)
          ..where((t) => t.productId.equals('test-product-dev-lab') | t.id.like('test-log%')))
        .go();

    // 5. Delete test product
    await (database.delete(database.products)
          ..where((t) =>
              t.barcode.equals(testFixtureBarcode) |
              t.id.equals('test-product-dev-lab')))
        .go();
  }
}
