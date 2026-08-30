import '../../../core/performance/device_label.dart';
import '../../../core/performance/jank_recorder.dart';
import '../../../core/performance/startup_trace.dart';
import '../domain/feedback_report_builder.dart';

/// Renders the recorded frame statistics as report lines.
///
/// The output is deliberately English and machine-greppable, one line per
/// screen, so a report pasted into an issue can be read without the app.
class PerformanceDiagnosticsProvider
    implements FeedbackReportDiagnosticsProvider {
  PerformanceDiagnosticsProvider({
    JankRecorder? recorder,
    StartupTrace? startupTrace,
    DeviceLabelLoader? deviceLabelLoader,
    this.maxScreens = 12,
    this.maxStalls = 10,
    this.maxStartupRuns = 6,
  })  : _recorder = recorder ?? JankRecorder.instance,
        _startupTrace = startupTrace ?? StartupTrace.instance,
        _deviceLabelLoader = deviceLabelLoader ?? DeviceLabel.load;

  final JankRecorder _recorder;
  final StartupTrace _startupTrace;
  final DeviceLabelLoader _deviceLabelLoader;
  final int maxScreens;
  final int maxStalls;
  final int maxStartupRuns;

  @override
  Future<List<String>> buildLines({required DateTime now}) async {
    return buildLinesFrom(
      snapshot: _recorder.snapshot(),
      startup: _startupTrace.snapshot(),
      now: now,
      deviceLabel: await _deviceLabelLoader(),
    );
  }

  List<String> buildLinesFrom({
    required PerfSnapshot snapshot,
    required DateTime now,
    required String deviceLabel,
    StartupSnapshot startup = const StartupSnapshot(runs: []),
  }) {
    final lines = <String>[
      'device: $deviceLabel',
      'display_hz: ${_num(snapshot.refreshRateHz, 1)}',
      'frame_budget_ms: ${_num(snapshot.frameBudgetMs, 1)}',
      'recording_since: ${_timestamp(snapshot.since)}',
      'recording_paused: ${snapshot.isPaused ? 'yes' : 'no'}',
      'total_frames: ${snapshot.totalFrames}',
      'janky_frames: ${snapshot.totalJankFrames} '
          '(${_percent(snapshot.totalJankRatio)})',
      'stalls_recorded: ${snapshot.stalls.length}',
    ];

    lines.addAll(_startupLines(startup));

    if (snapshot.isEmpty) {
      lines.add('status: no frames recorded yet');
      return lines;
    }

    final screens = snapshot.screens.take(maxScreens);
    for (final stats in screens) {
      lines.add(
        'screen[${stats.screen}]: '
        'frames=${stats.frames} '
        'jank=${_percent(stats.jankRatio)} '
        'severe=${stats.severeFrames} '
        'avg=${_num(stats.averageFrameMs, 1)}ms '
        'worst=${_num(stats.worstFrameMs, 0)}ms '
        'worst_build=${_num(stats.worstBuildMs, 0)}ms '
        'worst_raster=${_num(stats.worstRasterMs, 0)}ms '
        'cause=${stats.dominantCause}',
      );
    }

    if (snapshot.screens.length > maxScreens) {
      lines.add(
        'screens_omitted: ${snapshot.screens.length - maxScreens}',
      );
    }

    final stalls = snapshot.stalls.take(maxStalls).toList();
    for (var i = 0; i < stalls.length; i++) {
      final stall = stalls[i];
      lines.add(
        'stall[${i + 1}]: ${stall.durationMs}ms '
        'screen=${stall.screen} '
        'at=${_timestamp(stall.at)}',
      );
    }

    return lines;
  }

  /// The launch and resume waits, which produce no frames to measure and so
  /// appear nowhere in the statistics above.
  List<String> _startupLines(StartupSnapshot startup) {
    if (startup.isEmpty) return const ['startup: not measured yet'];

    final lines = <String>[];
    for (final kind in StartupRunKind.values) {
      final median = startup.medianToFirstFrame(kind);
      if (median != null) {
        lines.add('startup_${kind.name}_median_ms: $median');
      }
    }

    final runs = startup.runs.take(maxStartupRuns);
    for (final run in runs) {
      final phases = [...run.phases]
        ..sort((a, b) => b.durationMs.compareTo(a.durationMs));
      final detail = [
        for (final phase in phases) '${phase.name}=${phase.durationMs}ms',
        'unattributed=${run.unattributedMs}ms',
      ].join(' ');
      lines.add(
        'startup[${run.kind.name}]: '
        'to_first_frame=${run.toFirstFrameMs}ms '
        'at=${_timestamp(run.at)} '
        '$detail',
      );
    }
    return lines;
  }

  static String _percent(double ratio) =>
      '${(ratio * 100).toStringAsFixed(1)}%';

  static String _num(double value, int digits) => value.toStringAsFixed(digits);

  static String _timestamp(DateTime? value) =>
      value == null ? 'unavailable' : value.toUtc().toIso8601String();
}
