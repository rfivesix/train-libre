import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_engine.dart';
import 'package:train_libre/features/statistics/domain/body_nutrition_analytics_models.dart';
import 'package:train_libre/features/analytics/domain/models/chart_data_point.dart';

void main() {
  group('BodyNutritionAnalyticsEngine trend summary', () {
    test('an incomplete date has no calorie point but keeps its weight', () {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 7);
      final excludedDate = DateTime.utc(2026, 1, 3);
      final result = BodyNutritionAnalyticsEngine.build(
        range: DateTimeRange(start: start, end: end),
        weightPoints: [ChartDataPoint(date: excludedDate, value: 80)],
        caloriesByDay: {
          for (var i = 0; i < 7; i++) DateTime.utc(2026, 1, 1 + i): 2000,
          excludedDate: 420,
        },
        incompleteDays: {DateTime(2026, 1, 3)},
      );

      expect(result.avgDailyCalories, 2000);
      expect(result.loggedCalorieDays, 6);
      expect(
        result.caloriesDaily.map((point) => point.day),
        isNot(contains(excludedDate)),
      );
      expect(
        result.smoothedCalories.map((point) => point.day),
        isNot(contains(excludedDate)),
      );
      expect(result.weightDaily.single.day, excludedDate);
      expect(result.weightDaily.single.value, 80);
    });
    test('classifies clear cut-like pattern as aligned', () {
      final start = DateTime.utc(2026, 1, 1);
      final range = DateTimeRange(start: start, end: DateTime.utc(2026, 2, 14));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          18,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 2)),
            value: 84.0 - (i * 0.22),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 45; i++)
            start.add(Duration(days: i)): 2500 - (i * 10.0),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.falling);
      expect(
        result.calorieTrend.direction,
        BodyNutritionTrendDirection.falling,
      );
      expect(result.relationship, BodyNutritionRelationshipType.alignedCutLike);
      expect(result.confidence != BodyNutritionConfidence.insufficient, isTrue);
    });

    test('classifies stable maintenance-like pattern', () {
      final start = DateTime.utc(2026, 3, 1);
      final range = DateTimeRange(start: start, end: DateTime.utc(2026, 4, 10));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          14,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 78.0 + ((i.isEven ? 1 : -1) * 0.05),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 41; i++)
            start.add(Duration(days: i)): 2200 + ((i.isEven ? 1 : -1) * 30),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.stable);
      expect(result.calorieTrend.direction, BodyNutritionTrendDirection.stable);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.stableMaintenanceLike,
      );
    });

    test('classifies clear bulk-like pattern as aligned', () {
      final start = DateTime.utc(2026, 5, 1);
      final range = DateTimeRange(start: start, end: DateTime.utc(2026, 6, 20));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          17,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 72.0 + (i * 0.18),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 51; i++)
            start.add(Duration(days: i)): 2350 + (i * 9.0),
        },
      );

      expect(result.weightTrend.direction, BodyNutritionTrendDirection.rising);
      expect(result.calorieTrend.direction, BodyNutritionTrendDirection.rising);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.alignedBulkLike,
      );
    });

    test('gates sparse data as insufficient', () {
      final start = DateTime.utc(2026, 7, 1);
      final range = DateTimeRange(start: start, end: DateTime.utc(2026, 7, 14));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: [
          ChartDataPoint(date: start.add(const Duration(days: 1)), value: 80),
          ChartDataPoint(
            date: start.add(const Duration(days: 12)),
            value: 79.8,
          ),
        ],
        caloriesByDay: {
          start.add(const Duration(days: 2)): 2000,
          start.add(const Duration(days: 10)): 2100,
        },
      );

      expect(result.confidence, BodyNutritionConfidence.insufficient);
      expect(
        result.relationship,
        BodyNutritionRelationshipType.insufficientData,
      );
    });

    test('classifies opposing trends as mixed or unclear', () {
      final start = DateTime.utc(2026, 8, 1);
      final range = DateTimeRange(start: start, end: DateTime.utc(2026, 9, 15));
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          18,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 2)),
            value: 80.0 + (i * 0.12),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 46; i++)
            start.add(Duration(days: i)): 2500 - (i * 8.5),
        },
      );

      expect(result.relationship, BodyNutritionRelationshipType.mixedOrUnclear);
    });

    test('normalized comparison starts both series from same baseline', () {
      final start = DateTime.utc(2026, 10, 1);
      final range = DateTimeRange(
        start: start,
        end: DateTime.utc(2026, 10, 30),
      );
      final result = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: List.generate(
          10,
          (i) => ChartDataPoint(
            date: start.add(Duration(days: i * 3)),
            value: 90.0 - (i * 0.15),
          ),
        ),
        caloriesByDay: {
          for (var i = 0; i < 30; i++)
            start.add(Duration(days: i)): 2500 - i * 8,
        },
      );

      expect(result.hasComparableTrend, isTrue);
      expect(result.normalizedWeightTrend.first.value, closeTo(0, 0.0001));
      expect(result.normalizedCaloriesTrend.first.value, closeTo(0, 0.0001));
      expect(result.normalizedTrendRange, isNotNull);
    });

    test('computeWeightChangeKg matches build weightChangeKg', () {
      final start = DateTime.utc(2026, 10, 24);
      final range = DateTimeRange(
        start: start,
        end: DateTime.utc(2026, 11, 22),
      );
      final weightPoints = [
        ChartDataPoint(date: start, value: 90.4),
        ChartDataPoint(date: start.add(const Duration(days: 1)), value: 89.8),
        ChartDataPoint(date: start.add(const Duration(days: 2)), value: 89.7),
        ChartDataPoint(date: start.add(const Duration(days: 15)), value: 89.2),
        ChartDataPoint(date: start.add(const Duration(days: 28)), value: 88.8),
        ChartDataPoint(date: start.add(const Duration(days: 29)), value: 88.6),
      ];

      final built = BodyNutritionAnalyticsEngine.build(
        range: range,
        weightPoints: weightPoints,
        caloriesByDay: const {},
      );
      final standalone = BodyNutritionAnalyticsEngine.computeWeightChangeKg(
        range: range,
        weightPoints: weightPoints,
      );

      expect(standalone, isNotNull);
      expect(standalone, closeTo(built.weightChangeKg!, 0.0001));
      // Smoothed trend change differs from raw endpoint delta (88.6 - 90.4 = -1.8).
      expect(standalone!, greaterThan(-1.8));
    });
  });
}
