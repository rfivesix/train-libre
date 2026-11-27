import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'statistics_data_quality_policy.dart';

class DailyValuePoint {
  final DateTime day;
  final double value;

  const DailyValuePoint({required this.day, required this.value});
}

enum BodyNutritionInsightType {
  notEnoughData,
  stableWeightCaloriesUp,
  weightUpCaloriesUp,
  caloriesDownWeightNotYetChanged,
  weightDownCaloriesDown,
  mixed,
}

enum BodyNutritionTrendDirection { rising, falling, stable, unclear }

enum BodyNutritionRelationshipType {
  alignedCutLike,
  alignedBulkLike,
  stableMaintenanceLike,
  mixedOrUnclear,
  insufficientData,
}

enum BodyNutritionConfidence { high, moderate, low, insufficient }

class BodyNutritionTrendSnapshot {
  const BodyNutritionTrendSnapshot({
    required this.direction,
    required this.slopePerWeek,
    required this.netChange,
    required this.signalToNoise,
  });

  final BodyNutritionTrendDirection direction;
  final double? slopePerWeek;
  final double? netChange;
  final double signalToNoise;
}

class BodyNutritionDataQualitySummary {
  const BodyNutritionDataQualitySummary({
    required this.spanDays,
    required this.weightDays,
    required this.calorieDays,
    required this.overlapDays,
    required this.weightCoverage,
    required this.calorieCoverage,
    required this.overlapCoverage,
    required this.weightLargestGapDays,
    required this.calorieLargestGapDays,
  });

  final int spanDays;
  final int weightDays;
  final int calorieDays;
  final int overlapDays;
  final double weightCoverage;
  final double calorieCoverage;
  final double overlapCoverage;
  final int weightLargestGapDays;
  final int calorieLargestGapDays;
}

class BodyNutritionAnalyticsResult {
  final DateTimeRange range;
  final int totalDays;
  final double? currentWeightKg;
  final double? weightChangeKg;
  final double avgDailyCalories;
  final int weightDays;
  final int loggedCalorieDays;
  final List<DailyValuePoint> weightDaily;
  final List<DailyValuePoint> smoothedWeight;
  final List<DailyValuePoint> caloriesDaily;
  final Set<DateTime> incompleteNutritionDays;
  final List<DailyValuePoint> smoothedCalories;
  final List<DailyValuePoint> normalizedWeightTrend;
  final List<DailyValuePoint> normalizedCaloriesTrend;
  final DateTimeRange? normalizedTrendRange;
  final BodyNutritionTrendSnapshot weightTrend;
  final BodyNutritionTrendSnapshot calorieTrend;
  final BodyNutritionRelationshipType relationship;
  final BodyNutritionConfidence confidence;
  final BodyNutritionDataQualitySummary qualitySummary;
  final BodyNutritionInsightType insightType;
  final StatisticsDataQualityAssessment insightDataQuality;

  const BodyNutritionAnalyticsResult({
    required this.range,
    required this.totalDays,
    required this.currentWeightKg,
    required this.weightChangeKg,
    required this.avgDailyCalories,
    required this.weightDays,
    required this.loggedCalorieDays,
    required this.weightDaily,
    required this.smoothedWeight,
    required this.caloriesDaily,
    this.incompleteNutritionDays = const {},
    required this.smoothedCalories,
    this.normalizedWeightTrend = const [],
    this.normalizedCaloriesTrend = const [],
    this.normalizedTrendRange,
    required this.weightTrend,
    required this.calorieTrend,
    required this.relationship,
    required this.confidence,
    required this.qualitySummary,
    required this.insightType,
    required this.insightDataQuality,
  });

  bool get hasAnyData => weightDays > 0 || loggedCalorieDays > 0;

  bool get hasEnoughForInsight =>
      insightType != BodyNutritionInsightType.notEnoughData;

  bool get hasComparableTrend =>
      normalizedWeightTrend.isNotEmpty && normalizedCaloriesTrend.isNotEmpty;

  factory BodyNutritionAnalyticsResult.mockPreview(DateTimeRange range) {
    final startDay = DateTime.utc(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final endDay = DateTime.utc(range.end.year, range.end.month, range.end.day);
    final rawDays = endDay.difference(startDay).inDays + 1;
    final totalDays = math.max(7, rawDays);
    final effectiveRange = rawDays < 7
        ? DateTimeRange(
            start: startDay,
            end: startDay.add(const Duration(days: 6)),
          )
        : range;
    final sampleCount = math.min(totalDays, 45);
    final stepDays = sampleCount <= 1
        ? 1.0
        : (totalDays - 1) / (sampleCount - 1);

    final mockDailyWeight = List.generate(sampleCount, (i) {
      final offset = (i * stepDays).round().clamp(0, totalDays - 1);
      final progress = sampleCount <= 1 ? 0.0 : i / (sampleCount - 1);
      final wave = math.sin(progress * math.pi * 2.5) * 0.35;
      return DailyValuePoint(
        day: startDay.add(Duration(days: offset)),
        value: 80.2 - (progress * 1.5) + wave,
      );
    }, growable: false);

    final mockDailyCalories = List.generate(sampleCount, (i) {
      final offset = (i * stepDays).round().clamp(0, totalDays - 1);
      final progress = sampleCount <= 1 ? 0.0 : i / (sampleCount - 1);
      final wave = math.cos(progress * math.pi * 3.0) * 180.0;
      return DailyValuePoint(
        day: startDay.add(Duration(days: offset)),
        value: 2350.0 + (progress * 140.0) + wave,
      );
    }, growable: false);

    return BodyNutritionAnalyticsResult(
      range: effectiveRange,
      totalDays: totalDays,
      currentWeightKg: 78.7,
      weightChangeKg: -1.5,
      avgDailyCalories: 2420.0,
      weightDays: sampleCount,
      loggedCalorieDays: sampleCount,
      weightDaily: mockDailyWeight,
      smoothedWeight: mockDailyWeight,
      caloriesDaily: mockDailyCalories,
      smoothedCalories: mockDailyCalories,
      normalizedWeightTrend: mockDailyWeight,
      normalizedCaloriesTrend: mockDailyCalories,
      normalizedTrendRange: effectiveRange,
      weightTrend: const BodyNutritionTrendSnapshot(
        direction: BodyNutritionTrendDirection.falling,
        slopePerWeek: -0.35,
        netChange: -1.5,
        signalToNoise: 2.5,
      ),
      calorieTrend: const BodyNutritionTrendSnapshot(
        direction: BodyNutritionTrendDirection.rising,
        slopePerWeek: 70.0,
        netChange: 140.0,
        signalToNoise: 1.8,
      ),
      relationship: BodyNutritionRelationshipType.alignedCutLike,
      confidence: BodyNutritionConfidence.high,
      qualitySummary: BodyNutritionDataQualitySummary(
        spanDays: totalDays,
        weightDays: sampleCount,
        calorieDays: sampleCount,
        overlapDays: sampleCount,
        weightCoverage: 1.0,
        calorieCoverage: 1.0,
        overlapCoverage: 1.0,
        weightLargestGapDays: 0,
        calorieLargestGapDays: 0,
      ),
      insightType: BodyNutritionInsightType.weightDownCaloriesDown,
      insightDataQuality: const StatisticsDataQualityAssessment(
        hasSufficientData: true,
        reasonHook: '',
      ),
    );
  }
}
