import 'confidence_models.dart';
import 'goal_models.dart';
import 'recommendation_models.dart';

class AdaptiveNutritionRecommendationEngine {
  const AdaptiveNutritionRecommendationEngine._();

  static const double _kcalPerKgPerWeekToDay = 7700 / 7;
  static const int _minimumRecommendedCalories = 1200;

  static NutritionRecommendation generateFromMaintenanceEstimate({
    required RecommendationGenerationInput input,
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required DateTime generatedAt,
    required String algorithmVersion,
    required int estimatedMaintenanceCalories,
    required RecommendationConfidence confidence,
    double? phaseEffectiveKcalPerKg,
    String? dueWeekKey,
    NutritionRecommendation? previousRecommendation,
    List<String> additionalWarningReasons = const [],
  }) {
    var effectiveConfidence = confidence;
    final calorieAdjustment = rateAdjustmentKcalPerDay(targetRateKgPerWeek);
    var recommendedCalories = estimatedMaintenanceCalories + calorieAdjustment;
    final safetyWarningReasons = <String>[];

    if (recommendedCalories < _minimumRecommendedCalories) {
      recommendedCalories = _minimumRecommendedCalories;
      safetyWarningReasons.add('calorie_floor_applied');
      if (effectiveConfidence == RecommendationConfidence.high ||
          effectiveConfidence == RecommendationConfidence.medium) {
        effectiveConfidence = RecommendationConfidence.low;
      }
    }

    final macroResult = _computeMacros(
      goal: goal,
      currentWeightKg: input.currentWeightKg,
      recommendedCalories: recommendedCalories,
    );

    final baselineCalories = input.activeTargetCalories ??
        previousRecommendation?.recommendedCalories;
    final warningReasons = <String>{
      ...macroResult.warningReasons,
      ...safetyWarningReasons,
      if (input.qualityFlags.contains('unresolved_food_calories'))
        'unresolved_food_calories',
      ...additionalWarningReasons,
    }.toList(growable: false);

    final warningState = _buildWarningState(
      baselineCalories: baselineCalories,
      recommendedCalories: recommendedCalories,
      extraReasons: warningReasons,
    );

    return NutritionRecommendation(
      recommendedCalories: recommendedCalories,
      recommendedProteinGrams: macroResult.protein,
      recommendedCarbsGrams: macroResult.carbs,
      recommendedFatGrams: macroResult.fat,
      estimatedMaintenanceCalories: estimatedMaintenanceCalories,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      confidence: effectiveConfidence,
      warningState: warningState,
      generatedAt: generatedAt,
      windowStart: input.windowStart,
      windowEnd: input.windowEnd,
      algorithmVersion: algorithmVersion,
      inputSummary: RecommendationInputSummary(
        windowDays: input.windowDays,
        weightLogCount: input.weightLogCount,
        intakeLoggedDays: input.intakeLoggedDays,
        smoothedWeightSlopeKgPerWeek: input.smoothedWeightSlopeKgPerWeek,
        avgLoggedCalories: input.avgLoggedCalories,
        qualityFlags: input.qualityFlags,
        phaseEffectiveKcalPerKg: phaseEffectiveKcalPerKg,
      ),
      baselineCalories: baselineCalories,
      dueWeekKey: dueWeekKey,
    );
  }

  static int rateAdjustmentKcalPerDay(double kgPerWeek) {
    return (kgPerWeek * _kcalPerKgPerWeekToDay).round();
  }

  static _MacroResult _computeMacros({
    required BodyweightGoal goal,
    required double currentWeightKg,
    required int recommendedCalories,
  }) {
    final normalizedWeight = currentWeightKg <= 0 ? 75.0 : currentWeightKg;
    var proteinGrams = (normalizedWeight * _proteinPerKg(goal)).round();

    // Fat is targeted per kilogram like protein is, and only falls back to the
    // floor when the calorie budget cannot carry the target. Carbohydrates
    // take whatever is left.
    final fatFloor = (normalizedWeight * _kFatFloorPerKg).round().clamp(35, 130);
    var fatGrams =
        (normalizedWeight * _fatPerKg(goal)).round().clamp(fatFloor, 250);

    var carbsGrams =
        ((recommendedCalories - (proteinGrams * 4) - (fatGrams * 9)) / 4)
            .round();

    final warningReasons = <String>[];

    // Not enough calories left for any carbohydrates: give the target back
    // down towards the floor before touching protein.
    if (carbsGrams < 0 && fatGrams > fatFloor) {
      final affordableFat =
          ((recommendedCalories - (proteinGrams * 4)) / 9).floor();
      fatGrams = affordableFat.clamp(fatFloor, fatGrams);
      carbsGrams =
          ((recommendedCalories - (proteinGrams * 4) - (fatGrams * 9)) / 4)
              .round();
    }

    if (carbsGrams < 0) {
      carbsGrams = 0;
      fatGrams = ((recommendedCalories - (proteinGrams * 4)) / 9).floor();

      if (fatGrams < 25) {
        fatGrams = 25;
        final proteinBudgetCalories = recommendedCalories - (fatGrams * 9);
        if (proteinBudgetCalories < proteinGrams * 4) {
          proteinGrams = (proteinBudgetCalories / 4).floor().clamp(0, 999);
        }
      }

      warningReasons.add('macro_distribution_constrained');
    }

    return _MacroResult(
      protein: proteinGrams.clamp(0, 999),
      carbs: carbsGrams.clamp(0, 999),
      fat: fatGrams.clamp(0, 999),
      warningReasons: warningReasons,
    );
  }

  static double _proteinPerKg(BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return 2.0;
      case BodyweightGoal.maintainWeight:
      case BodyweightGoal.gainWeight:
        return 1.8;
    }
  }

  /// Target fat intake in grams per kilogram of body weight.
  ///
  /// Sits inside the evidence-based ranges — roughly 0.5–1.0 g/kg on a deficit
  /// and 0.8–1.2 g/kg at or above maintenance — rather than at the bottom of
  /// them. A cut is held slightly lower than maintenance so the deficit costs
  /// carbohydrates last: training quality suffers from an empty carbohydrate
  /// budget long before it suffers from fat at 0.9 g/kg.
  static double _fatPerKg(BodyweightGoal goal) {
    switch (goal) {
      case BodyweightGoal.loseWeight:
        return 0.9;
      case BodyweightGoal.maintainWeight:
      case BodyweightGoal.gainWeight:
        return 1.0;
    }
  }

  /// Lowest fat intake the distribution will settle on, in grams per kilogram,
  /// before it starts taking calories out of carbohydrates and then protein.
  ///
  /// The bottom of the cutting range: below this, hormonal and fat-soluble
  /// vitamin support is no longer a given.
  static const double _kFatFloorPerKg = 0.60;

  static RecommendationWarningState _buildWarningState({
    required int? baselineCalories,
    required int recommendedCalories,
    required List<String> extraReasons,
  }) {
    final reasons = <String>[...extraReasons];
    var warningLevel = RecommendationWarningLevel.none;
    var hasLargeAdjustmentWarning = false;

    if (baselineCalories != null) {
      final delta = (recommendedCalories - baselineCalories).abs();
      if (delta >= 450) {
        warningLevel = RecommendationWarningLevel.high;
        hasLargeAdjustmentWarning = true;
        reasons.add('large_adjustment_high');
      } else if (delta >= 250) {
        warningLevel = RecommendationWarningLevel.moderate;
        hasLargeAdjustmentWarning = true;
        reasons.add('large_adjustment_moderate');
      }
    }

    if (reasons.contains('calorie_floor_applied')) {
      warningLevel = RecommendationWarningLevel.high;
    } else if (!hasLargeAdjustmentWarning && reasons.isNotEmpty) {
      warningLevel = RecommendationWarningLevel.moderate;
    }

    return RecommendationWarningState(
      hasLargeAdjustmentWarning: hasLargeAdjustmentWarning,
      warningLevel: warningLevel,
      warningReasons: reasons,
    );
  }
}

class _MacroResult {
  final int protein;
  final int carbs;
  final int fat;
  final List<String> warningReasons;

  const _MacroResult({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.warningReasons,
  });
}
