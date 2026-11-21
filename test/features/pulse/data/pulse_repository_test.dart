import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/pulse/application/pulse_tracking_service.dart';
import 'package:train_libre/features/pulse/data/pulse_repository.dart';
import 'package:train_libre/features/pulse/domain/pulse_models.dart';
import 'package:train_libre/services/health/health_platform_heart_rate.dart';

class _FakeHeartRateDataSource implements HealthHeartRateDataSource {
  _FakeHeartRateDataSource({this.samples = const [], this.error});

  final List<HealthHeartRateSampleDto> samples;
  final Object? error;
  final requests = <(DateTime, DateTime)>[];

  @override
  Future<List<HealthHeartRateSampleDto>> readHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    requests.add((fromUtc, toUtc));
    if (error != null) throw error!;
    return samples
        .where(
          (sample) =>
              !sample.sampledAtUtc.isBefore(fromUtc) &&
              sample.sampledAtUtc.isBefore(toUtc),
        )
        .toList(growable: false);
  }
}

class _FakePulseSettings implements PulseTrackingSettingsService {
  const _FakePulseSettings(this.enabled);

  final bool enabled;

  @override
  Future<bool> isTrackingEnabled() async => enabled;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> setTrackingEnabled(bool enabled) async {}
}

class _FakeRestingHeartRateDataSource
    implements HealthRestingHeartRateDataSource {
  _FakeRestingHeartRateDataSource({this.samples = const [], this.error});

  final List<HealthHeartRateSampleDto> samples;
  final PlatformException? error;
  final requests = <(DateTime, DateTime)>[];

  @override
  Future<List<HealthHeartRateSampleDto>> readRestingHeartRateSamples({
    required DateTime fromUtc,
    required DateTime toUtc,
  }) async {
    requests.add((fromUtc, toUtc));
    if (error != null) throw error!;
    return samples;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses the latest reported resting pulse without changing daily pulse',
    () async {
      final start = DateTime(2026, 4, 20).toUtc();
      final end = DateTime(2026, 4, 21).toUtc();
      final restingSource = _FakeRestingHeartRateDataSource(
        samples: [
          HealthHeartRateSampleDto(
            sampledAtUtc: start.add(const Duration(hours: 4)),
            bpm: 61,
          ),
          HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 63),
          HealthHeartRateSampleDto(sampledAtUtc: end, bpm: 55),
        ],
      );
      final repository = HealthPulseAnalysisRepository(
        dataSource: _FakeHeartRateDataSource(
          samples: [HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 78)],
        ),
        restingDataSource: restingSource,
        trackingService: const _FakePulseSettings(true),
      );

      final summary = await repository.getAnalysis(
        window: PulseAnalysisWindow(startUtc: start, endUtc: end),
      );

      expect(restingSource.requests.single, (start, end));
      expect(summary.restingBpm, 61);
      expect(summary.restingBpmIsEstimated, isFalse);
      expect(summary.averageBpm, 78);
      expect(summary.chartSamples.single.bpm, 78);
    },
  );

  test('period summary and chart use reported daily values with no standard pulse access', () async {
    final start = DateTime(2026, 4, 20).toUtc();
    final end = DateTime(2026, 4, 27).toUtc();
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(
        error: PlatformException(code: 'permission_denied'),
      ),
      restingDataSource: _FakeRestingHeartRateDataSource(
        samples: [
          HealthHeartRateSampleDto(
            sampledAtUtc: DateTime(2026, 4, 24, 11).toUtc(),
            bpm: 62,
          ),
          HealthHeartRateSampleDto(
            sampledAtUtc: DateTime(2026, 4, 21, 11).toUtc(),
            bpm: 56,
          ),
          HealthHeartRateSampleDto(
            sampledAtUtc: DateTime(2026, 4, 21, 10).toUtc(),
            bpm: 69,
          ),
        ],
      ),
      trackingService: const _FakePulseSettings(true),
      database: database,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(startUtc: start, endUtc: end),
    );

    expect(summary.restingBpm, 59);
    expect(summary.averageBpm, isNull);
    expect(summary.restingBpmIsEstimated, isFalse);
    expect(summary.hasData, isTrue);
    expect(summary.canRenderChart, isTrue);
    expect(summary.chartSamples.map((point) => point.bpm), [56, 62]);
  });

  test(
    'daily analysis keeps distinct measurements within the same hour',
    () async {
      final start = DateTime.utc(2026, 4, 20);
      final source = _FakeHeartRateDataSource(
        samples: [
          HealthHeartRateSampleDto(
            sampledAtUtc: start.add(const Duration(minutes: 1, seconds: 10)),
            bpm: 60,
          ),
          HealthHeartRateSampleDto(
            sampledAtUtc: start.add(const Duration(minutes: 1, seconds: 40)),
            bpm: 140,
          ),
          HealthHeartRateSampleDto(
            sampledAtUtc: start.add(const Duration(minutes: 2)),
            bpm: 80,
          ),
        ],
      );
      final repository = HealthPulseAnalysisRepository(
        dataSource: source,
        trackingService: const _FakePulseSettings(true),
        queryPadding: Duration.zero,
      );
      final summary = await repository.getAnalysis(
        window: PulseAnalysisWindow(
          startUtc: start,
          endUtc: start.add(const Duration(days: 1)),
        ),
      );
      expect(summary.sampleCount, 3);
      expect(summary.chartSamples.map((s) => s.bpm), [60, 140, 80]);
      expect(
        summary.chartSamples[1].sampledAtUtc,
        start.add(const Duration(minutes: 1, seconds: 40)),
      );
    },
  );

  test('does not query platform when pulse tracking is disabled', () async {
    final dataSource = _FakeHeartRateDataSource();
    final restingSource = _FakeRestingHeartRateDataSource();
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      restingDataSource: restingSource,
      trackingService: const _FakePulseSettings(false),
    );
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 4, 20),
      endUtc: DateTime.utc(2026, 4, 21),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.noDataReason, PulseNoDataReason.disabled);
    expect(dataSource.requests, isEmpty);
    expect(restingSource.requests, isEmpty);
  });

  test(
    'queries padded window and filters final samples to selected window',
    () async {
      final start = DateTime.utc(2026, 4, 20);
      final end = DateTime.utc(2026, 4, 21);
      final dataSource = _FakeHeartRateDataSource(
        samples: [
          HealthHeartRateSampleDto(
            sampledAtUtc: start.subtract(const Duration(minutes: 1)),
            bpm: 60,
          ),
          HealthHeartRateSampleDto(
            sampledAtUtc: start.add(const Duration(hours: 1)),
            bpm: 70,
          ),
        ],
      );
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = HealthPulseAnalysisRepository(
        dataSource: dataSource,
        trackingService: const _FakePulseSettings(true),
        database: database,
      );

      final summary = await repository.getAnalysis(
        window: PulseAnalysisWindow(startUtc: start, endUtc: end),
      );

      expect(dataSource.requests.single, (
        start.subtract(const Duration(hours: 24)),
        end.add(const Duration(hours: 24)),
      ));
      expect(summary.sampleCount, 1);
      expect(summary.averageBpm, 70);
    },
  );

  test('maps permission error to permission no-data state', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(
        error: PlatformException(code: 'permission_denied'),
      ),
      trackingService: const _FakePulseSettings(true),
      database: database,
    );
    final window = PulseAnalysisWindow(
      startUtc: DateTime.utc(2026, 4, 20),
      endUtc: DateTime.utc(2026, 4, 21),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.noDataReason, PulseNoDataReason.permissionDenied);
  });

  test('empty manual sync preserves cached data', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 20);
    final samples = [HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 60)];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(const Duration(hours: 1)),
    );
    await repository.getAnalysis(window: window);
    samples.clear();

    final result = await repository.syncRange(
      fromUtc: start,
      toUtc: window.endUtc,
    );
    final summary = await repository.getAnalysis(window: window);

    expect(result.rawSampleCount, 0);
    expect(summary.averageBpm, 60);
  });

  test(
    'manual sync refreshes cached hours using complete hour boundaries',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final start = DateTime.utc(2026, 4, 20);
      final samples = [HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 60)];
      final dataSource = _FakeHeartRateDataSource(samples: samples);
      final repository = HealthPulseAnalysisRepository(
        dataSource: dataSource,
        trackingService: const _FakePulseSettings(true),
        database: database,
        queryPadding: Duration.zero,
      );
      final window = PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(hours: 1)),
      );
      await repository.getAnalysis(window: window);
      samples.add(
        HealthHeartRateSampleDto(
          sampledAtUtc: start.add(const Duration(minutes: 45)),
          bpm: 80,
        ),
      );

      final result = await repository.syncRange(
        fromUtc: start.add(const Duration(minutes: 15)),
        toUtc: start.add(const Duration(minutes: 50)),
      );
      final summary = await repository.getAnalysis(window: window);

      expect(dataSource.requests.last, (
        start,
        start.add(const Duration(hours: 1)),
      ));
      expect(result.rawSampleCount, 2);
      expect(summary.sampleCount, 2);
      expect(summary.averageBpm, 70);
    },
  );

  test(
    'uses aggregate cache on second hub open without reprocessing raw samples',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final start = DateTime.utc(2026, 4, 1);
      final samples = _syntheticSamples(start, 160000);
      final dataSource = _FakeHeartRateDataSource(samples: samples);
      final repository = HealthPulseAnalysisRepository(
        dataSource: dataSource,
        trackingService: const _FakePulseSettings(true),
        database: database,
        queryPadding: Duration.zero,
      );
      final window = PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 120)),
      );

      final first = await repository.getAnalysis(window: window);
      final second = await repository.getAnalysis(window: window);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(first.sampleCount, 160000);
      expect(second.sampleCount, 160000);
      expect(dataSource.requests.length, lessThanOrEqualTo(2));
      if (dataSource.requests.length == 2) {
        expect(dataSource.requests.last.$1.isAfter(start), isTrue);
      }
    },
  );

  test(
    'larger older window triggers leading backfill before summary',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final start = DateTime.utc(2026, 4, 1);
      final samples = _syntheticSamples(
        start,
        30 * 24,
        step: const Duration(hours: 1),
      );
      final dataSource = _FakeHeartRateDataSource(samples: samples);
      final repository = HealthPulseAnalysisRepository(
        dataSource: dataSource,
        trackingService: const _FakePulseSettings(true),
        database: database,
        queryPadding: Duration.zero,
      );
      final recentWindow = PulseAnalysisWindow(
        startUtc: start.add(const Duration(days: 23)),
        endUtc: start.add(const Duration(days: 30)),
      );
      final fullWindow = PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 30)),
      );

      await repository.getAnalysis(window: recentWindow);
      final summary = await repository.getAnalysis(window: fullWindow);

      expect(dataSource.requests.length, 2);
      expect(dataSource.requests.last, (
        fullWindow.startUtc,
        recentWindow.startUtc,
      ));
      expect(summary.sampleCount, 30 * 24);
    },
  );

  test('single cached bucket does not cover a much larger window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final sampleAt = start.add(const Duration(days: 10));
    final dataSource = _FakeHeartRateDataSource(
      samples: [HealthHeartRateSampleDto(sampledAtUtc: sampleAt, bpm: 70)],
    );
    final repository = HealthPulseAnalysisRepository(
      dataSource: dataSource,
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: sampleAt,
        endUtc: sampleAt.add(const Duration(hours: 1)),
      ),
    );
    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 20)),
      ),
    );

    expect(dataSource.requests.length, greaterThanOrEqualTo(2));
    expect(dataSource.requests[1].$1, start);
    expect(dataSource.requests[1].$2, sampleAt);
    expect(summary.sampleCount, 1);
  });

  test(
    'trailing new data is refreshed incrementally after cached range',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final start = DateTime.utc(2026, 4, 1);
      final samples = _syntheticSamples(
        start,
        72,
        step: const Duration(hours: 1),
      );
      final dataSource = _FakeHeartRateDataSource(samples: samples);
      final repository = HealthPulseAnalysisRepository(
        dataSource: dataSource,
        trackingService: const _FakePulseSettings(true),
        database: database,
        queryPadding: Duration.zero,
      );
      final window = PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 2)),
      );
      final expandedWindow = PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 3)),
      );

      await repository.getAnalysis(window: window);
      final cachedSummary = await repository.getAnalysis(
        window: expandedWindow,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(dataSource.requests.length, 2);
      expect(cachedSummary.sampleCount, 48);
      expect(dataSource.requests.last.$1, start.add(const Duration(days: 2)));
    },
  );

  test('weighted aggregate average and min/max preserve raw values', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 50),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(minutes: 10)),
        bpm: 100,
      ),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(hours: 1)),
        bpm: 200,
      ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(hours: 2)),
      ),
    );

    expect(summary.averageBpm, closeTo((50 + 100 + 200) / 3, 0.001));
    expect(summary.minBpm, 50);
    expect(summary.maxBpm, 200);
  });

  test('weighted aggregate metrics include leading backfilled range', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      HealthHeartRateSampleDto(sampledAtUtc: start, bpm: 40),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(hours: 1)),
        bpm: 80,
      ),
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(const Duration(days: 7)),
        bpm: 120,
      ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start.add(const Duration(days: 7)),
        endUtc: start.add(const Duration(days: 7, hours: 1)),
      ),
    );
    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(days: 8)),
      ),
    );

    expect(summary.sampleCount, 3);
    expect(summary.averageBpm, closeTo(80, 0.001));
    expect(summary.minBpm, 40);
    expect(summary.maxBpm, 120);
  });

  test('resting estimate is stable from aggregate buckets', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 4, 1);
    final samples = [
      for (var hour = 0; hour < 10; hour++)
        HealthHeartRateSampleDto(
          sampledAtUtc: start.add(Duration(hours: hour)),
          bpm: (60 + hour).toDouble(),
        ),
    ];
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      restingDataSource: _FakeRestingHeartRateDataSource(
        error: PlatformException(code: 'permission_denied'),
      ),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );

    final summary = await repository.getAnalysis(
      window: PulseAnalysisWindow(
        startUtc: start,
        endUtc: start.add(const Duration(hours: 10)),
      ),
    );

    expect(summary.restingBpm, closeTo(60.5, 0.001));
    expect(summary.restingBpmIsEstimated, isTrue);
  });

  test('detail chart is capped and covers the selected range', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final start = DateTime.utc(2026, 1, 1);
    final samples = _syntheticSamples(start, 160000);
    final repository = HealthPulseAnalysisRepository(
      dataSource: _FakeHeartRateDataSource(samples: samples),
      trackingService: const _FakePulseSettings(true),
      database: database,
      queryPadding: Duration.zero,
    );
    final window = PulseAnalysisWindow(
      startUtc: start,
      endUtc: start.add(Duration(minutes: samples.length)),
    );

    final summary = await repository.getAnalysis(window: window);

    expect(summary.chartSamples.length, lessThanOrEqualTo(2000));
    final firstChartDay = summary.chartSamples.first.sampledAtUtc.toLocal();
    final windowStartDay = window.startUtc.toLocal();
    expect(
      DateTime(
        firstChartDay.year,
        firstChartDay.month,
        firstChartDay.day,
      ).isBefore(
        DateTime(windowStartDay.year, windowStartDay.month, windowStartDay.day),
      ),
      isFalse,
    );

    final lastChartDay = summary.chartSamples.last.sampledAtUtc.toLocal();
    final windowEndDay = window.endUtc.toLocal();
    expect(
      DateTime(lastChartDay.year, lastChartDay.month, lastChartDay.day).isAfter(
        DateTime(windowEndDay.year, windowEndDay.month, windowEndDay.day),
      ),
      isFalse,
    );
  });
}

List<HealthHeartRateSampleDto> _syntheticSamples(
  DateTime start,
  int count, {
  Duration step = const Duration(minutes: 1),
}) {
  return [
    for (var i = 0; i < count; i++)
      HealthHeartRateSampleDto(
        sampledAtUtc: start.add(step * i),
        bpm: (55 + (i % 80)).toDouble(),
      ),
  ];
}
