import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BasisDataManager.shouldImportAsset', () {
    test('imports on first run with versionless asset when no data exists', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '0',
        installedVersion: '0',
        hasExistingDataForVersionlessAsset: false,
      );

      expect(shouldImport, isTrue);
    });

    test('skips re-import for versionless asset when data already exists', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '0',
        installedVersion: '0',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isFalse);
    });

    test('imports when asset version is newer than installed version', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: false,
        assetVersion: '202601010001',
        installedVersion: '202501010001',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isTrue);
    });

    test('force import always imports', () {
      final shouldImport = BasisDataManager.shouldImportAsset(
        forceImport: true,
        assetVersion: '0',
        installedVersion: '000000000001',
        hasExistingDataForVersionlessAsset: true,
      );

      expect(shouldImport, isTrue);
    });
  });

  group('BasisDataManager.storedVersionAfterImport', () {
    test('stores fallback version for versionless assets', () {
      final stored = BasisDataManager.storedVersionAfterImport(
        assetVersion: '0',
      );
      expect(stored, '000000000001');
    });

    test('stores actual version when provided', () {
      final stored = BasisDataManager.storedVersionAfterImport(
        assetVersion: '202601010001',
      );
      expect(stored, '202601010001');
    });
  });

  group('BasisDataManager.checkForBasisDataUpdate build-bound gating', () {
    late AppDatabase db;

    setUp(() async {
      databaseFactory = databaseFactorySqflitePlugin;
      PackageInfo.setMockInitialValues(
        appName: 'Train Libre',
        packageName: 'com.rfivesix.trainlibre',
        version: '0.8.5',
        buildNumber: '80013',
        buildSignature: '',
      );
      const pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
        if (call.method == 'getTemporaryDirectory') {
          return '.';
        }
        if (call.method == 'getApplicationSupportDirectory') {
          return '.';
        }
        return null;
      });
      const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sqfliteChannel, (call) async {
        if (call.method == 'getDatabasesPath') {
          return '.';
        }
        if (call.method == 'openDatabase') {
          return 1;
        }
        if (call.method == 'closeDatabase') {
          return null;
        }
        if (call.method == 'query') {
          final arguments = call.arguments as Map;
          final sqlTable = arguments['table'] as String?;
          if (sqlTable == 'sqlite_master') {
            return [
              {'name': 'exercises'}
            ];
          }
          if (sqlTable == 'metadata') {
            return [
              {'value': '0'}
            ];
          }
          return [];
        }
        return null;
      });
      db = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(db);
      BasisDataManager.instance.invalidateCatalogPresenceCache();
      await db.into(db.exercises).insert(const ExercisesCompanion(
            id: Value('dummy-uuid'),
          ));
      await db
          .into(db.exerciseTranslations)
          .insert(const ExerciseTranslationsCompanion(
            exerciseId: Value('dummy-uuid'),
            name: Value('dummy'),
            languageCode: Value('de'),
          ));
    });

    /// Seeds the rows the bundled imports would have produced, so the
    /// "everything is installed" preference state is actually backed by data.
    Future<void> seedBundledCatalogData() async {
      await db.into(db.products).insert(const ProductsCompanion(
            barcode: Value('base-1'),
            name: Value('Base product'),
            calories: Value(100),
            protein: Value(1),
            carbs: Value(2),
            fat: Value(3),
            source: Value('base'),
          ));
      await db.into(db.foodCategories).insert(const FoodCategoriesCompanion(
            key: Value('obst'),
            nameDe: Value('Obst'),
          ));
    }

    tearDown(() async {
      const pathProviderChannel =
          MethodChannel('plugins.flutter.io/path_provider');
      const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sqfliteChannel, null);
      await db.close();
    });

    test('skips update entirely when build number matches cached value',
        () async {
      await seedBundledCatalogData();
      await db.into(db.products).insert(const ProductsCompanion(
            barcode: Value('off-1'),
            name: Value('OFF product'),
            calories: Value(100),
            protein: Value(1),
            carbs: Value(2),
            fat: Value(3),
            source: Value('off'),
          ));
      SharedPreferences.setMockInitialValues({
        'is_exercise_catalog_initialized': true,
        'last_db_sync_app_version': '80013',
        'installed_food_enrichment_v1': true,
        'installed_training_version': '999999999999',
        'installed_food_version': '999999999999',
        'installed_cats_version': '999999999999',
        'installed_off_version_de': '999999999999',
      });

      final progressCalls = <Map<String, dynamic>>[];

      await BasisDataManager.instance.checkForBasisDataUpdate(
        onProgress: (task, detail, progress) {
          progressCalls.add({
            'task': task,
            'detail': detail,
            'progress': progress,
          });
        },
      );

      // Verify that it skipped and reported completion immediately for all food areas
      expect(progressCalls, hasLength(3));

      expect(progressCalls[0]['task'], 'Basis-Produkte');
      expect(progressCalls[0]['detail'], 'Basis-Produkte sind aktuell.');
      expect(progressCalls[0]['progress'], 1.0);

      expect(progressCalls[1]['task'], 'Kategorien');
      expect(progressCalls[1]['detail'], 'Kategorien sind aktuell.');
      expect(progressCalls[1]['progress'], 1.0);

      expect(progressCalls[2]['task'], startsWith('Produktdatenbank'));
      expect(progressCalls[2]['detail'], contains('ist aktuell'));
      expect(progressCalls[2]['progress'], 1.0);
    });

    test(
        'does not skip when the preferences claim catalogs the device does not have',
        () async {
      // The state a restored backup used to leave behind: every bookkeeping
      // key says "installed", but nothing was imported on this device.
      SharedPreferences.setMockInitialValues({
        'is_exercise_catalog_initialized': true,
        'last_db_sync_app_version': '80013',
        'installed_food_enrichment_v1': true,
        'installed_training_version': '999999999999',
        'installed_food_version': '999999999999',
        'installed_cats_version': '999999999999',
        'installed_off_version_de': '999999999999',
      });

      final progressCalls = <String>[];
      await BasisDataManager.instance.checkForBasisDataUpdate(
        onProgress: (task, detail, progress) => progressCalls.add(detail),
      );

      // The build-bound early return must not have fired.
      expect(progressCalls, isNot(contains('Basis-Produkte sind aktuell.')));

      // The unbacked version claims are cleared so the importers and the
      // download prompt see the real state of this device.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('installed_food_version'), null);
      expect(prefs.getString('installed_cats_version'), null);
      expect(prefs.getString('installed_off_version_de'), null);
    });

    test('isOffDatabaseInitialized ignores a version without matching rows',
        () async {
      SharedPreferences.setMockInitialValues({
        'installed_off_version_de': '999999999999',
      });

      expect(
          await BasisDataManager.instance.isOffDatabaseInitialized(), isFalse);

      await db.into(db.products).insert(const ProductsCompanion(
            barcode: Value('off-1'),
            name: Value('OFF product'),
            calories: Value(100),
            protein: Value(1),
            carbs: Value(2),
            fat: Value(3),
            source: Value('off'),
          ));

      expect(
          await BasisDataManager.instance.isOffDatabaseInitialized(), isTrue);
    });

    test('isExerciseCatalogInitialized ignores a flag without matching rows',
        () async {
      await db.delete(db.exerciseTranslations).go();
      await db.delete(db.exercises).go();
      SharedPreferences.setMockInitialValues({
        'is_exercise_catalog_initialized': true,
      });

      expect(await BasisDataManager.instance.isExerciseCatalogInitialized(),
          isFalse);

      await db.into(db.exercises).insert(const ExercisesCompanion(
            id: Value('restored-uuid'),
          ));
      BasisDataManager.instance.invalidateCatalogPresenceCache();

      expect(await BasisDataManager.instance.isExerciseCatalogInitialized(),
          isTrue);
    });
  });
}
