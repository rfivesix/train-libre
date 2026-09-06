@TestOn('vm')
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_classification_labels.dart';
import 'package:train_libre/features/exercise_catalog/domain/exercise_locale_chain.dart';
import 'package:train_libre/generated/app_localizations.dart';

/// Every classification value the shipped catalog carries has a label.
///
/// The other label test asserts against a list typed out by hand, which
/// catches a typo but not a vocabulary that grew. This one reads the asset the
/// app actually ships, so the day the data repo adds a 32nd movement pattern
/// this fails — rather than the chip silently not appearing.
const String kAssetPath = 'assets/db/train_libre_training.db';

/// Values that are deliberately unlabelled.
///
/// `other` is the movement-pattern vocabulary admitting it has no answer for
/// 76 exercises. A chip reading "Other" tells the reader nothing.
const Set<String> kUnlabelled = {'other'};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase db;

  setUpAll(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    ExerciseLocaleChain.invalidate();
    await BasisDataManager.instance.importExerciseCatalogFromFileForTesting(
      File(kAssetPath).absolute.path,
    );
    ExerciseLocaleChain.invalidate();
  });

  tearDownAll(() async {
    await db.close();
    ExerciseLocaleChain.invalidate();
  });

  Future<List<String>> distinct(String column) async {
    final rows = await db
        .customSelect('SELECT DISTINCT $column AS v FROM exercises '
            'WHERE $column IS NOT NULL AND $column != \'\' ORDER BY v')
        .get();
    return rows
        .map((r) => r.read<String>('v'))
        .where((v) => !kUnlabelled.contains(v))
        .toList();
  }

  Future<BuildContext> contextFor(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        home: Builder(builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        }),
      ),
    );
    return captured;
  }

  testWidgets('the catalog is what this test reads', (tester) async {
    // A guard on the guard: if the import quietly failed, every list below
    // would be empty and every assertion would pass.
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM exercises')
        .getSingle();
    expect(rows.read<int>('c'), greaterThan(800));
  });

  testWidgets('every shipped value is named', (tester) async {
    final context = await contextFor(tester);

    final axes =
        <String, ({List<String> values, String? Function(String) label})>{
      'mechanic': (
        values: await distinct('mechanic'),
        label: (v) => ExerciseClassificationLabels.mechanic(context, v),
      ),
      'laterality': (
        values: await distinct('laterality'),
        label: (v) => ExerciseClassificationLabels.laterality(context, v),
      ),
      'difficulty': (
        values: await distinct('difficulty'),
        label: (v) => ExerciseClassificationLabels.difficulty(context, v),
      ),
      'force_vector': (
        values: await distinct('force_vector'),
        label: (v) => ExerciseClassificationLabels.forceVector(context, v),
      ),
      'movement_pattern': (
        values: await distinct('movement_pattern'),
        label: (v) => ExerciseClassificationLabels.movementPattern(context, v),
      ),
    };

    for (final entry in axes.entries) {
      expect(entry.value.values, isNotEmpty, reason: '${entry.key} is empty');
      for (final value in entry.value.values) {
        expect(entry.value.label(value), isNotNull,
            reason: '${entry.key} "$value" has no label');
      }
    }
  });

  testWidgets('every usage tag in use is named', (tester) async {
    final context = await contextFor(tester);
    final rows = await db
        .customSelect('SELECT DISTINCT tag AS v FROM exercise_tags ORDER BY v')
        .get();
    final tags = rows.map((r) => r.read<String>('v')).toList();

    expect(tags, isNotEmpty);
    for (final tag in tags) {
      expect(ExerciseClassificationLabels.usageTag(context, tag), isNotNull,
          reason: 'usage tag "$tag" has no label');
    }
  });
}
