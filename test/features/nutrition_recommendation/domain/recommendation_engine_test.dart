import 'package:flutter_test/flutter_test.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/confidence_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/goal_models.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_engine.dart';
import 'package:train_libre/features/nutrition_recommendation/domain/recommendation_models.dart';

void main() {
  group('AdaptiveNutritionRecommendationEngine projection', () {
    test('rateAdjustmentKcalPerDay maps weekly kg target to kcal/day', () {
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(-0.50),
        -550,
      );
      expect(
        AdaptiveNutritionRecommendationEngine.rateAdjustmentKcalPerDay(0.25),
        275,
      );
    });

    test('uses active targets as warning baseline for large adjustments', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(activeTargetCalories: 2000),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2550,
        confidence: RecommendationConfidence.medium,
        dueWeekKey: '2026-04-06',
      );

      expect(recommendation.recommendedCalories, 2550);
      expect(recommendation.baselineCalories, 2000);
      expect(recommendation.warningState.hasLargeAdjustmentWarning, isTrue);
      expect(
        recommendation.warningState.warningReasons,
        contains('large_adjustment_high'),
      );
      expect(recommendation.dueWeekKey, '2026-04-06');
    });

    test(
        'falls back to previous recommendation baseline when active target is missing',
        () {
      final previous = NutritionRecommendation(
        recommendedCalories: 2350,
        recommendedProteinGrams: 170,
        recommendedCarbsGrams: 250,
        recommendedFatGrams: 70,
        estimatedMaintenanceCalories: 2350,
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        confidence: RecommendationConfidence.medium,
        warningState: RecommendationWarningState.none,
        generatedAt: DateTime(2026, 3, 29),
        windowStart: DateTime(2026, 3, 9),
        windowEnd: DateTime(2026, 3, 29, 23, 59, 59),
        algorithmVersion: 'test',
        inputSummary: const RecommendationInputSummary(
          windowDays: 21,
          weightLogCount: 9,
          intakeLoggedDays: 15,
          smoothedWeightSlopeKgPerWeek: -0.1,
          avgLoggedCalories: 2300,
        ),
        baselineCalories: 2350,
        dueWeekKey: '2026-03-23',
      );

      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(activeTargetCalories: null),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2500,
        confidence: RecommendationConfidence.medium,
        previousRecommendation: previous,
      );

      expect(recommendation.baselineCalories, 2350);
      expect(recommendation.warningState.hasLargeAdjustmentWarning, isFalse);
    });

    test('applies calorie floor and degrades confidence conservatively', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(currentWeightKg: 95),
        goal: BodyweightGoal.loseWeight,
        targetRateKgPerWeek: -1.0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 1200,
        confidence: RecommendationConfidence.high,
      );

      expect(recommendation.recommendedCalories, 1200);
      expect(recommendation.confidence, RecommendationConfidence.low);
      expect(
        recommendation.warningState.warningReasons,
        contains('calorie_floor_applied'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.high,
      );
    });

    test('surfaces unresolved calorie inputs as warning reason', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(
          qualityFlags: const ['unresolved_food_calories'],
        ),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2400,
        confidence: RecommendationConfidence.medium,
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('unresolved_food_calories'),
      );
      expect(
        recommendation.warningState.warningLevel,
        RecommendationWarningLevel.moderate,
      );
    });

    test('appends additional warning reasons for estimator context', () {
      final recommendation =
          AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
        input: _input(),
        goal: BodyweightGoal.maintainWeight,
        targetRateKgPerWeek: 0,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: 2400,
        confidence: RecommendationConfidence.medium,
        additionalWarningReasons: const [
          'bayesian_prediction_only_no_observation'
        ],
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('bayesian_prediction_only_no_observation'),
      );
    });
  });

  // Fat used to be pinned to its 0.6 g/kg floor whatever the goal and whatever
  // the calorie budget, with every remaining calorie going to carbohydrates —
  // which is at the very bottom of the evidence-based range on a cut and below
  // it at maintenance. It is now targeted per kilogram like protein is.
  group('AdaptiveNutritionRecommendationEngine macro distribution', () {
    NutritionRecommendation generate({
      required BodyweightGoal goal,
      double weightKg = 80,
      int maintenanceCalories = 2600,
      double rateKgPerWeek = 0,
    }) {
      return AdaptiveNutritionRecommendationEngine
          .generateFromMaintenanceEstimate(
        input: _input(currentWeightKg: weightKg),
        goal: goal,
        targetRateKgPerWeek: rateKgPerWeek,
        generatedAt: DateTime(2026, 4, 5),
        algorithmVersion: 'test',
        estimatedMaintenanceCalories: maintenanceCalories,
        confidence: RecommendationConfidence.medium,
      );
    }

    test('targets 0.9 g fat per kg while cutting', () {
      final recommendation = generate(
        goal: BodyweightGoal.loseWeight,
        rateKgPerWeek: -0.5,
      );

      expect(recommendation.recommendedFatGrams, 72); // 80 kg * 0.9
      expect(recommendation.recommendedProteinGrams, 160); // 80 kg * 2.0
    });

    test('targets 1.0 g fat per kg at maintenance and on a bulk', () {
      expect(
        generate(goal: BodyweightGoal.maintainWeight).recommendedFatGrams,
        80,
      );
      expect(
        generate(goal: BodyweightGoal.gainWeight, rateKgPerWeek: 0.25)
            .recommendedFatGrams,
        80,
      );
    });

    test('leaves the remaining calories to carbohydrates', () {
      final recommendation = generate(goal: BodyweightGoal.maintainWeight);

      final macroCalories = recommendation.recommendedProteinGrams * 4 +
          recommendation.recommendedCarbsGrams * 4 +
          recommendation.recommendedFatGrams * 9;

      expect(
        (macroCalories - recommendation.recommendedCalories).abs(),
        lessThanOrEqualTo(4), // one carbohydrate gram of rounding
      );
      expect(recommendation.recommendedCarbsGrams, greaterThan(0));
      expect(
        recommendation.warningState.warningReasons,
        isNot(contains('macro_distribution_constrained')),
      );
    });

    test('gives fat back towards the floor before starving carbohydrates', () {
      // 110 kg on 1500 kcal: protein alone is 220 g, and fat at target would
      // leave nothing for carbohydrates.
      final recommendation = generate(
        goal: BodyweightGoal.loseWeight,
        weightKg: 110,
        maintenanceCalories: 1500,
      );

      final floor = (110 * 0.60).round();
      expect(recommendation.recommendedFatGrams, greaterThanOrEqualTo(floor));
      expect(recommendation.recommendedFatGrams, lessThan((110 * 0.9).round()));
      expect(recommendation.recommendedCarbsGrams, greaterThanOrEqualTo(0));
    });

    test('flags a distribution it cannot satisfy at all', () {
      // Nothing fits here: the calorie floor is 1200 and protein alone claims
      // more than that.
      final recommendation = generate(
        goal: BodyweightGoal.loseWeight,
        weightKg: 160,
        maintenanceCalories: 1200,
        rateKgPerWeek: -1.0,
      );

      expect(
        recommendation.warningState.warningReasons,
        contains('macro_distribution_constrained'),
      );
      expect(recommendation.recommendedFatGrams, greaterThanOrEqualTo(25));
      expect(recommendation.recommendedCarbsGrams, 0);
    });

    test('falls back to a default body weight when none is known', () {
      final recommendation = generate(
        goal: BodyweightGoal.maintainWeight,
        weightKg: 0,
      );

      expect(recommendation.recommendedFatGrams, 75); // 75 kg * 1.0
    });
  });
}

RecommendationGenerationInput _input({
  int? activeTargetCalories,
  List<String> qualityFlags = const [],
  double currentWeightKg = 82,
}) {
  return RecommendationGenerationInput(
    windowStart: DateTime(2026, 3, 15),
    windowEnd: DateTime(2026, 4, 5, 23, 59, 59),
    windowDays: 14,
    weightLogCount: 6,
    intakeLoggedDays: 10,
    smoothedWeightSlopeKgPerWeek: -0.2,
    avgLoggedCalories: 2300,
    currentWeightKg: currentWeightKg,
    priorMaintenanceCalories: 2400,
    activeTargetCalories: activeTargetCalories,
    qualityFlags: qualityFlags,
  );
}
