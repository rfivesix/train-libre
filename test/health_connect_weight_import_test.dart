import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/services/health/health_connect_weight_import.dart';

class _FakeWeightPlatform extends HealthConnectWeightImportPlatform {
  _FakeWeightPlatform({required this.status, required this.records});

  HealthConnectWeightImportStatus status;
  List<HealthConnectWeightRecord> records;
  bool permissionResult = true;
  DateTime? lastFrom;
  DateTime? lastTo;

  @override
  Future<HealthConnectWeightImportStatus> getStatus() async => status;

  @override
  Future<bool> requestPermissions() async => permissionResult;

  @override
  Future<List<HealthConnectWeightRecord>> readWeights({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    lastFrom = fromUtc;
    lastTo = toUtc;
    return records;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthConnectWeightImportService', () {
    late AppDatabase database;
    late DatabaseHelper databaseHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      databaseHelper = DatabaseHelper.forTesting(database);
    });

    tearDown(() async => database.close());

    test('imports once and updates the same local measurement', () async {
      final measuredAt = DateTime.utc(2026, 8, 1, 8);
      final modifiedAt = DateTime.utc(2026, 8, 1, 9);
      final platform = _FakeWeightPlatform(
        status: const HealthConnectWeightImportStatus(
          available: true,
          historyAvailable: true,
          readGranted: true,
          historyGranted: true,
        ),
        records: [
          HealthConnectWeightRecord(
            recordId: 'weight-1',
            lastModifiedAtUtc: modifiedAt,
            timestampUtc: measuredAt,
            weightKg: 80,
            sourcePackageName: 'com.scale.app',
          ),
        ],
      );
      final service = HealthConnectWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isAndroid: true,
      );

      final first = await service.requestAccessAndImport();
      expect(first?.imported, 1);
      expect(first?.updated, 0);
      expect(await service.isEnabled(), isTrue);
      expect(await database.select(database.measurements).get(), hasLength(1));

      final unchanged = await service.importNow();
      expect(unchanged?.imported, 0);
      expect(unchanged?.updated, 0);
      expect(await database.select(database.measurements).get(), hasLength(1));

      platform.records = [
        HealthConnectWeightRecord(
          recordId: 'weight-1',
          lastModifiedAtUtc: modifiedAt.add(const Duration(minutes: 1)),
          timestampUtc: measuredAt.add(const Duration(minutes: 5)),
          weightKg: 79.5,
          sourcePackageName: 'com.scale.app',
        ),
      ];
      final updated = await service.importNow();
      expect(updated?.imported, 0);
      expect(updated?.updated, 1);
      final measurements = await database.select(database.measurements).get();
      expect(measurements, hasLength(1));
      expect(measurements.single.value, 79.5);
      expect(
        measurements.single.date.toUtc(),
        measuredAt.add(const Duration(minutes: 5)),
      );
    });

    test('uses the 30-day window when history permission is unavailable',
        () async {
      final platform = _FakeWeightPlatform(
        status: const HealthConnectWeightImportStatus(
          available: true,
          historyAvailable: false,
          readGranted: true,
          historyGranted: false,
        ),
        records: const [],
      );
      final service = HealthConnectWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isAndroid: true,
      );

      final result = await service.importNow();

      expect(result?.limitedHistory, isTrue);
      expect(platform.lastFrom, isNotNull);
      expect(platform.lastTo, isNotNull);
      expect(
        platform.lastTo!.difference(platform.lastFrom!).inDays,
        inInclusiveRange(29, 30),
      );
    });

    test('does not enable cold-start import after denied permission', () async {
      final platform = _FakeWeightPlatform(
        status: const HealthConnectWeightImportStatus(
          available: true,
          historyAvailable: true,
          readGranted: false,
          historyGranted: false,
        ),
        records: const [],
      )..permissionResult = false;
      final service = HealthConnectWeightImportService(
        platform: platform,
        databaseHelper: databaseHelper,
        isAndroid: true,
      );

      expect(await service.requestAccessAndImport(), isNull);
      expect(await service.isEnabled(), isFalse);
      expect(await service.importOnColdStart(), isNull);
    });
  });
}
