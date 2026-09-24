import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WorkoutLocalDataSource dataSource;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = WorkoutLocalDataSource.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('createRoutine sets lastUsedAt to now and touches update order', () async {
    final r1 = await dataSource.createRoutine('Routine 1');
    expect(r1.id, isNotNull);

    await Future.delayed(const Duration(milliseconds: 50));
    final r2 = await dataSource.createRoutine('Routine 2');
    expect(r2.id, isNotNull);

    // Both should be returned by watchAllRoutinesWithDetails, r2 first because newer
    var list = await dataSource.watchAllRoutinesWithDetails().first;
    expect(list.length, 2);
    expect(list.first.name, 'Routine 2');
    expect(list.last.name, 'Routine 1');

    // Now touch r1 at a later time
    final t3 = DateTime.now().add(const Duration(hours: 1));
    await dataSource.touchRoutineLastUsed(r1.id!, t3);

    // r1 should now be at the top
    list = await dataSource.watchAllRoutinesWithDetails().first;
    expect(list.first.name, 'Routine 1');
    expect(list.last.name, 'Routine 2');
  });

  test('watchAllRoutinesWithDetails includes exercises in sequence order', () async {
    // Insert test exercise
    await db.into(db.exercises).insert(
      const ExercisesCompanion(
        id: Value('bench-uuid'),
        categoryName: Value('Strength'),
        trackingType: Value('weight_reps'),
        loadMode: Value('external'),
      ),
    );
    await db.into(db.exerciseTranslations).insert(
      const ExerciseTranslationsCompanion(
        exerciseId: Value('bench-uuid'),
        languageCode: Value('en'),
        name: Value('Bench Press'),
      ),
    );

    await db.into(db.exercises).insert(
      const ExercisesCompanion(
        id: Value('squat-uuid'),
        categoryName: Value('Strength'),
        trackingType: Value('weight_reps'),
        loadMode: Value('external'),
      ),
    );
    await db.into(db.exerciseTranslations).insert(
      const ExerciseTranslationsCompanion(
        exerciseId: Value('squat-uuid'),
        languageCode: Value('en'),
        name: Value('Barbell Squat'),
      ),
    );

    final benchRow = await (db.select(db.exercises)
          ..where((tbl) => tbl.id.equals('bench-uuid')))
        .getSingle();
    final squatRow = await (db.select(db.exercises)
          ..where((tbl) => tbl.id.equals('squat-uuid')))
        .getSingle();

    final r = await dataSource.createRoutine('Legs & Push');
    await dataSource.addExerciseToRoutine(r.id!, squatRow.localId);
    await dataSource.addExerciseToRoutine(r.id!, benchRow.localId);

    final list = await dataSource.watchAllRoutinesWithDetails().first;
    expect(list.length, 1);
    final routineWithDetails = list.first;
    expect(routineWithDetails.exercises.length, 2);
    expect(
      routineWithDetails.exercises[0].exercise.localizedNameFor('en'),
      'Barbell Squat',
    );
    expect(
      routineWithDetails.exercises[1].exercise.localizedNameFor('en'),
      'Bench Press',
    );
  });
}
