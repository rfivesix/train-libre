import 'hrv_models.dart';

enum PulseScope { day, week, month }

enum PulseDataQuality { ready, limited, insufficient, noData }

enum PulseNoDataReason {
  none,
  disabled,
  noSamples,
  permissionDenied,
  platformUnavailable,
  queryFailed,
}

class PulseSamplePoint {
  const PulseSamplePoint({required this.sampledAtUtc, required this.bpm});

  final DateTime sampledAtUtc;
  final double bpm;
}

class PulseAnalysisWindow {
  const PulseAnalysisWindow({required this.startUtc, required this.endUtc});

  final DateTime startUtc;
  final DateTime endUtc;

  Duration get duration => endUtc.difference(startUtc);
  bool get isMultiDay => duration > const Duration(hours: 25);
}

class PulseAnalysisSummary {
  const PulseAnalysisSummary({
    required this.window,
    required this.samples,
    required this.chartSamples,
    required this.sampleCount,
    required this.quality,
    required this.noDataReason,
    this.averageBpm,
    this.minBpm,
    this.maxBpm,
    this.restingBpm,
    this.restingBpmIsEstimated = false,
    this.hrv,
  });

  final PulseAnalysisWindow window;
  final List<PulseSamplePoint> samples;
  final List<PulseSamplePoint> chartSamples;
  final int sampleCount;
  final PulseDataQuality quality;
  final PulseNoDataReason noDataReason;
  final double? averageBpm;
  final double? minBpm;
  final double? maxBpm;
  final double? restingBpm;
  final bool restingBpmIsEstimated;
  final HrvSummary? hrv;

  PulseAnalysisSummary withHrv(HrvSummary? value) => copyWith(hrv: value);

  PulseAnalysisSummary copyWith({
    double? restingBpm,
    bool? restingBpmIsEstimated,
    List<PulseSamplePoint>? chartSamples,
    HrvSummary? hrv,
  }) => PulseAnalysisSummary(
    window: window,
    samples: samples,
    chartSamples: chartSamples ?? this.chartSamples,
    sampleCount: sampleCount,
    quality: quality,
    noDataReason: noDataReason,
    averageBpm: averageBpm,
    minBpm: minBpm,
    maxBpm: maxBpm,
    restingBpm: restingBpm ?? this.restingBpm,
    restingBpmIsEstimated: restingBpmIsEstimated ?? this.restingBpmIsEstimated,
    hrv: hrv ?? this.hrv,
  );

  bool get hasData => sampleCount > 0 || restingBpm != null;

  bool get hasPulseRange => minBpm != null && maxBpm != null;

  bool get canRenderChart =>
      chartSamples.isNotEmpty &&
      ((window.isMultiDay && restingBpm != null && !restingBpmIsEstimated) ||
          (quality != PulseDataQuality.noData &&
              quality != PulseDataQuality.insufficient));
}
