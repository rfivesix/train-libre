import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/performance/jank_recorder.dart';
import 'package:train_libre/core/performance/startup_trace.dart';
import 'package:train_libre/features/feedback_report/data/performance_diagnostics_provider.dart';

FrameTiming _frame({
  required int buildMs,
  required int rasterMs,
}) {
  const int vsyncStart = 0;
  final int buildFinish = buildMs * 1000;
  final int rasterFinish = buildFinish + rasterMs * 1000;
  return FrameTiming(
    vsyncStart: vsyncStart,
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

  group('JankRecorder', () {
    test('counts frames over the display budget as jank', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

      recorder.setScreen('DiaryTab');
      recorder.handleTimings([
        _frame(buildMs: 4, rasterMs: 5), // 9ms — inside the 16.7ms budget
        _frame(buildMs: 6, rasterMs: 30), // 36ms — janky, raster bound
        _frame(buildMs: 90, rasterMs: 4), // 94ms — severe, build bound
      ]);

      final snapshot = recorder.snapshot();
      final stats = snapshot.screens.single;

      expect(stats.screen, 'DiaryTab');
      expect(stats.frames, 3);
      expect(stats.jankFrames, 2);
      expect(stats.severeFrames, 1);
      expect(stats.rasterBoundJank, 1);
      expect(stats.buildBoundJank, 1);
      expect(stats.worstFrameMs, closeTo(94, 0.001));
      expect(stats.worstBuildMs, closeTo(90, 0.001));
      expect(stats.worstRasterMs, closeTo(30, 0.001));
    });

    test('applies the 120Hz budget when the display reports it', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(120);

      recorder.setScreen('WorkoutTab');
      // 12ms would pass at 60Hz but misses the 8.3ms budget of a ProMotion
      // display — the case a hard-coded 16.7ms would silently swallow.
      recorder.handleTimings([_frame(buildMs: 6, rasterMs: 6)]);

      expect(recorder.snapshot().screens.single.jankFrames, 1);
    });

    test('attributes frames to the screen that was current', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

      recorder.setScreen('DiaryTab');
      recorder.handleTimings([_frame(buildMs: 2, rasterMs: 2)]);
      recorder.setScreen('AiMealCaptureScreen');
      recorder.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);

      final snapshot = recorder.snapshot();
      // Sorted by jank first, so the offending screen leads.
      expect(snapshot.screens.first.screen, 'AiMealCaptureScreen');
      expect(snapshot.screens.first.jankFrames, 1);
      expect(snapshot.totalFrames, 2);
    });

    test('ranks screens by their share of dropped frames', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

      recorder.setScreen('NutritionTab');
      recorder.handleTimings([
        for (var i = 0; i < 40; i++) _frame(buildMs: 2, rasterMs: 2),
        for (var i = 0; i < 10; i++) _frame(buildMs: 30, rasterMs: 10),
      ]); // 50 frames, 20% jank

      recorder.setScreen('DiaryTab');
      recorder.handleTimings([
        for (var i = 0; i < 900; i++) _frame(buildMs: 2, rasterMs: 2),
        for (var i = 0; i < 100; i++) _frame(buildMs: 30, rasterMs: 10),
      ]); // 1000 frames, 10% jank — more janky frames, but a better screen

      // A screen too small to judge must not top the list on noise.
      recorder.setScreen('ShareSheetScreen');
      recorder.handleTimings([_frame(buildMs: 30, rasterMs: 10)]);

      final order =
          recorder.snapshot().screens.map((stats) => stats.screen).toList();
      expect(order, ['NutritionTab', 'DiaryTab', 'ShareSheetScreen']);
    });

    test('records stalls against the current screen', () {
      final recorder = JankRecorder.createForTest();
      recorder.setScreen('DataManagementScreen');
      recorder.recordStallForTest(durationMs: 2400);

      final stalls = recorder.snapshot().stalls;
      expect(stalls, hasLength(1));
      expect(stalls.single.screen, 'DataManagementScreen');
      expect(stalls.single.durationMs, 2400);
    });

    test('pausing stops collecting', () {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

      recorder.setScreen('DiaryTab');
      recorder.setPaused(true);
      recorder.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);

      expect(recorder.snapshot().totalFrames, 0);
      expect(recorder.snapshot().isPaused, isTrue);
    });

    test('reset clears the collected data', () async {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);

      recorder.setScreen('DiaryTab');
      recorder.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);
      recorder.recordStallForTest(durationMs: 1500);
      await recorder.reset();

      final snapshot = recorder.snapshot();
      expect(snapshot.totalFrames, 0);
      expect(snapshot.stalls, isEmpty);
      expect(snapshot.isEmpty, isTrue);
    });

    test('survives a restart by restoring persisted counters', () async {
      final first = JankRecorder.createForTest()..setRefreshRateForTest(60);
      first.setScreen('DiaryTab');
      first.handleTimings([_frame(buildMs: 40, rasterMs: 40)]);
      first.recordStallForTest(durationMs: 1800);
      await first.persist();

      // A crash is exactly when the numbers matter, so a fresh process has to
      // pick up what the previous one measured.
      final second = JankRecorder.createForTest();
      await second.start();
      addTearDown(second.stop);

      final snapshot = second.snapshot();
      expect(snapshot.screens.single.screen, 'DiaryTab');
      expect(snapshot.screens.single.jankFrames, 1);
      expect(snapshot.stalls.single.durationMs, 1800);
    });
  });

  group('PerformanceDiagnosticsProvider', () {
    test('renders one greppable line per screen', () async {
      final recorder = JankRecorder.createForTest()..setRefreshRateForTest(60);
      recorder.setScreen('AiMealCaptureScreen');
      recorder.handleTimings([
        _frame(buildMs: 2, rasterMs: 2),
        _frame(buildMs: 6, rasterMs: 60),
      ]);
      recorder.recordStallForTest(durationMs: 2400);

      final lines = await PerformanceDiagnosticsProvider(
        recorder: recorder,
        deviceLabelLoader: () async => 'iPhone (iPhone14,4)',
      ).buildLines(now: DateTime.now());

      expect(lines, contains('device: iPhone (iPhone14,4)'));
      expect(lines, contains('display_hz: 60.0'));
      expect(lines, contains('frame_budget_ms: 16.7'));
      expect(lines.any((line) => line.startsWith('total_frames: 2')), isTrue);
      expect(
        lines.any((line) =>
            line.startsWith('screen[AiMealCaptureScreen]:') &&
            line.contains('cause=raster')),
        isTrue,
      );
      expect(
        lines.any((line) => line.startsWith('stall[1]: 2400ms')),
        isTrue,
      );
    });

    test('says so plainly when nothing was recorded', () async {
      final lines = await PerformanceDiagnosticsProvider(
        recorder: JankRecorder.createForTest(),
        startupTrace: StartupTrace.createForTest(clock: () => 0),
      ).buildLines(now: DateTime.now());

      expect(lines, contains('status: no frames recorded yet'));
      expect(lines, contains('startup: not measured yet'));
    });

    test('carries the launch and resume waits, phase by phase', () async {
      // The waits users complain about produce no frames, so without these
      // lines a report from a device that takes two seconds to open looks
      // exactly like one from a device that opens instantly.
      var now = 0;
      final trace = StartupTrace.createForTest(clock: () => now);

      trace.beginColdStart();
      now = 200;
      trace.beginPhase('glass_init');
      now = 800;
      trace.endPhase('glass_init');
      now = 2000;
      trace.noteFrameRasterized();

      final lines = await PerformanceDiagnosticsProvider(
        recorder: JankRecorder.createForTest(),
        startupTrace: trace,
      ).buildLines(now: DateTime.now());

      expect(lines, contains('startup_cold_median_ms: 2000'));
      final coldLine =
          lines.firstWhere((line) => line.startsWith('startup[cold]:'));
      expect(coldLine, contains('to_first_frame=2000ms'));
      expect(coldLine, contains('glass_init=600ms'));
      // The remainder is framework startup and shader warmup, and saying so is
      // the point: it tells the reader the cost is not in the phases above.
      expect(coldLine, contains('unattributed=1400ms'));
    });

    test('reports a resume separately from a launch', () async {
      var now = 0;
      final trace = StartupTrace.createForTest(clock: () => now);

      trace.beginColdStart();
      now = 900;
      trace.noteFrameRasterized();
      now = 90000;
      trace.beginResume();
      now = 91300;
      trace.noteFrameRasterized();

      final lines = await PerformanceDiagnosticsProvider(
        recorder: JankRecorder.createForTest(),
        startupTrace: trace,
      ).buildLines(now: DateTime.now());

      expect(lines, contains('startup_cold_median_ms: 900'));
      expect(lines, contains('startup_resume_median_ms: 1300'));
      expect(
        lines.any((line) =>
            line.startsWith('startup[resume]:') &&
            line.contains('to_first_frame=1300ms')),
        isTrue,
      );
    });
  });
}
