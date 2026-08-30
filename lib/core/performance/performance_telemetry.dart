import 'dart:io';

import 'package:flutter/foundation.dart';

import 'jank_recorder.dart';

/// Builds the anonymous property maps that carry frame statistics to
/// telemetry.
///
/// Everything here is hardware and app-internal class names: a model
/// identifier shared by millions of devices, counters, and the Dart type name
/// of a screen. No user content, no measurements, nothing that describes a
/// person.
class PerformanceTelemetry {
  const PerformanceTelemetry._();

  static String get platformLabel {
    if (kIsWeb) return 'web';
    return Platform.operatingSystem;
  }

  /// Properties merged into `feedback_report_submitted` when the user left the
  /// performance section switched on.
  static Map<String, dynamic> feedbackProperties({
    required PerfSnapshot snapshot,
    required String deviceLabel,
    String? platform,
    int topScreens = 5,
  }) {
    final properties = <String, dynamic>{
      'perf_device': deviceLabel,
      'perf_platform': platform ?? platformLabel,
      'perf_display_hz': _round(snapshot.refreshRateHz, 1),
      'perf_frame_budget_ms': _round(snapshot.frameBudgetMs, 1),
      'perf_frames': snapshot.totalFrames,
      'perf_jank_frames': snapshot.totalJankFrames,
      'perf_jank_pct': _round(snapshot.totalJankRatio * 100, 1),
      'perf_stalls': snapshot.stalls.length,
    };

    final worst = snapshot.screens.isEmpty ? null : snapshot.screens.first;
    if (worst != null) {
      properties['perf_worst_screen'] = worst.screen;
      properties['perf_worst_screen_jank_pct'] =
          _round(worst.jankRatio * 100, 1);
      properties['perf_worst_screen_cause'] = worst.dominantCause;
      properties['perf_worst_screen_frames'] = worst.frames;
      properties['perf_worst_frame_ms'] = _round(worst.worstFrameMs, 0);
    }

    // One compact string per screen keeps the event readable in PostHog
    // without exploding into a property per screen.
    properties['perf_top_screens'] = snapshot.screens
        .take(topScreens)
        .map((stats) => '${stats.screen}:${_round(stats.jankRatio * 100, 1)}%:'
            '${stats.dominantCause}')
        .toList(growable: false);

    return properties;
  }

  /// Properties of a single `performance_stall` event.
  static Map<String, dynamic> stallProperties({
    required StallEvent stall,
    required PerfSnapshot snapshot,
    required String deviceLabel,
    required int sessionStallIndex,
    String? platform,
  }) {
    ScreenPerfStats? stats;
    for (final candidate in snapshot.screens) {
      if (candidate.screen == stall.screen) {
        stats = candidate;
        break;
      }
    }

    return <String, dynamic>{
      'screen': stall.screen,
      'stall_ms': stall.durationMs,
      'stall_bucket': stallBucket(stall.durationMs),
      'device': deviceLabel,
      'platform': platform ?? platformLabel,
      'display_hz': _round(snapshot.refreshRateHz, 1),
      'screen_frames': stats?.frames ?? 0,
      'screen_jank_pct': stats == null ? 0.0 : _round(stats.jankRatio * 100, 1),
      'session_stall_index': sessionStallIndex,
    };
  }

  /// Bucketed duration, matching how the other latency events report time.
  static String stallBucket(int durationMs) {
    if (durationMs < 2000) return '1-2s';
    if (durationMs < 5000) return '2-5s';
    if (durationMs < 10000) return '5-10s';
    return '>10s';
  }

  static double _round(double value, int digits) {
    if (!value.isFinite) return 0;
    return double.parse(value.toStringAsFixed(digits));
  }
}

typedef StallTelemetrySender = Future<void> Function(
  Map<String, dynamic> properties,
);

typedef DeviceLabelResolver = Future<String> Function();

/// Forwards freezes to telemetry as they happen.
///
/// A frozen UI is the one problem a user cannot describe usefully after the
/// fact ("it hung once yesterday"), so it is worth reporting on its own rather
/// than waiting for a feedback report that may never be sent.
class StallTelemetryReporter {
  StallTelemetryReporter({
    required StallTelemetrySender sender,
    required JankRecorder recorder,
    required DeviceLabelResolver deviceLabelResolver,
    this.maxEventsPerSession = 5,
  })  : _sender = sender,
        _recorder = recorder,
        _deviceLabelResolver = deviceLabelResolver;

  final StallTelemetrySender _sender;
  final JankRecorder _recorder;
  final DeviceLabelResolver _deviceLabelResolver;

  /// An app stuck in a pathological loop could otherwise emit a stall every
  /// few seconds. The first handful carry the information; the rest is noise.
  final int maxEventsPerSession;

  int _sent = 0;

  int get sentCount => _sent;

  Future<void> report(StallEvent stall) async {
    if (_sent >= maxEventsPerSession) return;
    _sent++;

    try {
      final properties = PerformanceTelemetry.stallProperties(
        stall: stall,
        snapshot: _recorder.snapshot(),
        deviceLabel: await _deviceLabelResolver(),
        sessionStallIndex: _sent,
      );
      await _sender(properties);
    } catch (error) {
      debugPrint('[perf] reporting stall failed: $error');
    }
  }
}
