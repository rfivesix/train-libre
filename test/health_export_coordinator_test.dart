import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/health_export/export_service.dart';
import 'package:train_libre/features/health_export/health_export_coordinator.dart';
import 'package:train_libre/features/health_export/models/export_models.dart';

class _FakeExportService extends HealthExportService {
  _FakeExportService({
    this.enabledPlatforms = const {HealthExportPlatform.appleHealth},
  }) : super(adapters: const []);

  int exportCalls = 0;
  final Set<HealthExportPlatform> enabledPlatforms;
  final List<HealthExportPlatform> exportedPlatforms = [];

  @override
  Future<bool> isPlatformEnabled(HealthExportPlatform platform) async =>
      enabledPlatforms.contains(platform);

  @override
  Future<HealthExportResult> exportNow(
    HealthExportPlatform platform, {
    int? lookbackDays,
  }) async {
    exportCalls++;
    exportedPlatforms.add(platform);
    return HealthExportResult(platform: platform, success: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('coalesces relevant database changes into one foreground export',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = _FakeExportService();
    final coordinator = HealthExportCoordinator(
      database: database,
      service: service,
      debounceDuration: const Duration(milliseconds: 10),
      platforms: const [HealthExportPlatform.appleHealth],
    );
    addTearDown(() async {
      coordinator.dispose();
      await database.close();
    });

    coordinator.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service.exportCalls, 1);

    for (var index = 0; index < 3; index++) {
      await database.into(database.measurements).insert(
            MeasurementsCompanion(
              date: drift.Value(DateTime.now().toUtc()),
              type: const drift.Value('weight'),
              value: drift.Value(80 + index.toDouble()),
              unit: const drift.Value('kg'),
              legacySessionId: drift.Value(2000 + index),
            ),
          );
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service.exportCalls, 2);
  });

  test('runs continuous export for Health Connect when it is enabled',
      () async {
    final database = AppDatabase(NativeDatabase.memory());
    final service = _FakeExportService(
      enabledPlatforms: const {HealthExportPlatform.healthConnect},
    );
    final coordinator = HealthExportCoordinator(
      database: database,
      service: service,
      debounceDuration: const Duration(milliseconds: 10),
      platforms: const [HealthExportPlatform.healthConnect],
    );
    addTearDown(() async {
      coordinator.dispose();
      await database.close();
    });

    coordinator.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.exportedPlatforms, [HealthExportPlatform.healthConnect]);
  });
}
