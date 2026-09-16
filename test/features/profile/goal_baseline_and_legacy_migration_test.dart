import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_repository.dart';
import 'package:train_libre/features/nutrition_recommendation/data/recommendation_service.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/profile/data/goal_repository_impl.dart';
import 'package:train_libre/features/profile/data/legacy_goal_migration.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('nutrition goal baseline integrity', () {
    late AppDatabase database;
    late GoalRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      repository = GoalRepositoryImpl(database: database);
    });

    tearDown(() => database.close());

    test('never invents a baseline when no measurement was supplied', () async {
      await expectLater(
        repository.createGoal(
          preset: GoalPreset.loseWeight,
          title: 'Loss',
          startDate: DateTime(2026, 1, 1),
        ),
        throwsArgumentError,
      );
      expect(await database.select(database.measurements).get(), isEmpty);
      expect(await database.select(database.userGoals).get(), isEmpty);
    });

    test('inline baseline and goal persist atomically as a snapshot', () async {
      final date = DateTime(2026, 1, 1);
      final goal = await repository.createGoal(
        preset: GoalPreset.loseWeight,
        title: 'Loss',
        startDate: date,
        baselineValueKg: 82.4,
        baselineDate: date,
        trackingMode: GoalTrackingMode.open,
      );

      final measurements = await database.select(database.measurements).get();
      expect(measurements, hasLength(1));
      expect(measurements.single.value, 82.4);
      expect(goal.baselineValueKg, 82.4);
      expect(goal.baselineDate, date);
      expect(goal.baselineMeasurementId, measurements.single.id);

      await (database.update(database.measurements)
            ..where((row) => row.id.equals(measurements.single.id)))
          .write(const MeasurementsCompanion(value: Value(75.0)));
      var reloaded = await repository.getGoalById(goal.id);
      expect(reloaded!.baselineValueKg, 82.4);
      expect(reloaded.baselineDate, date);

      await (database.delete(database.measurements)
            ..where((row) => row.id.equals(measurements.single.id)))
          .go();
      reloaded = await repository.getGoalById(goal.id);
      expect(reloaded!.baselineMeasurementId, equals(null));
      expect(reloaded.baselineValueKg, 82.4);
      expect(reloaded.baselineDate, date);
    });

    test('replacement is scoped to nutrition and leaves workout goals active',
        () async {
      final date = DateTime(2026, 1, 1);
      await database.into(database.userGoals).insert(
            UserGoalsCompanion.insert(
              id: const Value('workout-goal'),
              area: const Value('workout'),
              preset: 'custom',
              title: 'Stronger',
              startDate: date,
            ),
          );
      final first = await repository.createGoal(
        preset: GoalPreset.loseWeight,
        title: 'Loss',
        startDate: date,
        baselineValueKg: 82,
        baselineDate: date,
      );
      final second = await repository.createGoal(
        preset: GoalPreset.gainWeight,
        title: 'Gain',
        startDate: date.add(const Duration(days: 1)),
        baselineValueKg: 81,
        baselineDate: date.add(const Duration(days: 1)),
      );

      expect((await repository.getGoalById(first.id))!.status,
          GoalStatus.superseded);
      expect(
          (await repository.getGoalById(second.id))!.status, GoalStatus.active);
      final workout = await (database.select(database.userGoals)
            ..where((row) => row.id.equals('workout-goal')))
          .getSingle();
      expect(workout.status, 'active');
    });

    test('a migrated goal starts driving the engine only after capture',
        () async {
      final start = DateTime(2026, 1, 1);
      await database.into(database.userGoals).insert(
            UserGoalsCompanion.insert(
              id: const Value('missing-baseline'),
              preset: 'loseWeight',
              title: 'Legacy loss',
              startDate: start,
              desiredWeeklyRateKg: const Value(-0.5),
              isNutritionDriver: const Value(true),
            ),
          );
      final service = AdaptiveNutritionRecommendationService(
        databaseHelper: DatabaseHelper.forTesting(database),
        goalRepository: repository,
      );
      expect(
        await service.refreshRecommendationIfDue(now: DateTime(2026, 1, 12)),
        equals(null),
      );

      await database.into(database.measurements).insert(
            MeasurementsCompanion.insert(
              id: const Value('new-real-weight'),
              type: 'weight',
              value: 81,
              unit: 'kg',
              date: DateTime(2026, 1, 12),
            ),
          );
      final captured =
          await repository.captureMissingBaseline('missing-baseline');
      expect(captured.baselineMeasurementId, 'new-real-weight');
      expect(captured.baselineValueKg, 81);
      expect(captured.baselineDate, DateTime(2026, 1, 12));
    });
  });

  group('legacy nutrition goal migration', () {
    for (final entry in <(BodyweightGoal, double, GoalPreset)>[
      (BodyweightGoal.loseWeight, -0.4, GoalPreset.loseWeight),
      (BodyweightGoal.gainWeight, 0.3, GoalPreset.gainWeight),
      (BodyweightGoal.maintainWeight, 0.0, GoalPreset.maintainWeight),
    ]) {
      test('converts ${entry.$1.name} once with the real latest measurement',
          () async {
        SharedPreferences.setMockInitialValues({
          'adaptive_nutrition_recommendation.goal_direction': entry.$1.name,
          'adaptive_nutrition_recommendation.target_rate_kg_per_week': entry.$2,
        });
        final database = AppDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        final date = DateTime(2026, 1, 10);
        await database.into(database.measurements).insert(
              MeasurementsCompanion.insert(
                id: const Value('baseline'),
                type: 'weight',
                value: 80,
                unit: 'kg',
                date: date.subtract(const Duration(days: 1)),
              ),
            );
        final migration = LegacyGoalMigration(
          database: database,
          legacyRepository: RecommendationRepository(),
        );

        expect(await migration.run(now: date), isTrue);
        expect(await migration.run(now: date), isFalse);
        final rows = await database.select(database.userGoals).get();
        expect(rows, hasLength(1));
        expect(rows.single.preset, entry.$3.key);
        expect(rows.single.trackingMode, GoalTrackingMode.weeklyRate.name);
        expect(rows.single.desiredWeeklyRateKg, entry.$2);
        expect(rows.single.baselineMeasurementId, 'baseline');
        expect(rows.single.baselineValueKg, 80);
      });
    }

    test('defers conversion when no real weight measurement exists', () async {
      SharedPreferences.setMockInitialValues({
        'adaptive_nutrition_recommendation.goal_direction':
            BodyweightGoal.loseWeight.name,
        'adaptive_nutrition_recommendation.target_rate_kg_per_week': -0.5,
      });
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final migrated = await LegacyGoalMigration(database: database).run();
      expect(migrated, isFalse);
      expect(await database.select(database.userGoals).get(), isEmpty);
    });
  });
}
