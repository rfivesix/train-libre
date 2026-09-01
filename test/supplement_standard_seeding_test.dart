import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart'
    hide SupplementLog, Supplement;
import 'package:train_libre/features/supplements/domain/models/supplement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supplement.isCaffeine', () {
    Supplement build({String? code, required String name}) => Supplement(
          name: name,
          defaultDose: 100,
          unit: 'mg',
          code: code,
        );

    test('matches the canonical code regardless of the name', () {
      expect(build(code: 'caffeine', name: 'Koffein').isCaffeine, isTrue);
      expect(build(code: 'caffeine', name: 'Whatever').isCaffeine, isTrue);
    });

    test('matches a code-less row by its localized name', () {
      for (final name in ['Koffein', 'Caféine', 'Caffeina', 'カフェイン']) {
        expect(build(name: name).isCaffeine, isTrue, reason: name);
      }
      expect(build(name: '  koffein ').isCaffeine, isTrue);
    });

    test('does not match a row that carries a different explicit code', () {
      expect(build(code: 'creatine_monohydrate', name: 'Koffein').isCaffeine,
          isFalse);
    });

    test('does not match an unrelated supplement', () {
      expect(build(name: 'Magnesium').isCaffeine, isFalse);
    });
  });

  group('ensureStandardSupplements', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      DatabaseHelper.setDriftDb(database);
    });

    tearDown(() async {
      await database.close();
    });

    Future<List<Supplement>> supplements() => dbHelper.getAllSupplements();

    test('seeds caffeine and creatine into an empty table', () async {
      await dbHelper.ensureStandardSupplements();

      final rows = await supplements();
      expect(
          rows.where((s) => s.code == Supplement.caffeineCode), hasLength(1));
      expect(
          rows.where((s) => s.code == Supplement.creatineCode), hasLength(1));
    });

    test('seeds caffeine even when the user already has their own supplement',
        () async {
      await database.into(database.supplements).insert(
            SupplementsCompanion.insert(
              name: 'Magnesium',
              dose: 400,
              unit: 'mg',
            ),
          );

      await dbHelper.ensureStandardSupplements();

      final rows = await supplements();
      expect(rows.where((s) => s.isCaffeine), hasLength(1));
    });

    test('back-fills the code on a legacy row instead of duplicating it',
        () async {
      await database.into(database.supplements).insert(
            SupplementsCompanion.insert(
              name: 'Koffein',
              dose: 80,
              unit: 'mg',
              dailyLimit: const drift.Value(300),
            ),
          );

      await dbHelper.ensureStandardSupplements();

      final caffeine = (await supplements()).where((s) => s.isCaffeine);
      expect(caffeine, hasLength(1));
      expect(caffeine.single.code, Supplement.caffeineCode);
      // The user's own edits survive the heal.
      expect(caffeine.single.name, 'Koffein');
      expect(caffeine.single.defaultDose, 80);
      expect(caffeine.single.dailyLimit, 300);
    });

    test('is idempotent across repeated launches', () async {
      await dbHelper.ensureStandardSupplements();
      await dbHelper.ensureStandardSupplements();
      await dbHelper.ensureStandardSupplements();

      final rows = await supplements();
      expect(rows.where((s) => s.isCaffeine), hasLength(1));
      expect(rows.where((s) => s.isCreatine), hasLength(1));
    });
  });
}
