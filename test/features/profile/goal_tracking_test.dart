import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/profile/domain/models/goal_progress.dart';
import 'package:train_libre/features/profile/domain/services/goal_trajectory_calculator.dart';
import 'package:train_libre/features/profile/domain/services/weekly_goal_review_service.dart';

void main() {
  group('GoalTrajectoryCalculator', () {
    test('calculateWeeklyRate calculates correct rate', () {
      final start = DateTime(2026, 1, 1);
      final target = start.add(const Duration(days: 70)); // 10 weeks
      final rate = GoalTrajectoryCalculator.calculateWeeklyRate(
        startWeight: 80.0,
        targetWeight: 75.0,
        startDate: start,
        targetDate: target,
      );

      expect(rate, closeTo(-0.5, 0.01));
    });

    test('calculateTargetDate calculates correct target date', () {
      final start = DateTime(2026, 1, 1);
      final targetDate = GoalTrajectoryCalculator.calculateTargetDate(
        startWeight: 80.0,
        targetWeight: 75.0,
        startDate: start,
        weeklyRateKg: -0.5,
      );

      // 5 kg at -0.5 kg/week = 10 weeks = 70 days
      expect(targetDate.difference(start).inDays, 70);
    });

    test('calculateTargetWeight calculates correct target weight', () {
      final start = DateTime(2026, 1, 1);
      final target = start.add(const Duration(days: 70)); // 10 weeks
      final weight = GoalTrajectoryCalculator.calculateTargetWeight(
        startWeight: 80.0,
        startDate: start,
        targetDate: target,
        weeklyRateKg: -0.5,
      );

      expect(weight, closeTo(75.0, 0.01));
    });

    test('isRateSafe validates safe boundaries', () {
      expect(GoalTrajectoryCalculator.isRateSafe(-0.5), isTrue);
      expect(GoalTrajectoryCalculator.isRateSafe(-1.0), isTrue);
      expect(GoalTrajectoryCalculator.isRateSafe(-2.0), isFalse);
      expect(GoalTrajectoryCalculator.isRateSafe(0.5), isTrue);
      expect(GoalTrajectoryCalculator.isRateSafe(1.0), isFalse);
    });
  });

  group('WeeklyGoalReviewService', () {
    final goal = Goal(
      id: 'test-goal',
      preset: GoalPreset.loseWeight,
      title: 'Weight Loss',
      status: GoalStatus.active,
      startDate: DateTime(2026, 1, 1),
      targetValue: 75.0,
      desiredWeeklyRateKg: -0.5,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('fails sufficiency gate when weigh-ins < 3', () {
      final eval = WeeklyGoalReviewService.evaluate(
        goal: goal,
        weightObservationCount: 2,
        loggedIntakeDaysCount: 6,
        observedRateKgPerWeek: -0.5,
        expectedRateKgPerWeek: -0.5,
        tdeeEstimate: 2400,
        currentCalories: 2000,
        engineRecommendedCalories: 1900,
        engineRecommendedProtein: 160,
        engineRecommendedCarbs: 200,
        engineRecommendedFat: 60,
      );

      expect(eval.isSufficiencyGateMet, isFalse);
      expect(eval.trajectoryStatus, 'calibrating');
      expect(eval.confidenceLevel, 'uncalibrated');
    });

    test('fails sufficiency gate when logged days < 4', () {
      final eval = WeeklyGoalReviewService.evaluate(
        goal: goal,
        weightObservationCount: 4,
        loggedIntakeDaysCount: 3,
        observedRateKgPerWeek: -0.5,
        expectedRateKgPerWeek: -0.5,
        tdeeEstimate: 2400,
        currentCalories: 2000,
        engineRecommendedCalories: 1900,
        engineRecommendedProtein: 160,
        engineRecommendedCarbs: 200,
        engineRecommendedFat: 60,
      );

      expect(eval.isSufficiencyGateMet, isFalse);
      expect(eval.trajectoryStatus, 'calibrating');
    });

    test('detects on track when divergence < 0.15 kg/week', () {
      final eval = WeeklyGoalReviewService.evaluate(
        goal: goal,
        weightObservationCount: 5,
        loggedIntakeDaysCount: 6,
        observedRateKgPerWeek: -0.45,
        expectedRateKgPerWeek: -0.50, // divergence 0.05 < 0.15
        tdeeEstimate: 2400,
        currentCalories: 2000,
        engineRecommendedCalories: 2000,
        engineRecommendedProtein: 160,
        engineRecommendedCarbs: 200,
        engineRecommendedFat: 60,
      );

      expect(eval.isSufficiencyGateMet, isTrue);
      expect(eval.trajectoryStatus, 'on_track');
      expect(eval.confidenceLevel, 'high');
    });

    test('detects slower rate when divergence >= 0.15 kg/week', () {
      final eval = WeeklyGoalReviewService.evaluate(
        goal: goal,
        weightObservationCount: 5,
        loggedIntakeDaysCount: 6,
        observedRateKgPerWeek: -0.20, // losing slower than -0.5
        expectedRateKgPerWeek: -0.50,
        tdeeEstimate: 2300,
        currentCalories: 2000,
        engineRecommendedCalories: 1850,
        engineRecommendedProtein: 160,
        engineRecommendedCarbs: 180,
        engineRecommendedFat: 55,
      );

      expect(eval.isSufficiencyGateMet, isTrue);
      expect(eval.trajectoryStatus, 'slower');
      expect(eval.recommendedCalories, 1850);
    });
  });

  group('GoalProgress', () {
    test('calculates correct progress percentage for weight loss', () {
      final goal = Goal(
        id: 'g1',
        preset: GoalPreset.loseWeight,
        title: 'Lose Weight',
        status: GoalStatus.active,
        startDate: DateTime(2026, 1, 1),
        targetValue: 75.0,
        desiredWeeklyRateKg: -0.5,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final progress = GoalProgress.calculate(
        goal: goal,
        baselineValue: 80.0,
        baselineDate: DateTime(2026, 1, 1),
        currentValue: 77.5,
        currentDate: DateTime(2026, 2, 1),
      );

      // Baseline: 80, Current: 77.5, Target: 75
      // Completed: 2.5 kg out of 5 kg = 50% (0.5)
      expect(progress.progressPercentage, closeTo(0.5, 0.01));
      expect(progress.remainingDistance, closeTo(2.5, 0.1));
      expect(progress.state, GoalProgressState.inProgress);
    });

    test('detects target met when current weight reaches target', () {
      final goal = Goal(
        id: 'g1',
        preset: GoalPreset.loseWeight,
        title: 'Lose Weight',
        status: GoalStatus.active,
        startDate: DateTime(2026, 1, 1),
        targetValue: 75.0,
        desiredWeeklyRateKg: -0.5,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final progress = GoalProgress.calculate(
        goal: goal,
        baselineValue: 80.0,
        baselineDate: DateTime(2026, 1, 1),
        currentValue: 74.8,
        currentDate: DateTime(2026, 3, 1),
      );

      expect(progress.isTargetMet, isTrue);
      expect(progress.state, GoalProgressState.targetMet);
      expect(progress.progressPercentage, 1.0);
    });
  });

  group('GoalEvent', () {
    test('serializes and deserializes occurredAt correctly', () {
      final now = DateTime.now();
      final event = GoalEvent(
        id: 'ev-1',
        goalId: 'g-1',
        eventType: 'created',
        occurredAt: now,
        createdAt: now,
      );

      final map = event.toMap();
      expect(map['occurred_at'], now.toIso8601String());

      final restored = GoalEvent.fromMap(map);
      expect(restored.occurredAt?.toIso8601String(), now.toIso8601String());
    });
  });
}
