import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/features/ai_assistant/data/assistant_diary_actions.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_sql_sandbox.dart';
import 'package:train_libre/features/ai_assistant/data/assistant_training_actions.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_action.dart';
import 'package:train_libre/features/ai_assistant/domain/assistant_data_request.dart';
import 'package:train_libre/features/diary/data/nutrition_repository.dart';
import 'package:train_libre/features/diary/data/sources/diary_local_data_source.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';
import 'package:train_libre/features/workout/data/workout_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'approved read actions use the same workout and diary repositories as screens',
      () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final day = DateTime(2026, 10, 18);
    final workout = await database.into(database.workoutLogs).insertReturning(
          db.WorkoutLogsCompanion.insert(
            startTime: DateTime(2026, 10, 18, 9),
            endTime: drift.Value(DateTime(2026, 10, 18, 10)),
            status: const drift.Value('completed'),
            routineNameSnapshot: const drift.Value('Leg day'),
          ),
        );
    await database.into(database.setLogs).insert(db.SetLogsCompanion.insert(
          workoutLogId: workout.id,
          exerciseNameSnapshot: const drift.Value('Squat'),
          reps: const drift.Value(5),
          weight: const drift.Value(100),
          isCompleted: const drift.Value(true),
        ));
    await database.into(database.products).insert(
          const db.ProductsCompanion(
            barcode: drift.Value('banana'),
            name: drift.Value('Banana'),
            calories: drift.Value(90),
            protein: drift.Value(1),
            carbs: drift.Value(22),
            fat: drift.Value(0),
            source: drift.Value('user'),
          ),
        );
    await database.into(database.nutritionLogs).insert(
          db.NutritionLogsCompanion.insert(
            legacyBarcode: const drift.Value('banana'),
            consumedAt: DateTime(2026, 10, 18, 12),
            amount: 100,
          ),
        );

    final gateway = AssistantDataGateway([
      AssistantTrainingActions(
        workouts: WorkoutRepository(
            localDataSource: WorkoutLocalDataSource(database)),
        database: database,
      ),
      AssistantDiaryActions(
          NutritionRepository(localDataSource: DiaryLocalDataSource(database))),
    ]);
    final request = AssistantDataRequest(
      categories: {
        AssistantDataCategory.workouts,
        AssistantDataCategory.diary,
        AssistantDataCategory.nutrition
      },
      scope: AssistantDateScope(day, day, 'explicit date'),
    );
    final denied = await gateway.readApproved(request, approved: false);
    expect(
        denied.every((result) => result.status == AssistantActionStatus.denied),
        isTrue);

    final approved = await gateway.readApproved(request, approved: true);
    expect(
        approved
            .every((result) => result.status == AssistantActionStatus.success),
        isTrue);
    final workoutData = approved
        .firstWhere((r) => r.category == AssistantDataCategory.workouts);
    expect(workoutData.records.single['routine'], 'Leg day');
    expect((workoutData.records.single['sets'] as List).single['exercise'],
        'Squat');
    final diaryData =
        approved.firstWhere((r) => r.category == AssistantDataCategory.diary);
    expect(
        diaryData.records.any((record) => record['name'] == 'Banana'), isTrue);
    final nutrition = approved
        .firstWhere((r) => r.category == AssistantDataCategory.nutrition);
    expect(nutrition.records.single['caloriesKcal'], 90);
    expect((nutrition.manifest['references'] as List), contains('foodEntry:1'));
  });

  test('recovery action records and manifest are JSON-encodable and load into sandbox', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final now = DateTime.now();
    final workout = await database.into(database.workoutLogs).insertReturning(
          db.WorkoutLogsCompanion.insert(
            startTime: now.subtract(const Duration(days: 2)),
            endTime: drift.Value(now.subtract(const Duration(days: 2, hours: -1))),
            status: const drift.Value('completed'),
            routineNameSnapshot: const drift.Value('Full body'),
          ),
        );
    await database.into(database.setLogs).insert(db.SetLogsCompanion.insert(
          workoutLogId: workout.id,
          exerciseNameSnapshot: const drift.Value('Bench press'),
          reps: const drift.Value(8),
          weight: const drift.Value(80),
          isCompleted: const drift.Value(true),
        ));

    final action = AssistantTrainingActions(
      workouts: WorkoutRepository(
          localDataSource: WorkoutLocalDataSource(database)),
      database: database,
    );

    final result = await action.read(AssistantDataCategory.recovery, null);
    expect(result.status, AssistantActionStatus.success);
    expect(result.records, isNotEmpty);

    // Manifest encoding must succeed without throwing "Instance of 'DateTime'"
    expect(result.manifest, isA<Map<String, dynamic>>());
    expect(result.manifest['payloadSha256'], isA<String>());

    // Sandbox creation must also succeed without throwing "Instance of 'DateTime'"
    final sandbox = await AssistantSqlSandbox.create([result]);
    addTearDown(sandbox.close);
    expect(sandbox.schema, contains('data_recovery'));
  });
}
