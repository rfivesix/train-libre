import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/performance/jank_recorder.dart';
import 'package:train_libre/core/performance/performance_telemetry.dart';

FrameTiming _frame({required int buildMs, required int rasterMs}) {
  final int buildFinish = buildMs * 1000;
  final int rasterFinish = buildFinish + rasterMs * 1000;
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 0,
    buildFinish: buildFinish,
    rasterStart: buildFinish,
    rasterFinish: rasterFinish,
    rasterFinishWallTime: rasterFinish,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('PerformanceTelemetry.feedbackProperties', () {
    test('carries device, display and the worst screen', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);
      recorder.setScreen('NutritionTab');
      recorder.handleTimings([
        for (var i = 0; i < 90; i++) _frame(buildMs: 2, rasterMs: 2),
        for (var i = 0; i < 10; i++) _frame(buildMs: 4, rasterMs: 60),
      ]);

      final props = PerformanceTelemetry.feedbackProperties(
        snapshot: recorder.snapshot(),
        deviceLabel: 'iPhone (iPhone14,4)',
        platform: 'ios',
      );

      expect(props['perf_device'], 'iPhone (iPhone14,4)');
      expect(props['perf_platform'], 'ios');
      expect(props['perf_display_hz'], 60.0);
      expect(props['perf_frames'], 100);
      expect(props['perf_jank_frames'], 10);
      expect(props['perf_jank_pct'], 10.0);
      expect(props['perf_worst_screen'], 'NutritionTab');
      expect(props['perf_worst_screen_cause'], 'raster');
      expect(props['perf_top_screens'], ['NutritionTab:10.0%:raster']);
    });

    test('holds no user content — only class names and counters', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);
      recorder.setScreen('DiaryTab');
      recorder.handleTimings([_frame(buildMs: 2, rasterMs: 2)]);

      final props = PerformanceTelemetry.feedbackProperties(
        snapshot: recorder.snapshot(),
        deviceLabel: 'unavailable',
        platform: 'ios',
      );

      for (final value in props.values) {
        expect(
          value is num || value is String || value is List,
          isTrue,
          reason: 'unexpected property type ${value.runtimeType}',
        );
      }
      expect(props.keys.every((key) => key.startsWith('perf_')), isTrue);
    });
  });

  group('StallTelemetryReporter', () {
    test('reports a stall with its screen, duration and device', () async {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);
      recorder.setScreen('DataManagementScreen');
      recorder.handleTimings([
        for (var i = 0; i < 50; i++) _frame(buildMs: 2, rasterMs: 2),
      ]);

      final sent = <Map<String, dynamic>>[];
      final reporter = StallTelemetryReporter(
        recorder: recorder,
        deviceLabelResolver: () async => 'iPhone (iPhone14,4)',
        sender: (properties) async => sent.add(properties),
      );
      recorder.onStall = (stall) => reporter.report(stall);

      recorder.recordStallForTest(durationMs: 2400);
      await Future<void>.delayed(Duration.zero);

      expect(sent, hasLength(1));
      expect(sent.single['screen'], 'DataManagementScreen');
      expect(sent.single['stall_ms'], 2400);
      expect(sent.single['stall_bucket'], '2-5s');
      expect(sent.single['device'], 'iPhone (iPhone14,4)');
      expect(sent.single['display_hz'], 60.0);
      expect(sent.single['screen_frames'], 50);
      expect(sent.single['session_stall_index'], 1);
    });

    test('stops after the per-session cap so a freeze loop cannot spam',
        () async {
      final recorder = JankRecorder.createForTest();
      final sent = <Map<String, dynamic>>[];
      final reporter = StallTelemetryReporter(
        recorder: recorder,
        deviceLabelResolver: () async => 'unavailable',
        sender: (properties) async => sent.add(properties),
        maxEventsPerSession: 2,
      );

      for (var i = 0; i < 6; i++) {
        await reporter.report(StallEvent(
          screen: 'DiaryTab',
          at: DateTime.now(),
          durationMs: 1500,
        ));
      }

      expect(sent, hasLength(2));
    });

    test('buckets the duration the way the other latency events do', () {
      expect(PerformanceTelemetry.stallBucket(1500), '1-2s');
      expect(PerformanceTelemetry.stallBucket(4000), '2-5s');
      expect(PerformanceTelemetry.stallBucket(9000), '5-10s');
      expect(PerformanceTelemetry.stallBucket(30000), '>10s');
    });
  });
}
