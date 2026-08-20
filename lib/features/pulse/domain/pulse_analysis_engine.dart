import 'dart:math' as math;

import 'pulse_models.dart';

class PulseAnalysisEngine {
  const PulseAnalysisEngine({this.maxChartPoints = 260});

  final int maxChartPoints;

  PulseAnalysisSummary analyze({
    required PulseAnalysisWindow window,
    required List<PulseSamplePoint> rawSamples,
    PulseNoDataReason emptyReason = PulseNoDataReason.noSamples,
  }) {
    final samples = _sanitizeAndSort(rawSamples, window);
    if (samples.isEmpty) {
      return PulseAnalysisSummary(
        window: window,
        samples: const <PulseSamplePoint>[],
        chartSamples: const <PulseSamplePoint>[],
        sampleCount: 0,
        quality: PulseDataQuality.noData,
        noDataReason: emptyReason,
      );
    }

    double minBpm = double.infinity;
    double maxBpm = double.negativeInfinity;
    for (final sample in samples) {
      final bpm = sample.bpm;
      if (bpm < minBpm) minBpm = bpm;
      if (bpm > maxBpm) maxBpm = bpm;
    }
    final averageBpm = _durationWeightedAverage(samples, window);
    final restingBpm = _restingPulse(samples);
    final quality = _classifyQuality(
      sampleCount: samples.length,
      windowDuration: window.duration,
      coverageSpan:
          samples.last.sampledAtUtc.difference(samples.first.sampledAtUtc),
    );

    return PulseAnalysisSummary(
      window: window,
      samples: samples,
      chartSamples: _downsample(samples),
      sampleCount: samples.length,
      averageBpm: averageBpm,
      minBpm: minBpm,
      maxBpm: maxBpm,
      restingBpm: restingBpm,
      quality: quality,
      noDataReason: PulseNoDataReason.none,
    );
  }

  List<PulseSamplePoint> _sanitizeAndSort(
    List<PulseSamplePoint> rawSamples,
    PulseAnalysisWindow window,
  ) {
    final groupedByTimestamp = <int, List<double>>{};
    final windowStartMs = window.startUtc.millisecondsSinceEpoch;
    final windowEndMs = window.endUtc.millisecondsSinceEpoch;

    // BOLT OPTIMIZATION: Avoid DateTime object allocations and map closure
    // allocations inside hot loop over potentially thousands of heart rate samples.
    for (var i = 0; i < rawSamples.length; i++) {
      final sample = rawSamples[i];
      final ms = sample.sampledAtUtc.millisecondsSinceEpoch;
      if (ms < windowStartMs || ms > windowEndMs) {
        continue;
      }
      final bpm = sample.bpm;
      if (!bpm.isFinite || bpm < 25 || bpm > 240) {
        continue;
      }
      var list = groupedByTimestamp[ms];
      if (list == null) {
        list = <double>[];
        groupedByTimestamp[ms] = list;
      }
      list.add(bpm);
    }

    final timestamps = groupedByTimestamp.keys.toList()..sort();

    // BOLT OPTIMIZATION: Replaced chained .map().toList() and .fold() with a
    // standard for loop to eliminate intermediate MappedIterable closures.
    final result = List<PulseSamplePoint>.generate(
      timestamps.length,
      (i) {
        final timestamp = timestamps[i];
        final values = groupedByTimestamp[timestamp]!;
        double sum = 0.0;
        for (var j = 0; j < values.length; j++) {
          sum += values[j];
        }
        return PulseSamplePoint(
          sampledAtUtc: DateTime.fromMillisecondsSinceEpoch(
            timestamp,
            isUtc: true,
          ),
          bpm: sum / values.length,
        );
      },
      growable: false,
    );
    return result;
  }

  double _durationWeightedAverage(
    List<PulseSamplePoint> samples,
    PulseAnalysisWindow window,
  ) {
    if (samples.length == 1) return samples.single.bpm;
    var weightedSum = 0.0;
    var totalSeconds = 0;

    for (var i = 0; i < samples.length; i++) {
      final current = samples[i];
      final previous = i == 0 ? window.startUtc : samples[i - 1].sampledAtUtc;
      final next =
          i == samples.length - 1 ? window.endUtc : samples[i + 1].sampledAtUtc;
      final start = _midpoint(previous, current.sampledAtUtc);
      final end = _midpoint(current.sampledAtUtc, next);
      final seconds = math.max(0, end.difference(start).inSeconds);
      if (seconds == 0) continue;
      weightedSum += current.bpm * seconds;
      totalSeconds += seconds;
    }

    if (totalSeconds <= 0) {
      return samples.fold<double>(0, (sum, sample) => sum + sample.bpm) /
          samples.length;
    }
    return weightedSum / totalSeconds;
  }

  /// MVP resting pulse: the median of the lowest 20% of valid samples.
  ///
  /// This avoids claiming a medically validated resting heart rate while still
  /// surfacing a conservative low-rest estimate from the selected period.
  double _restingPulse(List<PulseSamplePoint> samples) {
    // BOLT OPTIMIZATION: Replaced chained .map().toList() with List.generate to
    // eliminate intermediate MappedIterable overhead.
    final sorted = List<double>.generate(
      samples.length,
      (i) => samples[i].bpm,
      growable: false,
    )..sort();

    final count = math.max(1, (sorted.length * 0.2).ceil());
    final middle = count ~/ 2;
    if (count.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  PulseDataQuality _classifyQuality({
    required int sampleCount,
    required Duration windowDuration,
    required Duration coverageSpan,
  }) {
    if (sampleCount <= 0) return PulseDataQuality.noData;
    if (sampleCount < 3) return PulseDataQuality.insufficient;

    final windowMinutes = math.max(1, windowDuration.inMinutes);
    final coverageMinutes = math.max(0, coverageSpan.inMinutes);
    final density = sampleCount / windowMinutes;
    final poorCoverage = coverageMinutes < math.max(30, windowMinutes ~/ 12);
    if (sampleCount < 8 || density < 0.01 || poorCoverage) {
      return PulseDataQuality.limited;
    }
    return PulseDataQuality.ready;
  }

  DateTime _midpoint(DateTime a, DateTime b) {
    final deltaMicros = b.difference(a).inMicroseconds;
    return a.add(Duration(microseconds: deltaMicros ~/ 2));
  }

  List<PulseSamplePoint> _downsample(List<PulseSamplePoint> points) {
    if (points.length <= maxChartPoints || maxChartPoints < 3) return points;
    final sampled = <PulseSamplePoint>[];
    final step = (points.length - 1) / (maxChartPoints - 1);
    for (var i = 0; i < maxChartPoints; i++) {
      final index = (i * step).round().clamp(0, points.length - 1);
      final point = points[index];
      if (sampled.isEmpty ||
          sampled.last.sampledAtUtc != point.sampledAtUtc ||
          sampled.last.bpm != point.bpm) {
        sampled.add(point);
      }
    }
    final last = points.last;
    if (sampled.isEmpty || sampled.last.sampledAtUtc != last.sampledAtUtc) {
      sampled.add(last);
    }
    return sampled;
  }
}
