// lib/features/profile/domain/services/weekly_goal_review_service.dart

import 'dart:math' as math;

import '../models/goal_model.dart';
import 'goal_trajectory_calculator.dart';

class WeeklyGoalTrajectoryAssessmentService {
  static GoalReviewAssessment evaluate({
    required Goal goal,
    required DateTime baselineDate,
    required double baselineValue,
    required DateTime reviewDate,
    required double? currentSmoothedValue,
    required double? recentRateKgPerWeek,
    required double? operatingRateKgPerWeek,
    required int weightObservationCount,
    required int nutritionLoggedDays,
    required double? averageLoggedCalories,
    required int? currentCalories,
  }) {
    final target = goal.targetValue;
    final targetDate = goal.targetDate;
    final elapsedWeeks = math.max(
      reviewDate.difference(baselineDate).inDays / 7.0,
      0.0,
    );

    double? plannedRate = goal.desiredWeeklyRateKg;
    double? totalPlannedWeeks;
    if (target != null && targetDate != null) {
      final totalWeeks = targetDate.difference(baselineDate).inDays / 7.0;
      if (totalWeeks > 0) {
        totalPlannedWeeks = totalWeeks;
        plannedRate = (target - baselineValue) / totalWeeks;
      }
    }

    final direction = target != null && target != baselineValue
        ? (target - baselineValue).sign
        : (plannedRate ?? 0).sign;
    final trajectoryWeeks = totalPlannedWeeks == null
        ? elapsedWeeks
        : math.min(elapsedWeeks, totalPlannedWeeks);
    final expectedValue = plannedRate == null
        ? null
        : baselineValue + (plannedRate * trajectoryWeeks);
    final overallRate = currentSmoothedValue == null || elapsedWeeks < 1
        ? null
        : (currentSmoothedValue - baselineValue) / elapsedWeeks;

    double? gap;
    String overallStatus = 'calibrating';
    if (currentSmoothedValue != null && expectedValue != null) {
      gap = direction == 0
          ? -(currentSmoothedValue - expectedValue).abs()
          : direction * (currentSmoothedValue - expectedValue);
      final tolerance = math.max(0.3, (plannedRate ?? 0).abs() * 0.75);
      final targetMet = target != null &&
          direction != 0 &&
          direction * (currentSmoothedValue - target) >= 0;
      if (targetMet) {
        overallStatus = 'target_reached';
      } else if (targetDate != null && !reviewDate.isBefore(targetDate)) {
        overallStatus = 'target_date_needs_review';
      } else if (gap < -tolerance) {
        overallStatus = 'behind';
      } else if (gap > tolerance) {
        overallStatus = 'ahead';
      } else {
        overallStatus = 'on_trajectory';
      }
    }

    final rateDifference = recentRateKgPerWeek == null || plannedRate == null
        ? null
        : direction == 0
            ? recentRateKgPerWeek.abs() - plannedRate.abs()
            : direction * (recentRateKgPerWeek - plannedRate);
    String momentum = 'unclear';
    if (rateDifference != null) {
      if (rateDifference.abs() <
          WeeklyGoalReviewService.minDivergenceThresholdKgPerWeek) {
        momentum = 'matching_plan';
      } else if (overallStatus == 'behind') {
        momentum =
            rateDifference > 0 ? 'catching_up' : 'falling_further_behind';
      } else {
        momentum = rateDifference > 0 ? 'moving_faster' : 'moving_slower';
      }
    }

    double? requiredRate;
    if (target != null && targetDate != null && currentSmoothedValue != null) {
      final remainingWeeks = targetDate.difference(reviewDate).inDays / 7.0;
      if (remainingWeeks > 0) {
        requiredRate = (target - currentSmoothedValue) / remainingWeeks;
      }
    }

    DateTime? projectedDate;
    if (target != null &&
        currentSmoothedValue != null &&
        operatingRateKgPerWeek != null &&
        operatingRateKgPerWeek.abs() >= 0.05 &&
        (target - currentSmoothedValue).sign == operatingRateKgPerWeek.sign) {
      final weeks = (target - currentSmoothedValue) / operatingRateKgPerWeek;
      projectedDate = reviewDate.add(Duration(days: (weeks * 7).round()));
    }

    final sufficient = weightObservationCount >=
            WeeklyGoalReviewService.minWeightObservationsForReview &&
        nutritionLoggedDays >=
            WeeklyGoalReviewService.minLoggedIntakeDaysForReview &&
        recentRateKgPerWeek != null;
    final requiredRateIsSafe = requiredRate == null ||
        GoalTrajectoryCalculator.isRateSafe(requiredRate);
    final calorieTolerance = math.max(100.0, (currentCalories ?? 0) * 0.05);
    final intakeExplainsGap = averageLoggedCalories != null &&
        currentCalories != null &&
        ((direction > 0 &&
                averageLoggedCalories < currentCalories - calorieTolerance) ||
            (direction < 0 &&
                averageLoggedCalories > currentCalories + calorieTolerance));

    String nutritionAction;
    if (!sufficient) {
      nutritionAction = 'insufficient_data';
    } else if (!requiredRateIsSafe ||
        overallStatus == 'target_date_needs_review') {
      nutritionAction = 'trajectory_change_needed';
    } else if (overallStatus == 'behind' && intakeExplainsGap) {
      nutritionAction = 'keep_targets_intake_differs';
    } else if (overallStatus == 'behind' ||
        (overallStatus == 'ahead' && momentum == 'moving_faster')) {
      nutritionAction = 'adjust_targets';
    } else {
      nutritionAction = 'keep_targets';
    }

    return GoalReviewAssessment(
      overallStatus: overallStatus,
      recentMomentumStatus: momentum,
      baselineValue: baselineValue,
      expectedValue: expectedValue,
      currentSmoothedValue: currentSmoothedValue,
      trajectoryGap: gap,
      plannedRateKgPerWeek: plannedRate,
      recentRateKgPerWeek: recentRateKgPerWeek,
      overallRateKgPerWeek: overallRate,
      requiredRemainingRateKgPerWeek: requiredRate,
      projectedTargetDate: projectedDate,
      weightObservationCount: weightObservationCount,
      nutritionLoggedDays: nutritionLoggedDays,
      averageLoggedCalories: averageLoggedCalories,
      dataQuality: sufficient ? 'sufficient' : 'insufficient',
      nutritionAction: nutritionAction,
    );
  }
}

class WeeklyReviewEvaluation {
  final String
      trajectoryStatus; // 'on_track', 'slower', 'faster', 'calibrating'
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
    final isSufficient =
        weightObservationCount >= minWeightObservationsForReview &&
            loggedIntakeDaysCount >= minLoggedIntakeDaysForReview;

    if (!isSufficient || observedRateKgPerWeek == null) {
      final missing = <String>[];
      if (weightObservationCount < minWeightObservationsForReview) {
        missing.add(
            '${minWeightObservationsForReview - weightObservationCount} Wiegung(en)');
      }
      if (loggedIntakeDaysCount < minLoggedIntakeDaysForReview) {
        missing.add(
            '${minLoggedIntakeDaysForReview - loggedIntakeDaysCount} Kalorientag(e)');
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
        explanation:
            'Train Libre kalibriert sich noch auf deine Daten. Für eine verlässliche wöchentliche Empfehlung fehlen in den letzten 7 Tagen noch ${missing.join(' und ')}. Bitte führe dein Tagebuch einfach wie gewohnt weiter.',
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
        explanation:
            'Dein Gewichtsverlauf ist voll auf Zielkurs (Trend: ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche vs. Soll: ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche). Eine Kalorienanpassung ist aktuell nicht erforderlich.',
      );
    }

    // Significant divergence detected
    final isLosingGoal = goal.preset == GoalPreset.loseWeight || targetRate < 0;
    final isGainingGoal =
        goal.preset == GoalPreset.gainWeight || targetRate > 0;

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
      explanation =
          'Dein Trend verläuft mit ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche etwas langsamer als die geplante Trajektorie von ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche. Dein geschätzter Verbrauch (TDEE) liegt bei ca. ${tdeeEstimate?.round() ?? 2500} kcal. Eine moderate Kalorienanpassung kann helfen, die Trajektorie einzuhalten.';
    } else {
      explanation =
          'Dein Trend verläuft mit ${observedRateKgPerWeek >= 0 ? '+' : ''}${observedRateKgPerWeek.toStringAsFixed(2)} kg/Woche schneller als die geplante Trajektorie von ${targetRate >= 0 ? '+' : ''}${targetRate.toStringAsFixed(2)} kg/Woche. Dein geschätzter Verbrauch (TDEE) liegt bei ca. ${tdeeEstimate?.round() ?? 2500} kcal. Um ein zu extremes Defizit oder ungesunden Gewichtsverlust zu vermeiden, wird eine leichte Anhebung empfohlen.';
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
