import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/adaptive_diet_phase.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/rate_trajectory_controller.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_models.dart';

const _algorithmVersion = 'dual_loop_test';

void main() {
  const controller = RateTrajectoryController();

  group('RateTrajectoryController', () {
    test('requires compatible history before activating', () {
      final result = controller.evaluate(
        input: _input(slope: 0.17),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
      );

      expect(result.calories, 0);
      expect(result.status, 'inactive_no_compatible_history');
      expect(result.rateErrorKgPerWeek, closeTo(0.20, 0.0001));
    });

    test('activates after two same-sign errors and applies slew limit', () {
      final result = controller.evaluate(
        input: _input(slope: 0.17),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: _previous(
          goal: BodyweightGoal.gainWeight,
          targetRate: 0.37,
          slope: 0.18,
        ),
      );

      expect(result.status, 'active');
      expect(result.calories, 100);
    });

    test('caps correction and limits movement from previous correction', () {
      final result = controller.evaluate(
        input: _input(slope: -0.20),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: _previous(
          goal: BodyweightGoal.gainWeight,
          targetRate: 0.37,
          slope: 0.05,
          correction: 100,
        ),
      );

      expect(result.calories, 150);
    });

    test('supports negative corrections for excessive loss or gain rates', () {
      final result = controller.evaluate(
        input: _input(slope: -0.15),
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -0.50,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: _previous(
          goal: BodyweightGoal.loseWeight,
          targetRate: -0.50,
          slope: -0.20,
        ),
      );

      expect(result.status, 'active');
      expect(result.calories, -100);
    });

    test('deadband and sign reversals suppress correction', () {
      final deadband = controller.evaluate(
        input: _input(slope: 0.34),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: _previous(
          goal: BodyweightGoal.gainWeight,
          targetRate: 0.37,
          slope: 0.20,
        ),
      );
      final reversal = controller.evaluate(
        input: _input(slope: 0.50),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: _previous(
          goal: BodyweightGoal.gainWeight,
          targetRate: 0.37,
          slope: 0.20,
        ),
      );

      expect(deadband.status, 'inactive_deadband');
      expect(reversal.status, 'inactive_not_persistent');
      expect(deadband.calories, 0);
      expect(reversal.calories, 0);
    });

    test('sparse data, phase changes, and legacy versions suppress correction',
        () {
      final previous = _previous(
        goal: BodyweightGoal.gainWeight,
        targetRate: 0.37,
        slope: 0.18,
      );
      final sparse = controller.evaluate(
        input: _input(slope: 0.17, intakeDays: 6),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: _maturePhase,
        previousRecommendation: previous,
      );
      final phaseChange = controller.evaluate(
        input: _input(slope: 0.17),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: _algorithmVersion,
        phaseContext: const BayesianObservationPhaseContext(
          confirmedPhase: AdaptiveDietPhase.bulk,
          confirmedPhaseAgeDays: 30,
          pendingPhase: AdaptiveDietPhase.maintain,
          pendingPhaseAgeDays: 2,
        ),
        previousRecommendation: previous,
      );
      final legacy = controller.evaluate(
        input: _input(slope: 0.17),
        goal: BodyweightGoal.gainWeight,
        targetRateKgPerWeek: 0.37,
        algorithmVersion: 'new_version',
        phaseContext: _maturePhase,
        previousRecommendation: previous,
      );

      expect(sparse.status, 'inactive_sparse_data');
      expect(phaseChange.status, 'inactive_phase_transition');
      expect(legacy.status, 'inactive_no_compatible_history');
    });

    test('legacy recommendation JSON defaults controller fields safely', () {
      final encoded = _previous(
        goal: BodyweightGoal.maintainWeight,
        targetRate: 0,
        slope: 0,
      ).toJson()
        ..remove('trajectoryCorrectionCalories')
        ..remove('trajectoryRateErrorKgPerWeek')
        ..remove('trajectoryCorrectionStatus');

      final decoded = NutritionRecommendation.fromJson(encoded);

      expect(decoded.trajectoryCorrectionCalories, 0);
      expect(decoded.trajectoryRateErrorKgPerWeek, isNull);
      expect(decoded.trajectoryCorrectionStatus, 'inactive');
    });
  });
}

const _maturePhase = BayesianObservationPhaseContext(
  confirmedPhase: AdaptiveDietPhase.bulk,
  confirmedPhaseAgeDays: 30,
  pendingPhase: null,
  pendingPhaseAgeDays: null,
);

RecommendationGenerationInput _input({
  required double slope,
  int windowDays = 14,
  int intakeDays = 14,
  int weightLogs = 14,
}) {
  return RecommendationGenerationInput(
    windowStart: DateTime(2026, 4, 1),
    windowEnd: DateTime(2026, 4, 14),
    windowDays: windowDays,
    weightLogCount: weightLogs,
    intakeLoggedDays: intakeDays,
    smoothedWeightSlopeKgPerWeek: slope,
    avgLoggedCalories: 3200,
    currentWeightKg: 88,
    priorMaintenanceCalories: 2750,
    activeTargetCalories: 3150,
  );
}

NutritionRecommendation _previous({
  required BodyweightGoal goal,
  required double targetRate,
  required double slope,
  int correction = 0,
}) {
  return NutritionRecommendation(
    recommendedCalories: 3200,
    recommendedProteinGrams: 180,
    recommendedCarbsGrams: 400,
    recommendedFatGrams: 80,
    estimatedMaintenanceCalories: 2790,
    goal: goal,
    targetRateKgPerWeek: targetRate,
    confidence: RecommendationConfidence.high,
    warningState: RecommendationWarningState.none,
    generatedAt: DateTime(2026, 4, 14),
    windowStart: DateTime(2026, 4, 1),
    windowEnd: DateTime(2026, 4, 14),
    algorithmVersion: _algorithmVersion,
    inputSummary: RecommendationInputSummary(
      windowDays: 14,
      weightLogCount: 14,
      intakeLoggedDays: 14,
      smoothedWeightSlopeKgPerWeek: slope,
      avgLoggedCalories: 3150,
    ),
    baselineCalories: 3150,
    dueWeekKey: '2026-04-13',
    trajectoryCorrectionCalories: correction,
    trajectoryRateErrorKgPerWeek: targetRate - slope,
    trajectoryCorrectionStatus: correction == 0 ? 'inactive' : 'active',
  );
}
