import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Frame statistics aggregated per screen.
///
/// Deliberately counters only: no timestamps of what the user did, no content,
/// nothing that identifies a person. What leaves the device is a table of
/// frame counts, so the report stays useful without becoming personal data.
class ScreenPerfStats {
  final String screen;
  int frames;
  int jankFrames;
  int severeFrames;

  /// Split of the janky frames by which thread dominated. Raster-bound jank
  /// points at shaders, blur and backdrop filters; build-bound jank points at
  /// Dart work inside the frame. The fixes are different, so the report has to
  /// keep them apart.
  int rasterBoundJank;
  int buildBoundJank;

  double worstFrameMs;
  double worstBuildMs;
  double worstRasterMs;
  double sumFrameMs;

  ScreenPerfStats({
    required this.screen,
    this.frames = 0,
    this.jankFrames = 0,
    this.severeFrames = 0,
    this.rasterBoundJank = 0,
    this.buildBoundJank = 0,
    this.worstFrameMs = 0,
    this.worstBuildMs = 0,
    this.worstRasterMs = 0,
    this.sumFrameMs = 0,
  });

  double get jankRatio => frames == 0 ? 0 : jankFrames / frames;

  double get averageFrameMs => frames == 0 ? 0 : sumFrameMs / frames;

  /// `raster`, `build` or `-` when nothing janked yet.
  String get dominantCause {
    if (jankFrames == 0) return '-';
    return rasterBoundJank >= buildBoundJank ? 'raster' : 'build';
  }

  void mergeFrom(ScreenPerfStats other) {
    frames += other.frames;
    jankFrames += other.jankFrames;
    severeFrames += other.severeFrames;
    rasterBoundJank += other.rasterBoundJank;
    buildBoundJank += other.buildBoundJank;
    sumFrameMs += other.sumFrameMs;
    if (other.worstFrameMs > worstFrameMs) worstFrameMs = other.worstFrameMs;
    if (other.worstBuildMs > worstBuildMs) worstBuildMs = other.worstBuildMs;
    if (other.worstRasterMs > worstRasterMs) {
      worstRasterMs = other.worstRasterMs;
    }
  }

  Map<String, Object?> toJson() => {
        's': screen,
        'f': frames,
        'j': jankFrames,
        'sv': severeFrames,
        'rb': rasterBoundJank,
        'bb': buildBoundJank,
        'wf': worstFrameMs,
        'wb': worstBuildMs,
        'wr': worstRasterMs,
        'sum': sumFrameMs,
      };

  static ScreenPerfStats? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final screen = raw['s'];
    if (screen is! String || screen.isEmpty) return null;
    return ScreenPerfStats(
      screen: screen,
      frames: _asInt(raw['f']),
      jankFrames: _asInt(raw['j']),
      severeFrames: _asInt(raw['sv']),
      rasterBoundJank: _asInt(raw['rb']),
      buildBoundJank: _asInt(raw['bb']),
      worstFrameMs: _asDouble(raw['wf']),
      worstBuildMs: _asDouble(raw['wb']),
      worstRasterMs: _asDouble(raw['wr']),
      sumFrameMs: _asDouble(raw['sum']),
    );
  }
}

/// A stretch where the UI isolate stopped answering — the "app freezes, I can
/// tap nothing" case. Frame timings alone miss it, because a blocked isolate
/// produces no frames at all.
class StallEvent {
  final String screen;
  final DateTime at;
  final int durationMs;

  const StallEvent({
    required this.screen,
    required this.at,
    required this.durationMs,
  });

  Map<String, Object?> toJson() => {
        's': screen,
        'at': at.toUtc().millisecondsSinceEpoch,
        'd': durationMs,
      };

  static StallEvent? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final screen = raw['s'];
    final at = raw['at'];
    if (screen is! String || at is! int) return null;
    return StallEvent(
      screen: screen,
      at: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true).toLocal(),
      durationMs: _asInt(raw['d']),
    );
  }
}

/// Immutable view of everything the recorder holds, so the UI and the feedback
/// report never read the live mutable state.
class PerfSnapshot {
  final double refreshRateHz;
  final double frameBudgetMs;
  final DateTime? since;
  final bool isPaused;
  final List<ScreenPerfStats> screens;
  final List<StallEvent> stalls;

  const PerfSnapshot({
    required this.refreshRateHz,
    required this.frameBudgetMs,
    required this.since,
    required this.isPaused,
    required this.screens,
    required this.stalls,
  });

  int get totalFrames =>
      screens.fold<int>(0, (sum, stats) => sum + stats.frames);

  int get totalJankFrames =>
      screens.fold<int>(0, (sum, stats) => sum + stats.jankFrames);

  double get totalJankRatio =>
      totalFrames == 0 ? 0 : totalJankFrames / totalFrames;

  bool get isEmpty => totalFrames == 0 && stalls.isEmpty;
}

/// Records where the app drops frames, on the device it actually happens on.
///
/// This exists because jank is the one class of bug that cannot be reproduced
/// on a fast development machine: a Mac renders the same screen well inside
/// budget while a three-year-old phone misses it. `addTimingsCallback` runs in
/// release builds at negligible cost, so the numbers come from real usage.
class JankRecorder with WidgetsBindingObserver {
  JankRecorder._();

  static final JankRecorder instance = JankRecorder._();

  @visibleForTesting
  static JankRecorder createForTest() => JankRecorder._();

  static const String prefsKey = 'perf_jank_stats_v1';

  /// A frame counts as severe when it overruns the budget this many times
  /// over — that is the range a user perceives as a visible hitch rather than
  /// a slightly late frame.
  static const double severeMultiplier = 3.0;

  /// Below this many frames a jank percentage is noise, not a measurement.
  static const int minRankedFrames = 30;

  static const Duration _watchdogInterval = Duration(milliseconds: 500);
  static const Duration _stallThreshold = Duration(milliseconds: 1200);
  static const int _maxStalls = 25;
  static const int _maxScreens = 40;
  static const int _framesPerFlush = 900;

  final Map<String, ScreenPerfStats> _stats = <String, ScreenPerfStats>{};
  final List<StallEvent> _stalls = <StallEvent>[];

  String _screen = 'App';
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isForeground = true;
  bool _skipNextWatchdogTick = false;
  DateTime? _since;
  double _refreshRateHz = 60;
  Timer? _watchdog;
  Stopwatch? _watchdogClock;
  int _lastTickMs = 0;
  int _framesSinceFlush = 0;

  /// Called whenever a freeze is recorded. Kept as a callback so this file
  /// stays free of any telemetry dependency, and so tests can observe it.
  void Function(StallEvent stall)? onStall;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  String get currentScreen => _screen;

  double get refreshRateHz => _refreshRateHz;

  /// Budget for one frame. Hard-coding 16.7 ms would silently swallow half the
  /// dropped frames on a 120 Hz ProMotion device, so it follows the display.
  double get frameBudgetMs => 1000.0 / _refreshRateHz;

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    _refreshRateHz = _readRefreshRate();
    await _restore();
    _since ??= DateTime.now();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    WidgetsBinding.instance.addObserver(this);
    _startWatchdog();
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    WidgetsBinding.instance.removeObserver(this);
    _watchdog?.cancel();
    _watchdog = null;
    _watchdogClock = null;
    await persist();
  }

  /// Called by the route observer and by the tab switcher. Frame timings arrive
  /// batched and slightly delayed, so a handful of frames around a transition
  /// land on the screen that follows. Over thousands of frames that is noise.
  void setScreen(String screen) {
    final trimmed = screen.trim();
    if (trimmed.isEmpty || trimmed == _screen) return;
    _screen = trimmed;
  }

  void setPaused(bool value) {
    if (_isPaused == value) return;
    _isPaused = value;
    if (!value) _skipNextWatchdogTick = true;
  }

  Future<void> reset() async {
    _stats.clear();
    _stalls.clear();
    _since = DateTime.now();
    _framesSinceFlush = 0;
    await persist();
  }

  PerfSnapshot snapshot() {
    final screens = _stats.values.where((stats) => stats.frames > 0).toList()
      ..sort((a, b) {
        // Worst offender first, by share of dropped frames. A handful of frames
        // can produce a wild percentage, so screens below [minRankedFrames] are
        // ranked after the ones with a meaningful sample rather than topping
        // the list on noise.
        final aRankable = a.frames >= minRankedFrames;
        final bRankable = b.frames >= minRankedFrames;
        if (aRankable != bRankable) return aRankable ? -1 : 1;

        final byRatio = b.jankRatio.compareTo(a.jankRatio);
        if (byRatio != 0) return byRatio;
        return b.frames.compareTo(a.frames);
      });

    final stalls = _stalls.reversed.toList(growable: false);

    return PerfSnapshot(
      refreshRateHz: _refreshRateHz,
      frameBudgetMs: frameBudgetMs,
      since: _since,
      isPaused: _isPaused,
      screens: List<ScreenPerfStats>.unmodifiable(screens),
      stalls: List<StallEvent>.unmodifiable(stalls),
    );
  }

  @visibleForTesting
  void handleTimings(List<FrameTiming> timings) => _onTimings(timings);

  @visibleForTesting
  void recordStallForTest({required int durationMs}) =>
      _recordStall(durationMs);

  @visibleForTesting
  void setRefreshRateForTest(double hz) => _refreshRateHz = hz;

  void _onTimings(List<FrameTiming> timings) {
    if (_isPaused || timings.isEmpty) return;

    final budget = frameBudgetMs;
    final severeBudget = budget * severeMultiplier;
    final stats = _statsFor(_screen);

    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
      final frameMs = buildMs + rasterMs;

      stats.frames++;
      stats.sumFrameMs += frameMs;
      if (frameMs > stats.worstFrameMs) stats.worstFrameMs = frameMs;
      if (buildMs > stats.worstBuildMs) stats.worstBuildMs = buildMs;
      if (rasterMs > stats.worstRasterMs) stats.worstRasterMs = rasterMs;

      if (frameMs > budget) {
        stats.jankFrames++;
        if (frameMs > severeBudget) stats.severeFrames++;
        if (rasterMs >= buildMs) {
          stats.rasterBoundJank++;
        } else {
          stats.buildBoundJank++;
        }
      }
    }

    _framesSinceFlush += timings.length;
    if (_framesSinceFlush >= _framesPerFlush) {
      _framesSinceFlush = 0;
      unawaited(persist());
    }
  }

  ScreenPerfStats _statsFor(String screen) {
    final existing = _stats[screen];
    if (existing != null) return existing;

    // An unbounded map would grow with every dynamically named route. Once the
    // cap is hit, drop the least interesting entry rather than the newest one.
    if (_stats.length >= _maxScreens) {
      String? victim;
      var fewestFrames = -1;
      for (final entry in _stats.entries) {
        if (entry.value.jankFrames > 0) continue;
        if (fewestFrames < 0 || entry.value.frames < fewestFrames) {
          fewestFrames = entry.value.frames;
          victim = entry.key;
        }
      }
      if (victim != null) _stats.remove(victim);
    }

    final created = ScreenPerfStats(screen: screen);
    _stats[screen] = created;
    return created;
  }

  void _startWatchdog() {
    _watchdogClock = Stopwatch()..start();
    _lastTickMs = 0;
    _watchdog = Timer.periodic(_watchdogInterval, (_) {
      final clock = _watchdogClock;
      if (clock == null) return;

      final now = clock.elapsedMilliseconds;
      final delta = now - _lastTickMs;
      _lastTickMs = now;

      if (_skipNextWatchdogTick) {
        _skipNextWatchdogTick = false;
        return;
      }
      if (!_isForeground || _isPaused) return;

      // How late this tick is, which is a lower bound on how long the isolate
      // was blocked: a freeze starting just after a tick delays the next one by
      // the freeze minus one interval. Freezes shorter than the threshold plus
      // one interval therefore go unreported — for the wait after a launch or a
      // resume, [StartupTrace] measures the real span instead.
      final lateBy = delta - _watchdogInterval.inMilliseconds;
      if (lateBy >= _stallThreshold.inMilliseconds) {
        _recordStall(lateBy);
      }
    });
  }

  void _recordStall(int durationMs) {
    _stalls.add(StallEvent(
      screen: _screen,
      at: DateTime.now(),
      durationMs: durationMs,
    ));
    if (_stalls.length > _maxStalls) {
      _stalls.removeRange(0, _stalls.length - _maxStalls);
    }
    unawaited(persist());

    final listener = onStall;
    if (listener != null) {
      try {
        listener(_stalls.last);
      } catch (error) {
        debugPrint('[perf] stall listener failed: $error');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isResumed = state == AppLifecycleState.resumed;
    if (isResumed && !_isForeground) {
      // iOS suspends timers in the background, so the first tick back carries
      // the whole time away. Re-basing the clock here drops that time without
      // dropping the tick: skipping it instead blinded the watchdog to exactly
      // the freeze users report, the one that starts the moment the app comes
      // back and falls entirely inside the window that was skipped.
      final clock = _watchdogClock;
      if (clock != null) _lastTickMs = clock.elapsedMilliseconds;
    }
    _isForeground = isResumed;
    if (!isResumed) {
      unawaited(persist());
    }
  }

  @override
  void didChangeMetrics() {
    // Covers a display mode change and the first frames after launch, where the
    // view may not have reported its real refresh rate yet.
    final rate = _readRefreshRate();
    if (rate > 0) _refreshRateHz = rate;
  }

  double _readRefreshRate() {
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isEmpty) return _refreshRateHz;
      final rate = views.first.display.refreshRate;
      if (!rate.isFinite || rate < 30 || rate > 240) return _refreshRateHz;
      return rate;
    } catch (_) {
      return _refreshRateHz;
    }
  }

  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, Object?>{
        'since': _since?.toUtc().millisecondsSinceEpoch,
        'hz': _refreshRateHz,
        'screens': _stats.values
            .where((stats) => stats.frames > 0)
            .map((stats) => stats.toJson())
            .toList(),
        'stalls': _stalls.map((stall) => stall.toJson()).toList(),
      };
      await prefs.setString(prefsKey, jsonEncode(payload));
    } catch (error) {
      debugPrint('[perf] persisting frame stats failed: $error');
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final since = decoded['since'];
      if (since is int) {
        _since =
            DateTime.fromMillisecondsSinceEpoch(since, isUtc: true).toLocal();
      }

      final screens = decoded['screens'];
      if (screens is List) {
        for (final entry in screens) {
          final stats = ScreenPerfStats.fromJson(entry);
          if (stats == null) continue;
          final target = _statsFor(stats.screen);
          target.mergeFrom(stats);
        }
      }

      final stalls = decoded['stalls'];
      if (stalls is List) {
        for (final entry in stalls) {
          final stall = StallEvent.fromJson(entry);
          if (stall != null) _stalls.add(stall);
        }
        if (_stalls.length > _maxStalls) {
          _stalls.removeRange(0, _stalls.length - _maxStalls);
        }
      }
    } catch (error) {
      debugPrint('[perf] restoring frame stats failed: $error');
    }
  }
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;
