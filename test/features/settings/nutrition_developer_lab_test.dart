// test/features/settings/nutrition_developer_lab_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/profile/domain/models/goal_model.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/canonical_scenarios.dart';
import 'package:train_libre/features/settings/presentation/developer_lab/nutrition_sandbox_state.dart';

void main() {
  group('NutritionSandboxState', () {
    test('initializes with default valid parameters and derived pace', () {
      final state = NutritionSandboxState();
      expect(state.preset, GoalPreset.loseWeight);
      expect(state.baselineWeightKg, 85.0);
      expect(state.targetWeightKg, 78.0);
      expect(state.totalPlannedWeeks, 12);
      expect(state.desiredWeeklyRateKg, closeTo(0.58, 0.01));
    });

    test('recalculates derived pace when target weight or weeks change', () {
      final state = NutritionSandboxState();
      state.setTargetWeight(75.0); // delta = 10 kg
      state.setTotalPlannedWeeks(10); // 10 kg / 10 weeks = 1.0 kg/wk
      expect(state.desiredWeeklyRateKg, closeTo(1.0, 0.01));
    });

    test('reset restores the canonical sandbox baseline', () {
      final state = NutritionSandboxState();
      state.setTargetWeight(70);
      state.setCurrentCalories(1800);
      state.setWeightObservationCount(1);

      state.reset();

      expect(state.baselineWeightKg, 85.0);
      expect(state.targetWeightKg, 78.0);
      expect(state.currentCalories, 2150);
      expect(state.weightObservationCount, 5);
      expect(state.desiredWeeklyRateKg, closeTo(0.58, 0.01));
    });

    test('evaluates assessment live and produces synthetic models', () {
      final state = NutritionSandboxState();
      final assessment = state.evaluateAssessment();
      expect(assessment.overallStatus, isNotEmpty);
      expect(assessment.recentMomentumStatus, isNotEmpty);

      final goal = state.buildSyntheticGoal();
      expect(goal.status, GoalStatus.active);
      expect(goal.isNutritionDriver, isTrue);

      final review = state.buildSyntheticReviewRecord();
      expect(review.status, 'pending');
      expect(review.algorithmVersion, 'weekly_goal_review_2_0');
      expect(review.assessment, isNotNull);
    });
  });

  group('CanonicalNutritionScenarios', () {
    test('all 8 canonical scenarios match their expected evaluation states',
        () {
      final state = NutritionSandboxState();

      for (final scenario in CanonicalNutritionScenarios.all) {
        scenario.applyToSandbox(state);
        final assessment = state.evaluateAssessment();

        expect(
          assessment.overallStatus,
          scenario.expectedOverallStatus,
          reason: 'Scenario "${scenario.title}" overallStatus mismatch',
        );

        expect(
          assessment.recentMomentumStatus,
          scenario.expectedMomentum,
          reason: 'Scenario "${scenario.title}" momentum mismatch',
        );

        expect(
          assessment.nutritionAction,
          scenario.expectedAction,
          reason: 'Scenario "${scenario.title}" nutritionAction mismatch',
        );
      }
    });

    test(
        'Scenario 2 (Plateau) triggers adjust_targets and falling_further_behind',
        () {
      final state = NutritionSandboxState();
      final plateauScenario = CanonicalNutritionScenarios.all
          .firstWhere((s) => s.id == 'behind_plateau');
      plateauScenario.applyToSandbox(state);

      final assessment = state.evaluateAssessment();
      expect(assessment.overallStatus, 'behind');
      expect(assessment.recentMomentumStatus, 'falling_further_behind');
      expect(assessment.nutritionAction, 'adjust_targets');

      final review = state.buildSyntheticReviewRecord();
      expect(review.recommendedCalories, state.recommendedCalories);
    });

    test('Scenario 3 (Intake gap) keeps targets because intake explains gap',
        () {
      final state = NutritionSandboxState();
      final intakeScenario = CanonicalNutritionScenarios.all
          .firstWhere((s) => s.id == 'behind_intake_gap');
      intakeScenario.applyToSandbox(state);

      final assessment = state.evaluateAssessment();
      expect(assessment.overallStatus, 'behind');
      expect(assessment.nutritionAction, 'keep_targets_intake_differs');

      final review = state.buildSyntheticReviewRecord();
      expect(review.recommendedCalories, isNull);
    });

    test(
        'Scenario 6 (Insufficient data) fails sufficiency gate to calibrating state',
        () {
      final state = NutritionSandboxState();
      final calibratingScenario = CanonicalNutritionScenarios.all
          .firstWhere((s) => s.id == 'insufficient_data');
      calibratingScenario.applyToSandbox(state);

      final assessment = state.evaluateAssessment();
      expect(assessment.overallStatus, 'behind');
      expect(assessment.dataQuality, 'insufficient');
      expect(assessment.nutritionAction, 'insufficient_data');
    });

    test('Scenario 8 (Target reached) detects goal met', () {
      final state = NutritionSandboxState();
      final reachedScenario = CanonicalNutritionScenarios.all
          .firstWhere((s) => s.id == 'target_reached');
      reachedScenario.applyToSandbox(state);

      final assessment = state.evaluateAssessment();
      expect(assessment.overallStatus, 'target_reached');
      expect(assessment.nutritionAction, 'keep_targets');
    });
  });
}
