import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/services/health/apple_health_weight_import.dart';
import 'package:train_libre/services/health/health_connect_weight_import.dart';

class _FakeAppleWeightPlatform extends AppleHealthWeightImportPlatform {
  _FakeAppleWeightPlatform({required this.records});

  List<AppleHealthWeightRecord> records;
  bool permissionResult = true;
  bool denyRead = false;
  DateTime? lastFrom;

  @override
  Future<HealthConnectWeightImportStatus> getStatus() async =>
      const HealthConnectWeightImportStatus(
        available: true,
        historyAvailable: true,
        readGranted: true,
        historyGranted: true,
      );

  @override
  Future<bool> requestPermissions() async => permissionResult;

  @override
  Future<List<AppleHealthWeightRecord>> readWeights({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    lastFrom = fromUtc;
    if (denyRead) {
      throw PlatformException(code: 'permission_denied');
    }
    return records;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppleHealthWeightImportService', () {
    late AppDatabase database;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      databaseHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async => database.close());

    test('imports external records once and keeps HealthKit UUID identity',
        () async {
      final platform = _FakeAppleWeightPlatform(
        records: [
          AppleHealthWeightRecord(
            recordId: 'healthkit-weight-1',
            timestampUtc: DateTime.utc(2026, 9, 1, 8),
            weightKg: 79.4,
            sourceBundleId: 'com.scale.app',
          ),
        ],
      );
      final service = AppleHealthWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isIOS: true,
      );

      final first = await service.requestAccessAndImport();
      expect(first?.imported, 1);
      expect(await service.isEnabled(), isTrue);
      expect(await database.select(database.measurements).get(), hasLength(1));

      final repeat = await service.importNow();
      expect(repeat?.imported, 0);
      final mappings = await database.customSelect(
        'SELECT external_record_id FROM health_import_records WHERE platform = ?',
        variables: [drift.Variable.withString('appleHealth')],
      ).get();
      expect(mappings.single.read<String>('external_record_id'),
          'healthkit-weight-1');
      expect(platform.lastFrom, DateTime.utc(1970));
    });

    test('keeps every supported Apple Health measurement type separate',
        () async {
      final platform = _FakeAppleWeightPlatform(
        records: [
          AppleHealthWeightRecord(
            recordId: 'body-fat-1',
            timestampUtc: DateTime.utc(2026, 9, 2),
            weightKg: 18.5,
            sourceBundleId: 'com.scale.app',
            measurementType: 'fat_percent',
            unit: '%',
          ),
          AppleHealthWeightRecord(
            recordId: 'waist-1',
            timestampUtc: DateTime.utc(2026, 9, 3),
            weightKg: 82,
            sourceBundleId: 'com.scale.app',
            measurementType: 'waist',
            unit: 'cm',
          ),
        ],
      );
      final service = AppleHealthWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isIOS: true,
      );

      final result = await service.requestAccessAndImport();

      expect(result?.imported, 2);
      final measurements = await database.select(database.measurements).get();
      expect(
        measurements.map((measurement) => measurement.type),
        containsAll(['fat_percent', 'waist']),
      );
    });

    test('does not enable automatic import when permission is denied',
        () async {
      final platform = _FakeAppleWeightPlatform(records: const [])
        ..permissionResult = false;
      final service = AppleHealthWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isIOS: true,
      );

      expect(await service.requestAccessAndImport(), isNull);
      expect(await service.isEnabled(), isFalse);
      expect(await service.importOnColdStart(), isNull);
    });

    test('turns off import when HealthKit denies the first read query',
        () async {
      final platform = _FakeAppleWeightPlatform(records: const [])
        ..denyRead = true;
      final service = AppleHealthWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isIOS: true,
      );

      await expectLater(
        service.requestAccessAndImport(),
        throwsA(isA<PlatformException>()),
      );
      expect(await service.isEnabled(), isFalse);
    });
  });
}
