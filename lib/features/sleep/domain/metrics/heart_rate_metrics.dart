import '../heart_rate_sample.dart';

class NightlyHeartRateMetrics {
  const NightlyHeartRateMetrics({
    required this.sleepHrAvg,
    required this.sleepHrMin,
    required this.coverageSufficient,
  });

  final double? sleepHrAvg;
  final double? sleepHrMin;
  final bool coverageSufficient;
}

class SleepHeartRateBaseline {
  const SleepHeartRateBaseline({
    required this.baselineSleepHr,
    required this.isEstablished,
    required this.validNights,
  });

  final double? baselineSleepHr;
  final bool isEstablished;
  final int validNights;
}

class SleepHeartRateDelta {
  const SleepHeartRateDelta({
    required this.deltaSleepHr,
    required this.baselineEstablished,
    required this.coverageSufficient,
  });

  final double? deltaSleepHr;
  final bool baselineEstablished;
  final bool coverageSufficient;
}

NightlyHeartRateMetrics calculateNightlyHeartRateMetrics({
  required Iterable<HeartRateSample> sleepWindowSamples,
  int minimumSampleCount = 5,
}) {
  final bpms = <double>[];
  var sum = 0.0;

  // BOLT OPTIMIZATION: Replaced chained .map().toList() and .fold() with a
  // single-pass manual loop to avoid intermediate array allocations and O(2N) traversal.
  for (final sample in sleepWindowSamples) {
    final bpm = sample.bpm;
    bpms.add(bpm);
    sum += bpm;
  }

  if (bpms.length < minimumSampleCount) {
    return const NightlyHeartRateMetrics(
      sleepHrAvg: null,
      sleepHrMin: null,
      coverageSufficient: false,
    );
  }

  bpms.sort();
  final avg = sum / bpms.length;
  final p5Index = ((bpms.length - 1) * 0.05).floor();
  return NightlyHeartRateMetrics(
    sleepHrAvg: avg,
    sleepHrMin: bpms[p5Index],
    coverageSufficient: true,
  );
}

SleepHeartRateBaseline calculateSleepHeartRateBaseline(
  Iterable<double> nightlyAverageHeartRates,
) {
  final valid = <double>[];

  // BOLT OPTIMIZATION: Replaced .where().toList() with a standard for-loop
  // to prevent unnecessary Iterable allocations and GC overhead.
  for (final value in nightlyAverageHeartRates) {
    if (value.isFinite) {
      valid.add(value);
    }
  }

  if (valid.length < 10) {
    return SleepHeartRateBaseline(
      baselineSleepHr: null,
      isEstablished: false,
      validNights: valid.length,
    );
  }
  final windowStart = valid.length <= 30 ? 0 : valid.length - 30;
  // BOLT OPTIMIZATION: .sublist() already creates a fresh array, so we can sort
  // it in-place instead of creating another copy with List.from(window)..sort().
  final window = valid.sublist(windowStart);
  window.sort();
  return SleepHeartRateBaseline(
    baselineSleepHr: _median(window),
    isEstablished: true,
    validNights: valid.length,
  );
}

SleepHeartRateDelta calculateSleepHeartRateDelta({
  required NightlyHeartRateMetrics nightly,
  required SleepHeartRateBaseline baseline,
}) {
  if (!nightly.coverageSufficient ||
      nightly.sleepHrAvg == null ||
      !baseline.isEstablished ||
      baseline.baselineSleepHr == null) {
    return SleepHeartRateDelta(
      deltaSleepHr: null,
      baselineEstablished: baseline.isEstablished,
      coverageSufficient: nightly.coverageSufficient,
    );
  }
  return SleepHeartRateDelta(
    deltaSleepHr: nightly.sleepHrAvg! - baseline.baselineSleepHr!,
    baselineEstablished: true,
    coverageSufficient: true,
  );
}

double _median(List<double> sortedValues) {
  if (sortedValues.isEmpty) return 0;
  final middle = sortedValues.length ~/ 2;
  if (sortedValues.length.isOdd) return sortedValues[middle];
  return (sortedValues[middle - 1] + sortedValues[middle]) / 2;
}
