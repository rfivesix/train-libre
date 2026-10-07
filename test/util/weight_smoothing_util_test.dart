import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/util/weight_smoothing_util.dart';

void main() {
  group('WeightSmoothingUtil', () {
    test('returns empty list for empty source', () {
      expect(WeightSmoothingUtil.calculateEwma([]), isEmpty);
    });

    test('returns single point unchanged', () {
      final point = ChartDataPoint(date: DateTime(2026, 1, 1), value: 80.0);
      final result = WeightSmoothingUtil.calculateEwma([point]);
      expect(result.length, 1);
      expect(result.first.value, 80.0);
    });

    test('calculates EWMA with alpha 0.35 in chronological order', () {
      final d1 = DateTime(2026, 1, 1);
      final d2 = DateTime(2026, 1, 2);
      final d3 = DateTime(2026, 1, 3);

      final points = [
        ChartDataPoint(date: d2, value: 84.0),
        ChartDataPoint(date: d1, value: 85.0),
        ChartDataPoint(date: d3, value: 86.0),
      ];

      final smoothed = WeightSmoothingUtil.calculateEwma(points);

      expect(smoothed.length, 3);
      // d1 (first chronologically)
      expect(smoothed[0].date, d1);
      expect(smoothed[0].value, 85.0);

      // d2: 0.35 * 84.0 + 0.65 * 85.0 = 29.4 + 55.25 = 84.65
      expect(smoothed[1].date, d2);
      expect(smoothed[1].value, closeTo(84.65, 0.0001));

      // d3: 0.35 * 86.0 + 0.65 * 84.65 = 30.1 + 55.0225 = 85.1225
      expect(smoothed[2].date, d3);
      expect(smoothed[2].value, closeTo(85.1225, 0.0001));
    });

    test('calculateEwmaDailyPoints smoothes DailyValuePoint series identically',
        () {
      final d1 = DateTime.utc(2026, 1, 1);
      final d2 = DateTime.utc(2026, 1, 2);
      final d3 = DateTime.utc(2026, 1, 3);

      final points = [
        DailyValuePoint(day: d2, value: 84.0),
        DailyValuePoint(day: d1, value: 85.0),
        DailyValuePoint(day: d3, value: 86.0),
      ];

      final smoothed = WeightSmoothingUtil.calculateEwmaDailyPoints(points);

      expect(smoothed.length, 3);
      expect(smoothed[0].day, d1);
      expect(smoothed[0].value, 85.0);
      expect(smoothed[1].day, d2);
      expect(smoothed[1].value, closeTo(84.65, 0.0001));
      expect(smoothed[2].day, d3);
      expect(smoothed[2].value, closeTo(85.1225, 0.0001));
    });
  });
}
