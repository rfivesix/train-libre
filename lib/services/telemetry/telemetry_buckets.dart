// lib/services/telemetry/telemetry_buckets.dart

/// Utility functions to group raw metrics into coarse, anonymous buckets
/// to prevent fingerprinting or capturing sensitive granular user data.
abstract class TelemetryBuckets {
  /// Converts a workout or process duration into a coarse bucket.
  static String getDurationBucket(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return '<15min';
    if (minutes < 30) return '15-30min';
    if (minutes < 60) return '30-60min';
    return '>60min';
  }

  /// Converts exercise count into a coarse count bucket.
  static String getExerciseCountBucket(int count) {
    if (count <= 0) return '0';
    if (count <= 3) return '1-3';
    if (count <= 7) return '4-7';
    if (count <= 12) return '8-12';
    return '13+';
  }

  /// Converts request or processing latency into a coarse bucket.
  static String getLatencyBucket(Duration latency) {
    final ms = latency.inMilliseconds;
    if (ms < 2000) return '<2s';
    if (ms < 5000) return '2-5s';
    if (ms < 10000) return '5-10s';
    return '>10s';
  }

  /// Converts voice recording duration into a coarse bucket.
  static String getVoiceDurationBucket(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 5) return '<5s';
    if (seconds < 15) return '5-15s';
    if (seconds < 30) return '15-30s';
    return '>30s';
  }

  /// Converts food item count into a coarse bucket.
  static String getItemCountBucket(int count) {
    if (count <= 0) return '0';
    if (count <= 2) return '1-2';
    if (count <= 5) return '3-5';
    return '6+';
  }

  /// Converts measurement or log observation count into a coarse count bucket.
  static String getObservationCountBucket(int count) {
    if (count <= 0) return '0';
    if (count <= 2) return '1-2';
    if (count <= 5) return '3-5';
    return '6+';
  }

  /// Converts goal lifetime or duration into coarse time buckets.
  static String getGoalDurationBucket(Duration duration) {
    final days = duration.inDays;
    if (days < 7) return '<7d';
    if (days < 28) return '1-4w';
    if (days < 90) return '1-3m';
    if (days < 180) return '3-6m';
    return '>6m';
  }
}
