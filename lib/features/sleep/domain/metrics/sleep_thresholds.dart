import 'package:flutter/material.dart';

class SleepDurationThresholds {
  const SleepDurationThresholds._();

  static const double criticalLowerHours = 5.0;
  static const double optimalLowerHours = 7.0;
  static const double optimalUpperHours = 9.0;
  static const double criticalUpperHours = 10.5;

  static const int minDisplayHours = 0;
  static const int maxDisplayHours = 12;

  static Color getColorForHours(double hours) {
    if (hours < criticalLowerHours || hours > criticalUpperHours) {
      return Colors.red;
    }
    if (hours >= optimalLowerHours && hours <= optimalUpperHours) {
      return Colors.green;
    }
    return Colors.orange;
  }
}

class HeartRateThresholds {
  const HeartRateThresholds._();

  /// Deviation from baseline (in BPM) that is considered optimal.
  static const double optimalDeviation = 3.0;

  /// Deviation from baseline (in BPM) that is considered a warning.
  /// Beyond this, it is considered critical.
  static const double warningDeviation = 5.0;

  static Color getColorForDeviation(double deviation) {
    final absDev = deviation.abs();
    if (absDev <= optimalDeviation) {
      return Colors.green;
    }
    if (absDev <= warningDeviation) {
      return Colors.orange;
    }
    return Colors.red;
  }
}
