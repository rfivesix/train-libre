import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:train_libre/core/performance/startup_trace.dart';

/// The startup trace answers "where did the two seconds go". Everything here
/// drives it with a fake clock, because the numbers it reports are the whole
/// point — a test that waited in real time would measure the test runner.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late int now;
  late int wallMicros;
  late StartupTrace trace;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = 0;
    wallMicros = 1700000000000000;
    trace = StartupTrace.createForTest(
      clock: () => now,
      wallClock: () => wallMicros,
    );
  });

  test('a cold start reports the time to the first frame', () {
    trace.beginColdStart();
    now = 1800;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.kind, StartupRunKind.cold);
    expect(run.toFirstFrameMs, 1800);
  });

  test('phases carry their own duration and their offset into the run', () {
    trace.beginColdStart();

    now = 100;
    trace.beginPhase('glass_init');
    now = 700;
    trace.endPhase('glass_init');

    now = 750;
    trace.beginPhase('prefs');
    now = 800;
    trace.endPhase('prefs');

    now = 1000;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.phases.map((p) => p.name).toList(), ['glass_init', 'prefs']);
    expect(run.phases[0].durationMs, 600);
    expect(run.phases[0].startMs, 100);
    expect(run.phases[1].durationMs, 50);
    expect(run.phases[1].startMs, 750);
  });

  test('the worst phase is the one to look at first', () {
    trace.beginColdStart();
    now = 10;
    trace.beginPhase('cheap');
    now = 20;
    trace.endPhase('cheap');
    now = 30;
    trace.beginPhase('expensive');
    now = 900;
    trace.endPhase('expensive');
    now = 950;
    trace.noteFrameRasterized();

    expect(trace.snapshot().runs.single.worstPhase?.name, 'expensive');
  });

  test('time no phase claims is reported rather than hidden', () {
    // This is the case that matters: every measured step is cheap and the app
    // still took two seconds. The rest is framework startup and shader warmup,
    // which no phase here can wrap.
    trace.beginColdStart();
    now = 100;
    trace.beginPhase('prefs');
    now = 150;
    trace.endPhase('prefs');
    now = 2000;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.unattributedMs, 1950);
  });

  test('a phase left open is closed by the frame instead of vanishing', () {
    trace.beginColdStart();
    now = 100;
    trace.beginPhase('never_closed');
    now = 900;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.phases.single.name, 'never_closed');
    expect(run.phases.single.durationMs, 800);
  });

  test('measure closes the phase even when the body throws', () async {
    trace.beginColdStart();
    now = 100;

    await expectLater(
      trace.measure('failing', () async {
        now = 400;
        throw StateError('boom');
      }),
      throwsStateError,
    );

    now = 500;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.phases.single.name, 'failing');
    expect(run.phases.single.durationMs, 300);
  });

  test('a resume is recorded separately from the cold start', () {
    trace.beginColdStart();
    now = 1000;
    trace.noteFrameRasterized();

    now = 60000;
    trace.beginResume();
    now = 61400;
    trace.noteFrameRasterized();

    final runs = trace.snapshot().runs;
    expect(runs.first.kind, StartupRunKind.resume);
    expect(runs.first.toFirstFrameMs, 1400);
    expect(runs.last.kind, StartupRunKind.cold);
  });

  test('a resume during an open cold start does not replace it', () {
    // The user sees one wait, not two, and the cold start is the one that
    // explains it.
    trace.beginColdStart();
    now = 200;
    trace.beginPhase('prefs');
    now = 300;
    trace.endPhase('prefs');

    trace.beginResume();

    now = 1500;
    trace.noteFrameRasterized();

    final run = trace.snapshot().runs.single;
    expect(run.kind, StartupRunKind.cold);
    expect(run.toFirstFrameMs, 1500);
    expect(run.phases.single.name, 'prefs');
  });

  test('frames outside a run are ignored', () {
    trace.noteFrameRasterized();
    expect(trace.snapshot().isEmpty, isTrue);

    trace.beginColdStart();
    now = 500;
    trace.noteFrameRasterized();
    now = 600;
    trace.noteFrameRasterized();

    expect(trace.snapshot().runs.length, 1);
  });

  test('phases recorded outside a run are dropped', () {
    trace.beginPhase('orphan');
    now = 100;
    trace.endPhase('orphan');

    trace.beginColdStart();
    now = 200;
    trace.noteFrameRasterized();

    expect(trace.snapshot().runs.single.phases, isEmpty);
  });

  test('only the most recent runs are kept', () {
    for (var i = 0; i < StartupTrace.maxRuns + 5; i++) {
      trace.beginColdStart();
      now += 100 + i;
      trace.noteFrameRasterized();
    }
    expect(trace.snapshot().runs.length, StartupTrace.maxRuns);
  });

  test('the median ignores a single outlier run', () {
    for (final duration in [900, 950, 1000, 8000, 1050]) {
      trace.beginColdStart();
      final start = now;
      now = start + duration;
      trace.noteFrameRasterized();
      now += 10;
    }

    final snapshot = trace.snapshot();
    expect(snapshot.medianToFirstFrame(StartupRunKind.cold), 1000);
    expect(snapshot.medianToFirstFrame(StartupRunKind.resume), isNull);
  });

  test('runs survive a restart', () async {
    trace.beginColdStart();
    now = 1234;
    trace.beginPhase('glass_init');
    now = 1500;
    trace.endPhase('glass_init');
    now = 1700;
    trace.noteFrameRasterized();
    await trace.persist();

    final reloaded = StartupTrace.createForTest(clock: () => 0);
    await reloaded.attach();

    final run = reloaded.snapshot().runs.single;
    expect(run.toFirstFrameMs, 1700);
    expect(run.phases.single.name, 'glass_init');
    expect(run.phases.single.durationMs, 266);
  });

  test('a resume is only measured when the app really was in the background',
      () {
    trace.beginColdStart();
    now = 800;
    trace.noteFrameRasterized();

    // iOS delivers `resumed` after transient interruptions too — a control
    // centre pull, a permission sheet. Measuring those would bury the returns
    // the user actually waits for in noise.
    trace.handleLifecycleState(AppLifecycleState.resumed);
    expect(trace.hasOpenRun, isFalse);

    trace.handleLifecycleState(AppLifecycleState.paused);
    trace.handleLifecycleState(AppLifecycleState.resumed);
    expect(trace.hasOpenRun, isTrue);

    now = 2000;
    trace.noteFrameRasterized();
    expect(trace.snapshot().runs.first.kind, StartupRunKind.resume);
    expect(trace.snapshot().runs.first.toFirstFrameMs, 1200);
  });

  test('a pull of the control centre is not a resume', () {
    // iOS stops at `inactive` for an interruption that never hides the app.
    // Treating that as a return from the background filled the log with runs
    // the user never waited for.
    trace.handleLifecycleState(AppLifecycleState.paused);
    trace.handleLifecycleState(AppLifecycleState.resumed);
    now = 40;
    trace.noteFrameRasterized();

    trace.handleLifecycleState(AppLifecycleState.inactive);
    trace.handleLifecycleState(AppLifecycleState.resumed);
    expect(trace.hasOpenRun, isFalse);
  });

  test('the resume is measured to the frame, not to the timing callback', () {
    // The engine flushes frame timings at most once a second, so the callback
    // that closes the run arrives long after the frame it describes. Reading
    // the clock there reported that flush delay as resume latency: a steady
    // ~1000ms no matter how fast the app actually came back.
    trace.handleLifecycleState(AppLifecycleState.paused);
    trace.handleLifecycleState(AppLifecycleState.resumed);

    // The frame lands 32ms in; its timing is delivered a second later.
    final frameWallMicros = wallMicros + 32 * 1000;
    now = 1040;
    trace.noteFrameRasterized(rasterFinishWallMicros: frameWallMicros);

    expect(trace.snapshot().runs.first.toFirstFrameMs, 32);
  });

  test('a wall clock that jumped falls back to the measured span', () {
    trace.beginColdStart();
    now = 900;

    // A frame stamped before the run started, or after the callback that
    // reports it, means the wall clock moved under us.
    trace.noteFrameRasterized(rasterFinishWallMicros: wallMicros - 5000000);
    expect(trace.snapshot().runs.single.toFirstFrameMs, 900);

    trace.beginColdStart();
    now += 700;
    trace.noteFrameRasterized(rasterFinishWallMicros: wallMicros + 5000000);
    expect(trace.snapshot().runs.first.toFirstFrameMs, 700);
  });

  test('a resume interrupted before its frame lands is dropped', () {
    // Otherwise the first frame of the next return closes it, and the whole
    // stretch spent in the background is reported as resume latency.
    trace.handleLifecycleState(AppLifecycleState.paused);
    trace.handleLifecycleState(AppLifecycleState.resumed);
    expect(trace.hasOpenRun, isTrue);

    trace.handleLifecycleState(AppLifecycleState.hidden);
    expect(trace.hasOpenRun, isFalse);

    now = 600000;
    wallMicros += 600000 * 1000;
    trace.handleLifecycleState(AppLifecycleState.resumed);
    now = 600030;
    trace.noteFrameRasterized(
      rasterFinishWallMicros: wallMicros + 30 * 1000,
    );

    expect(trace.snapshot().runs.single.toFirstFrameMs, 30);
  });
}
