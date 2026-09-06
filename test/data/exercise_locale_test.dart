@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart' hide Exercise;
import 'package:train_libre/features/exercise_catalog/domain/exercise_locale_chain.dart';
import 'package:train_libre/features/exercise_catalog/domain/models/exercise.dart';
import 'package:train_libre/features/workout/data/sources/workout_local_data_source.dart';

/// Reading the catalog in any of its languages.
///
/// What replaced `nameDe`/`nameEn`: a map keyed by language code, a fallback
/// chain, and a separate notion of a name to *key* by. Conflating those two
/// was the bug waiting to happen — a live session keeps notes in a map keyed
/// by exercise name, and if that key follows the UI language, switching the
/// app to English mid-workout loses them.
const String kFixturePath = 'test/fixtures/exercise_catalog/v2_min.db';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('the model', () {
    const multilingual = Exercise(
      uuid: 'x',
      texts: {
        'de': ExerciseText(name: 'Kniebeuge', description: 'Beine'),
        'en': ExerciseText(name: 'Squat', description: 'Legs'),
        'ja': ExerciseText(name: 'スクワット'),
      },
      categoryName: 'Legs',
      primaryMuscles: [],
      secondaryMuscles: [],
    );

    test('serves the requested language', () {
      expect(multilingual.localizedNameFor('de'), 'Kniebeuge');
      expect(multilingual.localizedNameFor('en'), 'Squat');
      expect(multilingual.localizedNameFor('ja'), 'スクワット');
    });

    test('falls back to English, then German', () {
      expect(multilingual.localizedNameFor('fr'), 'Squat');

      const germanOnly = Exercise(
        texts: {'de': ExerciseText(name: 'Klimmzug')},
        categoryName: 'Back',
        primaryMuscles: [],
        secondaryMuscles: [],
      );
      expect(germanOnly.localizedNameFor('fr'), 'Klimmzug');
    });

    test('shows a name in a language nobody asked for rather than nothing', () {
      // A user's own exercise, typed in Polish. An empty title would be worse.
      const polishOnly = Exercise(
        texts: {'pl': ExerciseText(name: 'Przysiad')},
        categoryName: 'Legs',
        primaryMuscles: [],
        secondaryMuscles: [],
      );
      expect(polishOnly.localizedNameFor('de'), 'Przysiad');
    });

    test('an exercise with no text at all resolves to empty, not a crash', () {
      const nothing = Exercise(
        texts: {},
        categoryName: 'Other',
        primaryMuscles: [],
        secondaryMuscles: [],
      );
      expect(nothing.localizedNameFor('de'), '');
      expect(nothing.canonicalName, '');
      expect(nothing.allNames, isEmpty);
    });

    test('descriptions fall back independently of names', () {
      const namedButUndescribed = Exercise(
        texts: {
          'de': ExerciseText(name: 'Kniebeuge'),
          'en': ExerciseText(name: 'Squat', description: 'Legs'),
        },
        categoryName: 'Legs',
        primaryMuscles: [],
        secondaryMuscles: [],
      );
      expect(namedButUndescribed.localizedNameFor('de'), 'Kniebeuge');
      expect(namedButUndescribed.localizedDescriptionFor('de'), 'Legs');
    });

    test('canonicalName does not move with the UI language', () {
      // The whole reason it exists.
      expect(multilingual.canonicalName, 'Squat');
      expect(multilingual.localizedNameFor('de'), 'Kniebeuge');
      expect(multilingual.canonicalName, 'Squat');
    });

    test('allNames covers every language, for matching', () {
      expect(multilingual.allNames,
          containsAll(<String>['Kniebeuge', 'Squat', 'スクワット']));
    });

    test('withText replaces one language and leaves the others', () {
      final edited = multilingual.withText(
        'de',
        const ExerciseText(name: 'Tiefe Kniebeuge'),
      );
      expect(edited.localizedNameFor('de'), 'Tiefe Kniebeuge');
      expect(edited.localizedNameFor('en'), 'Squat');
    });

    test('a map round-trips through toMap/fromMap', () {
      final restored = Exercise.fromMap(multilingual.toMap());
      expect(restored.localizedNameFor('ja'), 'スクワット');
      expect(restored.localizedDescriptionFor('de'), 'Beine');
    });

    test('the old flat backup shape still loads', () {
      // Backups written before this change carry name_de/name_en.
      final legacy = Exercise.fromMap(const {
        'name_de': 'Bankdrücken',
        'name_en': 'Bench Press',
        'description_de': 'Brust',
        'category_name': 'Chest',
      });
      expect(legacy.localizedNameFor('de'), 'Bankdrücken');
      expect(legacy.canonicalName, 'Bench Press');
      expect(legacy.localizedDescriptionFor('de'), 'Brust');
    });
  });

  group('against the catalog', () {
    late AppDatabase db;
    late WorkoutLocalDataSource source;

    setUpAll(() async {
      sqflite.databaseFactory = databaseFactoryFfi;
      db = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(db);
      BasisDataManager.instance.invalidateCatalogPresenceCache();
      ExerciseLocaleChain.invalidate();
      await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
        File(kFixturePath).absolute.path,
      );
      ExerciseLocaleChain.invalidate();
      source = WorkoutLocalDataSource.forTesting(db);
    });

    tearDownAll(() async {
      await db.close();
      ExerciseLocaleChain.invalidate();
    });

    test('search names results in the requested language', () async {
      final de = await source.searchExercises(query: '', languageCode: 'de');
      final en = await source.searchExercises(query: '', languageCode: 'en');

      final deNames = {
        for (final e in de) e.uuid: e.localizedNameFor('de'),
      };
      final enNames = {
        for (final e in en) e.uuid: e.localizedNameFor('en'),
      };

      // At least some names must actually differ, or this proves nothing.
      final differing = deNames.entries
          .where((entry) => enNames[entry.key] != entry.value)
          .length;
      expect(differing, greaterThan(0),
          reason: 'German and English results were identical');
    });

    test('a language the catalog marks undisplayable is skipped', () async {
      // The registry decides, not the app. Italian and Japanese ship with
      // displayable = 0 in the current build.
      final registry = await db.select(db.catalogLanguages).get();
      final undisplayable = registry
          .where((row) => !row.displayable && row.code != 'en')
          .map((row) => row.code)
          .toList();
      expect(undisplayable, isNotEmpty,
          reason: 'the fixture must carry at least one');

      final chain = await ExerciseLocaleChain.resolve(db, undisplayable.first);
      expect(chain, isNot(contains(undisplayable.first)));
      expect(chain.first, 'en');
    });

    test('a displayable language stays first in the chain', () async {
      expect(await ExerciseLocaleChain.resolve(db, 'de'), ['de', 'en']);
      expect((await ExerciseLocaleChain.resolve(db, 'en')).first, 'en');
    });

    test('a language the registry never heard of is allowed through', () async {
      // Covers a v1 catalog with no registry, and a language the user typed
      // their own exercises in.
      final chain = await ExerciseLocaleChain.resolve(db, 'xx');
      expect(chain.first, 'xx');
    });

    test('search finds an exercise by its name in another language', () async {
      // Exercise 20 is "Arnold Press" in German and "Développé Arnold avec
      // haltères" in French. Before this, search only ever looked at the de
      // and en columns, so a French name found nothing.
      final byFrench = await source.searchExercises(
        query: 'Développé Arnold',
        languageCode: 'de',
      );
      expect(byFrench.map((e) => e.uuid), contains('20'));

      // And the reverse: an English name while the UI is German.
      final byEnglish = await source.searchExercises(
        query: 'Arnold Shoulder',
        languageCode: 'de',
      );
      expect(byEnglish.map((e) => e.uuid), contains('20'));
      // …still rendered in German.
      expect(
        byEnglish.firstWhere((e) => e.uuid == '20').localizedNameFor('de'),
        'Arnold Press',
      );
    });

    test('a resolved exercise carries all its languages', () async {
      final exercise = await source.getExerciseByUuid('20');
      expect(exercise, isNotNull);
      expect(exercise!.texts.length, greaterThan(2),
          reason: 'the detail path loads every translation, not just two');
    });

    test('a search result carries the one language it was rendered in',
        () async {
      final results =
          await source.searchExercises(query: '', languageCode: 'de');
      expect(results, isNotEmpty);
      expect(results.first.texts.length, 1,
          reason: 'loading 22 translations per row to show one is waste');
    });

    test('name lookup matches any language the exercise goes by', () async {
      final byId = await source.getExerciseByUuid('20');
      expect(byId, isNotNull);

      for (final name in byId!.allNames.take(4)) {
        final resolved = await source.getExerciseByName(name);
        expect(resolved?.uuid, '20', reason: 'lookup failed for "$name"');
      }
    });
  });
}
