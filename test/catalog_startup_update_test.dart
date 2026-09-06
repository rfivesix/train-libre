import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:train_libre/config/app_data_sources.dart';
import 'package:train_libre/services/exercise_catalog_refresh_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late AppDatabase db;
  late Directory temp;
  final manifest = jsonDecode(
          File(AppDataSources.trainingAssetManifestPath).readAsStringSync())
      as Map<String, dynamic>;
  final version = manifest['version'] as String;

  Future<String> seedLegacyCatalog() async {
    final source = await databaseFactoryFfi.openDatabase(
        File(AppDataSources.trainingAssetDbPath).absolute.path,
        options: OpenDatabaseOptions(readOnly: true));
    final row = (await source.query('exercises',
            where: "status = 'active' AND tracking_type IS NOT NULL", limit: 1))
        .single;
    await source.close();
    final id = row['id'].toString();
    await db.into(db.exercises).insert(
        ExercisesCompanion(id: Value(id), categoryName: const Value('Chest')));
    await db.into(db.exerciseTranslations).insert(ExerciseTranslationsCompanion(
        exerciseId: Value(id),
        languageCode: const Value('en'),
        name: const Value('Old catalog name')));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_exercise_catalog_initialized', true);
    await prefs.setString('installed_training_version', '000000000001');
    return id;
  }

  ExerciseCatalogRefreshService offlineService() =>
      ExerciseCatalogRefreshService.forTesting(
        httpClient: MockClient((_) async => http.Response('offline', 503)),
        supportDirectoryProvider: () async => temp,
        tempDirectoryProvider: () async => temp,
      );
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    sqflite.databaseFactory = databaseFactoryFfi;
    temp = await Directory.systemTemp.createTemp('catalog-startup-audit-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => temp.path);
    PackageInfo.setMockInitialValues(
        appName: 'Train Libre',
        packageName: 'test',
        version: '1.3.0-alpha.1',
        buildNumber: '1003000',
        buildSignature: '');
    db = AppDatabase(NativeDatabase.memory());
    DatabaseHelper.setDriftDb(db);
    BasisDataManager.instance.invalidateCatalogPresenceCache();
    await db.into(db.products).insert(const ProductsCompanion(
        barcode: Value('base-1'),
        name: Value('Base'),
        calories: Value(100),
        protein: Value(1),
        carbs: Value(2),
        fat: Value(3),
        source: Value('base')));
    await db.into(db.foodCategories).insert(const FoodCategoriesCompanion(
        key: Value('fruit'), nameDe: Value('Obst')));
    SharedPreferences.setMockInitialValues({
      'last_db_sync_app_version': '1002001',
      'installed_food_enrichment_v1': true,
      'installed_food_version': '999999999999',
      'installed_cats_version': '999999999999',
    });
  });
  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await temp.delete(recursive: true);
  });
  test('startup installs the real bundled v2 catalog without a remote update',
      () async {
    await BasisDataManager.instance
        .checkForBasisDataUpdate(skipOffDatabase: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('installed_training_version'), version);
    expect(prefs.getBool('is_exercise_catalog_initialized'), true);
    final rows = await db.select(db.exercises).get();
    expect(rows.length, manifest['expected_exercise_count']);
    expect(rows.where((r) => r.trackingType != null).length, greaterThan(800));
  });
  test('bundle manifest matches the SQLite file used for offline upgrades',
      () async {
    expect(
        sha256
            .convert(
                await File(AppDataSources.trainingAssetDbPath).readAsBytes())
            .toString(),
        manifest['db_sha256']);
    final source = await databaseFactoryFfi.openDatabase(
        File(AppDataSources.trainingAssetDbPath).absolute.path,
        options: OpenDatabaseOptions(readOnly: true));
    final metadata = await source
        .query('metadata', where: 'key = ?', whereArgs: ['version']);
    expect(metadata.single['value'], version);
    await source.close();
  });

  test('app upgrade enriches existing exercises from the bundled catalog',
      () async {
    final id = await seedLegacyCatalog();
    await db.into(db.routines).insert(
        RoutinesCompanion.insert(id: const Value('routine'), name: 'My plan'));
    await db.into(db.routineExercises).insert(RoutineExercisesCompanion.insert(
        id: const Value('slot'),
        routineId: 'routine',
        exerciseId: id,
        orderIndex: 0,
        notes: const Value('Keep my notes')));
    await db.into(db.workoutLogs).insert(WorkoutLogsCompanion.insert(
        id: const Value('workout'), startTime: DateTime(2026, 8, 1)));
    await db.into(db.setLogs).insert(SetLogsCompanion.insert(
        id: const Value('set'),
        workoutLogId: 'workout',
        exerciseId: Value(id),
        exerciseNameSnapshot: const Value('Old catalog name'),
        weight: const Value(42),
        reps: const Value(8)));
    await db.into(db.exercises).insert(const ExercisesCompanion(
        id: Value('user-exercise'),
        isCustom: Value(true),
        source: Value('user')));
    await BasisDataManager.instance
        .checkForBasisDataUpdate(skipOffDatabase: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('last_db_sync_app_version'), '1003000');
    expect(prefs.getString('installed_training_version'), version);
    final updated = await (db.select(db.exercises)
          ..where((e) => e.id.equals(id)))
        .getSingle();
    expect(updated.trackingType, isNotNull);
    final custom = await (db.select(db.exercises)
          ..where((e) => e.id.equals('user-exercise')))
        .getSingle();
    expect(custom.isCustom, true);
    final slot = (await db.select(db.routineExercises).get()).single;
    expect(slot.exerciseId, id);
    expect(slot.notes, 'Keep my notes');
    final logged = (await db.select(db.setLogs).get()).single;
    expect(logged.exerciseId, id);
    expect(logged.exerciseNameSnapshot, 'Old catalog name');
    expect(logged.weight, 42);
    expect(logged.reps, 8);
  });

  test('same app build still adopts a newer bundle after restoring old data',
      () async {
    await seedLegacyCatalog();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_db_sync_app_version', '1003000');
    await BasisDataManager.instance
        .checkForBasisDataUpdate(skipOffDatabase: true);
    expect(prefs.getString('installed_training_version'), version);
  });

  for (final installed in [version, '999999999999']) {
    test('startup preserves an already current or newer catalog ($installed)',
        () async {
      final id = await seedLegacyCatalog();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('installed_training_version', installed);
      await BasisDataManager.instance
          .checkForBasisDataUpdate(skipOffDatabase: true);
      expect(prefs.getString('installed_training_version'), installed);
      final row = await (db.select(db.exercises)..where((e) => e.id.equals(id)))
          .getSingle();
      expect(row.trackingType, isNull,
          reason: 'No reimport of an equal/older bundle');
    });
  }

  test('missing rows are repaired despite a newer restored version claim',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_exercise_catalog_initialized', true);
    await prefs.setString('installed_training_version', '999999999999');
    await BasisDataManager.instance
        .checkForBasisDataUpdate(skipOffDatabase: true);
    expect(prefs.getString('installed_training_version'), version);
    expect(prefs.getBool('is_exercise_catalog_initialized'), true);
    expect((await db.select(db.exercises).get()).length,
        manifest['expected_exercise_count']);
  });

  test('manual offline update keeps a newer installed catalog and its version',
      () async {
    final id = await seedLegacyCatalog();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('installed_training_version', '999999999999');
    await BasisDataManager.instance.importExerciseCatalog(
        force: true, catalogRefreshService: offlineService());
    expect(prefs.getString('installed_training_version'), '999999999999');
    expect((await db.select(db.exercises).get()).single.id, id);
  });

  test('manual offline update still installs a newer bundled catalog',
      () async {
    await seedLegacyCatalog();
    await BasisDataManager.instance.importExerciseCatalog(
        force: true, catalogRefreshService: offlineService());
    expect(
        (await SharedPreferences.getInstance())
            .getString('installed_training_version'),
        version);
  });
}
