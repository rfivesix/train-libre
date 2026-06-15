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
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
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
            return [{'name': 'exercises'}];
          }
          if (sqlTable == 'metadata') {
            return [{'value': '0'}];
          }
          return [];
        }
        return null;
      });
      db = AppDatabase(NativeDatabase.memory());
      DatabaseHelper.setDriftDb(db);
      await db.into(db.exercises).insert(const ExercisesCompanion(
        id: Value('dummy-uuid'),
      ));
      await db.into(db.exerciseTranslations).insert(const ExerciseTranslationsCompanion(
        exerciseId: Value('dummy-uuid'),
        name: Value('dummy'),
        languageCode: Value('de'),
      ));
    });

    tearDown(() async {
      const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
      const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sqfliteChannel, null);
      await db.close();
    });

    test('skips update entirely when build number matches cached value', () async {
      SharedPreferences.setMockInitialValues({
        'last_db_sync_app_version': '80013',
        'installed_food_enrichment_v1': true,
        'installed_training_version': '999999999999',
        'installed_food_version': '999999999999',
        'installed_categories_version': '999999999999',
        'installed_off_version': '999999999999',
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

      // Verify that it skipped and reported completion immediately for all areas (including exercises and products)
      expect(progressCalls, hasLength(6));

      expect(progressCalls[3]['task'], 'Basis-Produkte');
      expect(progressCalls[3]['detail'], 'Basis-Produkte sind aktuell.');
      expect(progressCalls[3]['progress'], 1.0);

      expect(progressCalls[4]['task'], 'Kategorien');
      expect(progressCalls[4]['detail'], 'Kategorien sind aktuell.');
      expect(progressCalls[4]['progress'], 1.0);

      expect(progressCalls[5]['task'], startsWith('Produktdatenbank'));
      expect(progressCalls[5]['detail'], contains('ist aktuell'));
      expect(progressCalls[5]['progress'], 1.0);
    });
  });
}
