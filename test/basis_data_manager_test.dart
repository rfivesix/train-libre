import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/infrastructure/basis_data_manager.dart';

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
    setUp(() {
      PackageInfo.setMockInitialValues(
        appName: 'Train Libre',
        packageName: 'com.rfivesix.trainlibre',
        version: '0.8.5',
        buildNumber: '80013',
        buildSignature: '',
      );
    });

    test('skips update entirely when build number matches cached value', () async {
      SharedPreferences.setMockInitialValues({
        'last_db_sync_app_version': '80013',
        'installed_food_enrichment_v1': true,
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

      // Verify that it skipped and reported completion immediately for all 3 areas
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
  });
}
