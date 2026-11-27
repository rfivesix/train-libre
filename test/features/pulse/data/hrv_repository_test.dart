import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/data/drift_database.dart';
import 'package:train_libre/features/pulse/application/pulse_tracking_service.dart';
import 'package:train_libre/features/pulse/data/hrv_repository.dart';

class _Settings implements PulseTrackingSettingsService {
  _Settings(this.enabled);
  bool enabled;
  int requests = 0;
  @override
  Future<bool> isTrackingEnabled() async => enabled;
  @override
  Future<bool> requestPermissions() async {
    requests++;
    return true;
  }

  @override
  Future<void> setTrackingEnabled(bool value) async {
    enabled = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test.hrv');
  final start = DateTime.utc(2026, 3, 28, 22);
  final end = DateTime.utc(2026, 3, 29, 7);
  late AppDatabase db;
  late _Settings settings;
  var calls = 0;
  var samples = <Map<String, Object>>[];
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    settings = _Settings(true);
    calls = 0;
    samples = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          expect(call.method, 'readHrvSamples');
          return samples;
        });
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await db.close();
  });

  test(
    'iOS imports SDNN, keeps source and identity, and deduplicates',
    () async {
      samples = [
        {
          'startUtcIso': '2026-03-29T00:01:00.000Z',
          'endUtcIso': '2026-03-29T00:02:00.000Z',
          'sdnnMs': 42.5,
          'nativeId': 'one',
          'sourceId': 'watch',
        },
        {
          'startUtcIso': '2026-03-29T00:01:00.000Z',
          'endUtcIso': '2026-03-29T00:02:00.000Z',
          'sdnnMs': 42.5,
          'nativeId': 'one',
          'sourceId': 'watch',
        },
        {
          'startUtcIso': '2026-03-29T05:00:00.000Z',
          'endUtcIso': '2026-03-29T05:01:00.000Z',
          'sdnnMs': 57.5,
          'nativeId': 'two',
          'sourceId': 'watch',
        },
        {
          'startUtcIso': '2026-03-29T05:00:00.000Z',
          'endUtcIso': '2026-03-29T05:01:00.000Z',
          'sdnnMs': -1.0,
          'nativeId': 'bad',
          'sourceId': 'watch',
        },
      ];
      final repo = HealthHrvRepository(
        database: db,
        trackingService: settings,
        channel: channel,
        isIos: true,
      );
      final summary = await repo.getSummary(fromUtc: start, toUtc: end);
      expect(summary.state, HrvState.available);
      expect(summary.sampleCount, 2);
      expect(summary.averageMs, 50);
      expect(summary.samples.first.sourceId, 'watch');
      expect(settings.requests, 1);
      final stored = await db
          .customSelect('SELECT * FROM pulse_hrv_samples')
          .get();
      expect(stored.length, 2);
      await repo.getSummary(fromUtc: start, toUtc: end);
      expect(settings.requests, 1);
      expect(
        (await db.customSelect('SELECT * FROM pulse_hrv_samples').get()).length,
        2,
      );
    },
  );

  test('empty HealthKit result does not expose stale cached data', () async {
    samples = [
      {
        'startUtcIso': '2026-03-29T00:01:00.000Z',
        'endUtcIso': '2026-03-29T00:02:00.000Z',
        'sdnnMs': 42.5,
        'nativeId': 'one',
        'sourceId': 'watch',
      },
    ];
    final repo = HealthHrvRepository(
      database: db,
      trackingService: settings,
      channel: channel,
      isIos: true,
    );
    await repo.getSummary(fromUtc: start, toUtc: end);
    samples = [];
    final result = await repo.getSummary(fromUtc: start, toUtc: end);
    expect(result.state, HrvState.noData);
    expect(result.averageMs, isNull);
  });

  test('disabled pulse and Android do not read the health store', () async {
    settings.enabled = false;
    final ios = HealthHrvRepository(
      database: db,
      trackingService: settings,
      channel: channel,
      isIos: true,
    );
    expect(
      (await ios.getSummary(fromUtc: start, toUtc: end)).state,
      HrvState.disabled,
    );
    settings.enabled = true;
    final android = HealthHrvRepository(
      database: db,
      trackingService: settings,
      channel: channel,
      isIos: false,
    );
    expect(
      (await android.getSummary(fromUtc: start, toUtc: end)).state,
      HrvState.unavailable,
    );
    expect(calls, 0);
    expect(settings.requests, 0);
  });

  test('a query failure is distinct from an empty result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'query_failed');
        });
    final repo = HealthHrvRepository(
      database: db,
      trackingService: settings,
      channel: channel,
      isIos: true,
    );
    final result = await repo.getSummary(fromUtc: start, toUtc: end);
    expect(result.state, HrvState.queryFailed);
    expect(result.averageMs, isNull);
  });
}
