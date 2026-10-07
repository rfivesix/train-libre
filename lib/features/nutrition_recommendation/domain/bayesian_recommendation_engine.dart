import 'adaptive_diet_phase.dart';
import 'bayesian_tdee_estimator.dart';
import 'goal_models.dart';
import 'recommendation_engine.dart';
import 'recommendation_models.dart';
import 'rate_trajectory_controller.dart';

class BayesianNutritionRecommendationResult {
  final NutritionRecommendation recommendation;
  final BayesianMaintenanceEstimate maintenanceEstimate;
  final BayesianEstimatorState? recursiveState;

  const BayesianNutritionRecommendationResult({
    required this.recommendation,
    required this.maintenanceEstimate,
    this.recursiveState,
  });

  int get maintenanceDeltaFromPriorCalories {
    return recommendation.estimatedMaintenanceCalories -
        maintenanceEstimate.priorMaintenanceCalories.round();
  }
}

class BayesianNutritionRecommendationEngine {
  final BayesianTdeeEstimator _estimator;
  final RateTrajectoryController _trajectoryController;

  const BayesianNutritionRecommendationEngine({
    BayesianTdeeEstimator estimator = const BayesianTdeeEstimator(),
    RateTrajectoryController trajectoryController =
        const RateTrajectoryController(),
  })  : _estimator = estimator,
        _trajectoryController = trajectoryController;

  BayesianNutritionRecommendationResult generate({
    required RecommendationGenerationInput input,
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required DateTime generatedAt,
    required String algorithmVersion,
    String? dueWeekKey,
    BayesianEstimatorState? recursiveState,
    NutritionRecommendation? previousRecommendation,
    BayesianObservationPhaseContext? phaseContext,
  }) {
    final effectivePhaseContext = phaseContext ??
        BayesianObservationPhaseContext.bootstrap(
          phase: goal.canonicalDietPhase,
        );
    final estimatorRun = _estimator.estimate(
      input: input,
      recursiveState: recursiveState,
      dueWeekKey: dueWeekKey,
      phaseContext: effectivePhaseContext,
    );
    final maintenanceEstimate = estimatorRun.estimate;
    final phaseEffectiveKcalPerKg =
        maintenanceEstimate.debugInfo['effectiveKcalPerKg'] as double?;
    final trajectoryCorrection = _trajectoryController.evaluate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      algorithmVersion: algorithmVersion,
      phaseContext: effectivePhaseContext,
      previousRecommendation: previousRecommendation,
    );

    final recommendation =
        AdaptiveNutritionRecommendationEngine.generateFromMaintenanceEstimate(
      input: input,
      goal: goal,
      targetRateKgPerWeek: targetRateKgPerWeek,
      generatedAt: generatedAt,
      algorithmVersion: algorithmVersion,
      estimatedMaintenanceCalories:
          maintenanceEstimate.posteriorMaintenanceCalories.round(),
      confidence: maintenanceEstimate.confidence,
      phaseEffectiveKcalPerKg: phaseEffectiveKcalPerKg,
      dueWeekKey: dueWeekKey,
      previousRecommendation: previousRecommendation,
      trajectoryCorrectionCalories: trajectoryCorrection.calories,
      trajectoryRateErrorKgPerWeek: trajectoryCorrection.rateErrorKgPerWeek,
      trajectoryCorrectionStatus: trajectoryCorrection.status,
    );

    return BayesianNutritionRecommendationResult(
      recommendation: recommendation,
      maintenanceEstimate: maintenanceEstimate,
      recursiveState: estimatorRun.nextState,
    );
  }
}
