import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One measured stretch of startup work.
class StartupPhase {
  /// Identifier of the step, e.g. `glass_init`. Deliberately an app-internal
  /// name and nothing else — these are shipped to the feedback report.
  final String name;

  /// Milliseconds from the start of the run to the moment this phase began.
  final int startMs;

  /// How long the phase took.
  final int durationMs;

  const StartupPhase({
    required this.name,
    required this.startMs,
    required this.durationMs,
  });

  Map<String, Object?> toJson() => {'n': name, 's': startMs, 'd': durationMs};

  static StartupPhase? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['n'];
    if (name is! String) return null;
    return StartupPhase(
      name: name,
      startMs: _asInt(raw['s']),
      durationMs: _asInt(raw['d']),
    );
  }
}

/// Why the app was busy: a cold start, or coming back from the background.
enum StartupRunKind { cold, resume }

/// Everything measured between the app starting to work and the user being
/// able to see the result.
class StartupRun {
  final StartupRunKind kind;
  final DateTime at;

  /// Milliseconds from the start of the run to the first frame that actually
  /// reached the screen. Zero while the run is still open.
  final int toFirstFrameMs;

  final List<StartupPhase> phases;

  const StartupRun({
    required this.kind,
    required this.at,
    required this.toFirstFrameMs,
    required this.phases,
  });

  /// The phase that took the longest, or null when nothing was measured.
  StartupPhase? get worstPhase {
    StartupPhase? worst;
    for (final phase in phases) {
      if (worst == null || phase.durationMs > worst.durationMs) worst = phase;
    }
    return worst;
  }

  /// Time inside the run that no phase accounts for.
  ///
  /// This is the interesting number when every phase looks cheap and the app
  /// still took two seconds: the cost is then in framework startup, shader
  /// warmup or the first build, none of which this class can wrap.
  int get unattributedMs {
    var measured = 0;
    for (final phase in phases) {
      measured += phase.durationMs;
    }
    final rest = toFirstFrameMs - measured;
    return rest < 0 ? 0 : rest;
  }

  Map<String, Object?> toJson() => {
        'k': kind.name,
        'at': at.toUtc().millisecondsSinceEpoch,
        'f': toFirstFrameMs,
        'p': phases.map((phase) => phase.toJson()).toList(),
      };

  static StartupRun? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = raw['at'];
    if (at is! int) return null;
    final kind = StartupRunKind.values.firstWhere(
      (candidate) => candidate.name == raw['k'],
      orElse: () => StartupRunKind.cold,
    );
    final phases = <StartupPhase>[];
    final rawPhases = raw['p'];
    if (rawPhases is List) {
      for (final entry in rawPhases) {
        final phase = StartupPhase.fromJson(entry);
        if (phase != null) phases.add(phase);
      }
    }
    return StartupRun(
      kind: kind,
      at: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true).toLocal(),
      toFirstFrameMs: _asInt(raw['f']),
      phases: List<StartupPhase>.unmodifiable(phases),
    );
  }
}

/// Immutable view of the recorded runs, newest first.
class StartupSnapshot {
  final List<StartupRun> runs;

  const StartupSnapshot({required this.runs});

  bool get isEmpty => runs.isEmpty;

  StartupRun? get lastCold => _lastOf(StartupRunKind.cold);
  StartupRun? get lastResume => _lastOf(StartupRunKind.resume);

  StartupRun? _lastOf(StartupRunKind kind) {
    for (final run in runs) {
      if (run.kind == kind) return run;
    }
    return null;
  }

  /// Median time to first frame for [kind], or null when nothing was recorded.
  ///
  /// The median rather than the mean: one run that hit a cold filesystem cache
  /// should not decide the number the user reads.
  int? medianToFirstFrame(StartupRunKind kind) {
    final values = [
      for (final run in runs)
        if (run.kind == kind && run.toFirstFrameMs > 0) run.toFirstFrameMs,
    ]..sort();
    if (values.isEmpty) return null;
    return values[values.length ~/ 2];
  }
}

/// Where the seconds go between launching the app and being able to use it.
///
/// The frame statistics in [JankRecorder] answer "which screen drops frames"
/// but say nothing about the two stretches users actually complain about: the
/// wait after tapping the icon, and the wait after bringing the app back from
/// the background. Neither produces frames to measure — the app is busy, not
/// janky — so they need their own measurement.
///
/// The phases are wrapped by hand at the call sites rather than derived, so
/// what a phase covers is whatever the code around it says it covers. Time the
/// run contains but no phase claims shows up as [StartupRun.unattributedMs],
/// which is the honest way to report framework startup and shader warmup:
/// visible, but not falsely attributed to app code.
class StartupTrace {
  StartupTrace._({int Function()? clock})
      : _clock = clock ?? _defaultClock(),
        _runStartedAtMs = 0;

  static final StartupTrace instance = StartupTrace._();

  /// A trace with an injectable clock, so tests do not have to wait in real
  /// time for a phase to take a measurable number of milliseconds.
  @visibleForTesting
  static StartupTrace createForTest({required int Function() clock}) =>
      StartupTrace._(clock: clock);

  static int Function() _defaultClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsedMilliseconds;
  }

  static const String prefsKey = 'perf_startup_trace_v1';

  /// Enough to see whether a slow start is the rule or a one-off, without
  /// growing the stored payload without bound.
  static const int maxRuns = 12;

  final int Function() _clock;

  final List<StartupRun> _runs = [];
  final Map<String, int> _openPhases = {};
  final List<StartupPhase> _phases = [];

  StartupRunKind? _openKind;
  bool _wasForeground = true;
  int _runStartedAtMs;
  DateTime? _openRunAt;
  bool _isAttached = false;

  /// Whether a run is open and still waiting for its first frame.
  bool get hasOpenRun => _openKind != null;

  /// Starts the cold-start run. Call as early in `main()` as possible.
  void beginColdStart() => _beginRun(StartupRunKind.cold);

  /// Starts a resume run. Closed by the next frame that reaches the screen.
  void beginResume() => _beginRun(StartupRunKind.resume);

  void _beginRun(StartupRunKind kind) {
    // A resume that arrives while a cold start is still open is the same wait
    // to the user; keeping the cold-start run is the more useful of the two.
    if (_openKind == StartupRunKind.cold && kind == StartupRunKind.resume) {
      return;
    }
    _openKind = kind;
    _openRunAt = DateTime.now();
    _runStartedAtMs = _clock();
    _openPhases.clear();
    _phases.clear();
  }

  /// Marks the start of a named phase. Ignored when no run is open.
  void beginPhase(String name) {
    if (_openKind == null || _openPhases.containsKey(name)) return;
    _openPhases[name] = _clock();
  }

  /// Closes a phase opened by [beginPhase]. Ignored when it was never opened.
  void endPhase(String name) {
    final startedAt = _openPhases.remove(name);
    if (startedAt == null) return;
    _phases.add(StartupPhase(
      name: name,
      startMs: startedAt - _runStartedAtMs,
      durationMs: _clock() - startedAt,
    ));
  }

  /// Runs [body] as a measured phase.
  ///
  /// The phase is closed even when [body] throws, so a failing step still
  /// shows up with the time it burned rather than disappearing.
  Future<T> measure<T>(String name, Future<T> Function() body) async {
    beginPhase(name);
    try {
      return await body();
    } finally {
      endPhase(name);
    }
  }

  /// Closes the open run at the first frame that reached the screen.
  ///
  /// Called from the frame timings callback rather than a post-frame callback:
  /// a post-frame callback fires when the frame has been *built*, which on a
  /// screen full of backdrop filters can be well before anything is visible.
  void noteFrameRasterized() {
    final kind = _openKind;
    if (kind == null) return;

    // Phases still open when the frame lands were never closed by their call
    // site. Dropping them would hide the time; closing them here reports it.
    for (final name in _openPhases.keys.toList()) {
      endPhase(name);
    }

    _runs.insert(
      0,
      StartupRun(
        kind: kind,
        at: _openRunAt ?? DateTime.now(),
        toFirstFrameMs: _clock() - _runStartedAtMs,
        phases: List<StartupPhase>.unmodifiable(_phases),
      ),
    );
    if (_runs.length > maxRuns) _runs.removeRange(maxRuns, _runs.length);

    _openKind = null;
    _openRunAt = null;
    _phases.clear();
    _openPhases.clear();

    unawaited(persist());
  }

  StartupSnapshot snapshot() => StartupSnapshot(
        runs: List<StartupRun>.unmodifiable(_runs),
      );

  Future<void> reset() async {
    _runs.clear();
    await persist();
  }

  /// Hooks the frame and lifecycle callbacks. Safe to call more than once.
  /// The hooks are registered before the first `await` on purpose: the frame
  /// this run is waiting for can land while the stored runs are still being
  /// read back, and a callback registered after it would miss it.
  Future<void> attach() async {
    if (_isAttached) return;
    _isAttached = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addObserver(_StartupTraceObserver(this));
    await _restore();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty || _openKind == null) return;
    noteFrameRasterized();
  }

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsKey,
        jsonEncode({'runs': _runs.map((run) => run.toJson()).toList()}),
      );
    } catch (error) {
      debugPrint('[perf] persisting startup trace failed: $error');
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final runs = decoded['runs'];
      if (runs is! List) return;

      // Restored runs go after the one this launch is recording.
      final restored = <StartupRun>[];
      for (final entry in runs) {
        final run = StartupRun.fromJson(entry);
        if (run != null) restored.add(run);
      }
      _runs.addAll(restored);
      if (_runs.length > maxRuns) _runs.removeRange(maxRuns, _runs.length);
    } catch (error) {
      debugPrint('[perf] restoring startup trace failed: $error');
    }
  }

  /// Opens a resume run when the app really comes back from the background.
  ///
  /// iOS delivers `resumed` after transient interruptions too — a control
  /// centre pull, a permission sheet — and measuring those would bury the
  /// returns the user actually waits for in noise.
  void handleLifecycleState(AppLifecycleState state) {
    final isResumed = state == AppLifecycleState.resumed;
    if (isResumed && !_wasForeground) {
      beginResume();
    }
    _wasForeground = isResumed;
  }
}

class _StartupTraceObserver with WidgetsBindingObserver {
  _StartupTraceObserver(this._trace);

  final StartupTrace _trace;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      _trace.handleLifecycleState(state);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
