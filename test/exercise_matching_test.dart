import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart' as db;
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late WorkoutLocalDataSource helper;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    helper = WorkoutLocalDataSource.forTesting(database);

    // Seed test exercises
    await database.into(database.exercises).insert(db.ExercisesCompanion(
          id: const drift.Value('ex-1'),
          source: const drift.Value('wger'),
        ));
    await database.into(database.exerciseTranslations).insert(db.ExerciseTranslationsCompanion(
          exerciseId: const drift.Value('ex-1'),
          languageCode: const drift.Value('de'),
          name: const drift.Value('Rumänisches Kreuzheben'),
        ));

    await database.into(database.exercises).insert(db.ExercisesCompanion(
          id: const drift.Value('ex-2'),
          source: const drift.Value('wger'),
        ));
    await database.into(database.exerciseTranslations).insert(db.ExerciseTranslationsCompanion(
          exerciseId: const drift.Value('ex-2'),
          languageCode: const drift.Value('de'),
          name: const drift.Value('Brustpresse'),
        ));

    await database.into(database.exercises).insert(db.ExercisesCompanion(
          id: const drift.Value('ex-3'),
          source: const drift.Value('wger'),
        ));
    await database.into(database.exerciseTranslations).insert(db.ExerciseTranslationsCompanion(
          exerciseId: const drift.Value('ex-3'),
          languageCode: const drift.Value('de'),
          name: const drift.Value('Beinstrecker'),
        ));

    await database.into(database.exercises).insert(db.ExercisesCompanion(
          id: const drift.Value('ex-4'),
          source: const drift.Value('wger'),
        ));
    await database.into(database.exerciseTranslations).insert(db.ExerciseTranslationsCompanion(
          exerciseId: const drift.Value('ex-4'),
          languageCode: const drift.Value('de'),
          name: const drift.Value('Wadenheben Stehend'),
        ));
  });

  tearDown(() async {
    await database.close();
  });

  group('Exercise Matching & Multi-pass Search Tests', () {
    test('getExerciseByName strips parenthetical equipment tags', () async {
      final match1 = await helper.getExerciseByName('Rumänisches Kreuzheben (Langhantel)');
      expect(match1, isNotNull);
      expect(match1!.uuid, 'ex-1');

      final match2 = await helper.getExerciseByName('Brustpresse (Maschine)');
      expect(match2, isNotNull);
      expect(match2!.uuid, 'ex-2');
    });

    test('searchExercises matches synonyms and stripped equipment tags', () async {
      final results1 = await helper.searchExercises(query: 'Beinstrecken (Maschine)');
      expect(results1, isNotEmpty);
      expect(results1.first.uuid, 'ex-3');

      final results2 = await helper.searchExercises(query: 'Wadendrücken (Maschine)');
      expect(results2, isNotEmpty);
      expect(results2.first.uuid, 'ex-4');
    });
    test('getExactExerciseByName requires exact match and rejects parenthetical variants', () async {
      final exactMatch = await helper.getExactExerciseByName('Rumänisches Kreuzheben');
      expect(exactMatch, isNotNull);
      expect(exactMatch!.uuid, 'ex-1');

      final variantMatch = await helper.getExactExerciseByName('Rumänisches Kreuzheben (Langhantel)');
      expect(variantMatch, isNull);
    });
  });
}
