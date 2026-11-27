import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/database_helper.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/steps/data/sources/steps_local_data_source.dart';
import 'package:train_libre/services/health/health_models.dart';
import 'package:train_libre/services/health/health_platform_steps.dart';
import 'package:train_libre/services/health/steps_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHealthPlatformSteps extends HealthPlatformSteps {
  _FakeHealthPlatformSteps(this._reads, {this.mergedApple = false});

  final bool mergedApple;
  @override
  bool get usesMergedAppleStatistics => mergedApple;

  final List<List<HealthStepSegmentDto>> _reads;
  int _readCalls = 0;

  @override
  Future<StepsAvailability> getAvailability() async =>
      StepsAvailability.available;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<HealthStepSegmentDto>> readStepSegments({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    if (_readCalls >= _reads.length) return const [];
    final result = _reads[_readCalls];
    _readCalls += 1;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Steps sync and aggregation', () {
    late AppDatabase database;
    late DatabaseHelper dbHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      database = AppDatabase(NativeDatabase.memory());
      dbHelper = DatabaseHelper.forTesting(database);
      DatabaseHelper.setDriftDb(database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'legacy provider and source preferences use automatic defaults',
      () async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(
          StepsSyncService.providerFilterKey,
          'apple',
        );
        await preferences.setString(
          StepsSyncService.sourcePolicyKey,
          'max_per_hour',
        );
        final service = StepsSyncService(
          stepsDb: StepsLocalDataSource(database),
        );

        expect(await service.getProviderFilter(), StepsProviderFilter.all);
        expect(await service.getSourcePolicy(), StepsSourcePolicy.autoDominant);
      },
    );

    test(
      're-enable sync with overlapping range does not inflate totals',
      () async {
        final t1 = DateTime.utc(2026, 3, 26, 12);
        final t2 = t1.add(const Duration(hours: 1));
        final dayLocal = DateTime(2026, 3, 26);

        final firstRead = <HealthStepSegmentDto>[
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 10),
            endAtUtc: DateTime.utc(2026, 3, 26, 11),
            stepCount: 400,
            sourceId: 'watch',
            nativeId: 'native-a',
          ),
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 11),
            endAtUtc: DateTime.utc(2026, 3, 26, 12),
            stepCount: 600,
            sourceId: 'watch',
            nativeId: 'native-b',
          ),
        ];
        final secondRead = <HealthStepSegmentDto>[
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 10),
            endAtUtc: DateTime.utc(2026, 3, 26, 11),
            stepCount: 400,
            sourceId: 'watch',
            nativeId: 'native-a',
          ),
          HealthStepSegmentDto(
            startAtUtc: DateTime.utc(2026, 3, 26, 11),
            endAtUtc: DateTime.utc(2026, 3, 26, 12),
            stepCount: 600,
            sourceId: 'watch',
            nativeId: 'native-b',
          ),
        ];

        final platform = _FakeHealthPlatformSteps([firstRead, secondRead]);
        final service = StepsSyncService(
          platform: platform,
          stepsDb: StepsLocalDataSource(database),
        );

        await service.setTrackingEnabled(true);
        await service.sync(now: t1, forceRefresh: true);
        final totalAfterFirst = await dbHelper.getDailyStepsTotal(
          dayLocal: dayLocal,
        );
        expect(totalAfterFirst, 1000);

        await service.setTrackingEnabled(false);
        await service.setTrackingEnabled(true);
        await service.sync(now: t2, forceRefresh: false);
        final totalAfterReenable = await dbHelper.getDailyStepsTotal(
          dayLocal: dayLocal,
        );

        expect(totalAfterReenable, totalAfterFirst);
      },
    );

    test('Apple migration replaces raw history and later hourly updates',
        () async {
      final oldDay = DateTime(2026, 2, 1, 12);
      final today = DateTime(2026, 3, 26, 12);
      HealthStepSegmentDto merged(DateTime start, int count) =>
          HealthStepSegmentDto(
            startAtUtc: start.toUtc(),
            endAtUtc: start.add(const Duration(hours: 1)).toUtc(),
            stepCount: count,
            sourceId: 'healthkit_merged',
            nativeId: 'hour-${start.toUtc().toIso8601String()}',
          );
      await dbHelper.upsertHealthStepSegments([
        HealthStepSegmentsCompanion.insert(
            provider: 'apple_healthkit',
            sourceId: const drift.Value('watch'),
            startAt: oldDay.toUtc(),
            endAt: oldDay.add(const Duration(minutes: 30)).toUtc(),
            stepCount: 900,
            externalKey: 'old-watch'),
        HealthStepSegmentsCompanion.insert(
            provider: 'apple_healthkit',
            sourceId: const drift.Value('phone'),
            startAt: today.toUtc(),
            endAt: today.add(const Duration(minutes: 30)).toUtc(),
            stepCount: 1500,
            externalKey: 'old-phone'),
      ]);
      final service = StepsSyncService(
          platform: _FakeHealthPlatformSteps([
            [merged(oldDay, 500), merged(today, 700)],
            [merged(today, 800)],
          ], mergedApple: true),
          stepsDb: StepsLocalDataSource(database));
      await service.setTrackingEnabled(true);
      await service.sync(now: today.add(const Duration(hours: 1)));
      expect(await dbHelper.getDailyStepsTotal(dayLocal: oldDay), 500);
      expect(await dbHelper.getDailyStepsTotal(dayLocal: today), 700);
      await service.sync(now: today.add(const Duration(hours: 2)));
      expect(await dbHelper.getDailyStepsTotal(dayLocal: oldDay), 500);
      expect(await dbHelper.getDailyStepsTotal(dayLocal: today), 800);
    });

    test('empty Apple response preserves previously imported data', () async {
      final day = DateTime(2026, 3, 26, 12);
      await dbHelper.upsertHealthStepSegments([
        HealthStepSegmentsCompanion.insert(
            provider: 'apple_healthkit',
            sourceId: const drift.Value('watch'),
            startAt: day.toUtc(),
            endAt: day.add(const Duration(minutes: 30)).toUtc(),
            stepCount: 900,
            externalKey: 'keep'),
      ]);
      final service = StepsSyncService(
          platform: _FakeHealthPlatformSteps([[]], mergedApple: true),
          stepsDb: StepsLocalDataSource(database));
      await service.setTrackingEnabled(true);
      final result = await service.sync(now: day.add(const Duration(hours: 1)));
      expect(result.skipped, isTrue);
      expect(await dbHelper.getDailyStepsTotal(dayLocal: day), 900);
    });

    test('hour ending at midnight is not counted on the next day', () async {
      final midnight = DateTime(2026, 3, 27);
      await dbHelper.upsertHealthStepSegments([
        HealthStepSegmentsCompanion.insert(
            provider: 'apple_healthkit',
            sourceId: const drift.Value('healthkit_merged'),
            startAt: midnight.subtract(const Duration(hours: 1)).toUtc(),
            endAt: midnight.toUtc(),
            stepCount: 500,
            externalKey: 'midnight'),
      ]);
      expect(await dbHelper.getDailyStepsTotal(dayLocal: midnight), 0);
    });

    test('aggregation auto policy uses dominant source per day', () async {
      await dbHelper.upsertHealthStepSegments(<HealthStepSegmentsCompanion>[
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('watch'),
          startAt: DateTime.utc(2026, 3, 26, 10),
          endAt: DateTime.utc(2026, 3, 26, 11),
          stepCount: 1000,
          externalKey: 'k1',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('phone'),
          startAt: DateTime.utc(2026, 3, 26, 10),
          endAt: DateTime.utc(2026, 3, 26, 11),
          stepCount: 1200,
          externalKey: 'k2',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('watch'),
          startAt: DateTime.utc(2026, 3, 26, 11),
          endAt: DateTime.utc(2026, 3, 26, 12),
          stepCount: 500,
          externalKey: 'k3',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('phone'),
          startAt: DateTime.utc(2026, 3, 26, 11),
          endAt: DateTime.utc(2026, 3, 26, 12),
          stepCount: 200,
          externalKey: 'k4',
          updatedAt: drift.Value(DateTime.now()),
        ),
      ]);

      final dayLocal = DateTime(2026, 3, 26);
      final total = await dbHelper.getDailyStepsTotal(dayLocal: dayLocal);
      expect(total, 1500);

      final hourly = await dbHelper.getHourlyStepsTotalsForDay(
        dayLocal: dayLocal,
      );
      final hourlyTotals = hourly
          .map((row) => row['totalSteps'] as int)
          .toList(growable: false)
        ..sort();
      expect(hourlyTotals, <int>[500, 1000]);

      final range = await dbHelper.getDailyStepsTotalsForRange(
        startLocal: dayLocal,
        endLocal: dayLocal,
      );
      expect(range.length, 1);
      expect(range.first['totalSteps'], 1500);
    });

    test('aggregation max-per-hour policy remains available', () async {
      await dbHelper.upsertHealthStepSegments(<HealthStepSegmentsCompanion>[
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('watch'),
          startAt: DateTime.utc(2026, 3, 26, 10),
          endAt: DateTime.utc(2026, 3, 26, 11),
          stepCount: 1000,
          externalKey: 'm1',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('phone'),
          startAt: DateTime.utc(2026, 3, 26, 10),
          endAt: DateTime.utc(2026, 3, 26, 11),
          stepCount: 1200,
          externalKey: 'm2',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('watch'),
          startAt: DateTime.utc(2026, 3, 26, 11),
          endAt: DateTime.utc(2026, 3, 26, 12),
          stepCount: 500,
          externalKey: 'm3',
          updatedAt: drift.Value(DateTime.now()),
        ),
        HealthStepSegmentsCompanion.insert(
          provider: 'apple_healthkit',
          sourceId: const drift.Value('phone'),
          startAt: DateTime.utc(2026, 3, 26, 11),
          endAt: DateTime.utc(2026, 3, 26, 12),
          stepCount: 200,
          externalKey: 'm4',
          updatedAt: drift.Value(DateTime.now()),
        ),
      ]);

      final dayLocal = DateTime(2026, 3, 26);
      final total = await dbHelper.getDailyStepsTotal(
        dayLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      expect(total, 1700);

      final hourly = await dbHelper.getHourlyStepsTotalsForDay(
        dayLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      final hourlyTotals = hourly
          .map((row) => row['totalSteps'] as int)
          .toList(growable: false)
        ..sort();
      expect(hourlyTotals, <int>[500, 1200]);

      final range = await dbHelper.getDailyStepsTotalsForRange(
        startLocal: dayLocal,
        endLocal: dayLocal,
        sourcePolicy: 'max_per_hour',
      );
      expect(range.length, 1);
      expect(range.first['totalSteps'], 1700);
    });
  });
}
