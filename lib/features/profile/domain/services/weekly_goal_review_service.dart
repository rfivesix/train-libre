// lib/features/profile/domain/services/weekly_goal_review_service.dart

import '../models/goal_model.dart';

class WeeklyReviewEvaluation {
  final String trajectoryStatus; // 'on_track', 'slower', 'faster', 'calibrating'
  final String confidenceLevel; // 'high', 'moderate', 'low', 'uncalibrated'
  final bool isSufficiencyGateMet;
  final int weightObservationCount;
  final int loggedIntakeDaysCount;
  final double? observedRateKgPerWeek;
  final double? targetRateKgPerWeek;
  final double? rateDivergenceKgPerWeek;
  final double? tdeeEstimate;
  final int? currentCalories;
  final int? recommendedCalories;
  final int? recommendedProtein;
  final int? recommendedCarbs;
  final int? recommendedFat;
  final String explanation;

  const WeeklyReviewEvaluation({
    required this.trajectoryStatus,
    required this.confidenceLevel,
    required this.isSufficiencyGateMet,
    required this.weightObservationCount,
    required this.loggedIntakeDaysCount,
    this.observedRateKgPerWeek,
    this.targetRateKgPerWeek,
    this.rateDivergenceKgPerWeek,
    this.tdeeEstimate,
    this.currentCalories,
    this.recommendedCalories,
    this.recommendedProtein,
    this.recommendedCarbs,
    this.recommendedFat,
    required this.explanation,
  });
}

class WeeklyGoalReviewService {
  static const int minWeightObservationsForReview = 3;
  static const int minLoggedIntakeDaysForReview = 4;
  static const double minDivergenceThresholdKgPerWeek = 0.15;

  /// Evaluates a 7-day observation window against the active goal.
  static WeeklyReviewEvaluation evaluate({
    required Goal goal,
    required int weightObservationCount,
    required int loggedIntakeDaysCount,
    required double? observedRateKgPerWeek,
    required double? expectedRateKgPerWeek,
    required double? tdeeEstimate,
    required int? currentCalories,
    required int? engineRecommendedCalories,
    required int? engineRecommendedProtein,
    required int? engineRecommendedCarbs,
    required int? engineRecommendedFat,
  }) {
    // 1. Check Sufficiency Gate
    final isSufficient = weightObservationCount >= minWeightObservationsForReview &&
        loggedIntakeDaysCount >= minLoggedIntakeDaysForReview;

    if (!isSufficient || observedRateKgPerWeek == null) {
      final missing = <String>[];
      if (weightObservationCount < minWeightObservationsForReview) {
        missing.add('${minWeightObservationsForReview - weightObservationCount} Wiegung(en)');
      }
      if (loggedIntakeDaysCount < minLoggedIntakeDaysForReview) {
        missing.add('${minLoggedIntakeDaysForReview - loggedIntakeDaysCount} Kalorientag(e)');
      }

      return WeeklyReviewEvaluation(
        trajectoryStatus: 'calibrating',
        confidenceLevel: 'uncalibrated',
        isSufficiencyGateMet: false,
        weightObservationCount: weightObservationCount,
        loggedIntakeDaysCount: loggedIntakeDaysCount,
        observedRateKgPerWeek: observedRateKgPerWeek,
        targetRateKgPerWeek: expectedRateKgPerWeek,
        tdeeEstimate: tdeeEstimate,
        currentCalories: currentCalories,
        explanation: 'Train Libre kalibriert sich noch auf deine Daten. Für eine verlässliche wöchentliche Empfehlung fehlen in den letzten 7 Tagen noch ${missing.join(' und ')}. Bitte führe dein Tagebuch einfach wie gewohnt weiter.',
      );
    }

    final targetRate = expectedRateKgPerWeek ?? goal.desiredWeeklyRateKg ?? 0.0;
    final divergence = (observedRateKgPerWeek - targetRate).abs();

    String confidence;
    if (weightObservationCount >= 5 && loggedIntakeDaysCount >= 6) {
      confidence = 'high';
    } else if (weightObservationCount >= 4 && loggedIntakeDaysCount >= 5) {
      confidence = 'moderate';
    } else {
      confidence = 'low';
    }

    // 2. Check Divergence Gate
    if (divergence < minDivergenceThresholdKgPerWeek) {
      // On track: divergence is within normal physiological fluctuation.
      return WeeklyReviewEvaluation(
        trajectoryStatus: 'on_track',
        confidenceLevel: confidence,
        isSufficiencyGateMet: true,
        weightObservationCount: weightObservationCount,
        loggedIntakeDaysCount: loggedIntakeDaysCount,
        observedRateKgPerWeek: observedRateKgPerWeek,
        targetRateKgPerWeek: targetRate,
        rateDivergenceKgPerWeek: divergence,
        tdeeEstimate: tdeeEstimate,
        currentCalories: currentCalories,
        recommendedCalories: currentCalories, // Keep current calories
        recommendedProtein: engineRecommendedProtein,
        recommendedCarbs: engineRecommendedCarbs,
        recommendedFat: engineRecommendedFat,
        explanation: 'Dein Gewichtsverlauf ist voll auf Zielkurs (Trend: ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche vs. Soll: ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche). Eine Kalorienanpassung ist aktuell nicht erforderlich.',
      );
    }

    // Significant divergence detected
    final isLosingGoal = goal.preset == GoalPreset.loseWeight || targetRate < 0;
    final isGainingGoal = goal.preset == GoalPreset.gainWeight || targetRate > 0;

    bool isSlower;
    if (isLosingGoal) {
      // Expected: e.g. -0.5. Observed: e.g. -0.2 -> slower loss
      isSlower = observedRateKgPerWeek > targetRate;
    } else if (isGainingGoal) {
      // Expected: e.g. +0.3. Observed: e.g. +0.1 -> slower gain
      isSlower = observedRateKgPerWeek < targetRate;
    } else {
      // Maintenance: drifted outside tolerance
      isSlower = observedRateKgPerWeek.abs() > targetRate.abs();
    }

    final status = isSlower ? 'slower' : 'faster';

    String explanation;
    if (isSlower) {
      explanation = 'Dein Trend verläuft mit ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche etwas langsamer als die geplante Trajektorie von ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche. Dein geschätzter Verbrauch (TDEE) liegt bei ca. ${tdeeEstimate?.round() ?? 2500} kcal. Eine moderate Kalorienanpassung kann helfen, die Trajektorie einzuhalten.';
    } else {
      explanation = 'Dein Trend verläuft mit ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche schneller als die geplante Trajektorie von ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche. Dein geschätzter Verbrauch (TDEE) liegt bei ca. ${tdeeEstimate?.round() ?? 2500} kcal. Um ein zu extremes Defizit oder ungesunden Gewichtsverlust zu vermeiden, wird eine leichte Anhebung empfohlen.';
    }

    return WeeklyReviewEvaluation(
      trajectoryStatus: status,
      confidenceLevel: confidence,
      isSufficiencyGateMet: true,
      weightObservationCount: weightObservationCount,
      loggedIntakeDaysCount: loggedIntakeDaysCount,
      observedRateKgPerWeek: observedRateKgPerWeek,
      targetRateKgPerWeek: targetRate,
      rateDivergenceKgPerWeek: divergence,
      tdeeEstimate: tdeeEstimate,
      currentCalories: currentCalories,
      recommendedCalories: engineRecommendedCalories,
      recommendedProtein: engineRecommendedProtein,
      recommendedCarbs: engineRecommendedCarbs,
      recommendedFat: engineRecommendedFat,
      explanation: explanation,
    );
  }
}
