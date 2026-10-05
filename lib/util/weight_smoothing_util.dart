import '../features/analytics/domain/models/chart_data_point.dart';
import '../features/statistics/domain/body_nutrition_analytics_models.dart';

/// Utility for exponential smoothing of body weight time series.
///
/// Uses Exponentially Weighted Moving Average (EWMA) with alpha = 0.35,
/// matching the exact formula used by Train Libre's Adaptive TDEE Engine.
class WeightSmoothingUtil {
  /// Default exponential smoothing factor matching the Adaptive TDEE engine.
  static const double defaultAlpha = 0.35;

  /// Calculates an EWMA smoothed series from [source] data points.
  ///
  /// Points are sorted chronologically before smoothing.
  /// The returned list has the same length and timestamps as [source].
  static List<ChartDataPoint> calculateEwma(
    List<ChartDataPoint> source, {
    double alpha = defaultAlpha,
  }) {
    if (source.isEmpty) return const [];
    if (source.length == 1) return List.of(source);

    final sorted = List<ChartDataPoint>.from(source)
      ..sort((a, b) => a.date.compareTo(b.date));

    final smoothed = <ChartDataPoint>[];
    var previous = sorted.first.value;

    for (final point in sorted) {
      final next = (alpha * point.value) + ((1.0 - alpha) * previous);
      smoothed.add(ChartDataPoint(date: point.date, value: next));
      previous = next;
    }

    return smoothed;
  }

  /// Calculates an EWMA smoothed series from [source] daily value points.
  ///
  /// Points are sorted chronologically by [DailyValuePoint.day] before smoothing.
  /// The returned list has the same length and days as [source].
  static List<DailyValuePoint> calculateEwmaDailyPoints(
    List<DailyValuePoint> source, {
    double alpha = defaultAlpha,
  }) {
    if (source.isEmpty) return const [];
    if (source.length == 1) return List.of(source);

    final sorted = List<DailyValuePoint>.from(source)
      ..sort((a, b) => a.day.compareTo(b.day));

    final smoothed = <DailyValuePoint>[];
    var previous = sorted.first.value;

    for (final point in sorted) {
      final next = (alpha * point.value) + ((1.0 - alpha) * previous);
      smoothed.add(DailyValuePoint(day: point.day, value: next));
      previous = next;
    }

    return smoothed;
  }
}
