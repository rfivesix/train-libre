/// A discrete HealthKit SDNN measurement, expressed in milliseconds.
class HrvSample {
  const HrvSample({
    required this.startUtc,
    required this.endUtc,
    required this.sdnnMs,
    required this.sourceId,
    required this.nativeId,
  });
  final DateTime startUtc;
  final DateTime endUtc;
  final double sdnnMs;
  final String sourceId;
  final String nativeId;
}

enum HrvState { available, noData, disabled, unavailable, queryFailed }

class HrvSummary {
  const HrvSummary({required this.state, required this.samples});
  final HrvState state;
  final List<HrvSample> samples;
  int get sampleCount => samples.length;
  double? get averageMs => samples.isEmpty
      ? null
      : samples.fold<double>(0, (sum, s) => sum + s.sdnnMs) / samples.length;
}
