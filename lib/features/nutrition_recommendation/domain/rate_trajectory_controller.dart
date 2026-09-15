import 'adaptive_diet_phase.dart';
import 'goal_models.dart';
import 'recommendation_models.dart';

class RateTrajectoryControllerConfig {
  final double kcalPerKgPerWeekToDay;
  final double proportionalGain;
  final double rateErrorDeadbandKgPerWeek;
  final int maximumCorrectionCalories;
  final int maximumWeeklyCorrectionChangeCalories;
  final int minimumWindowDays;
  final int minimumIntakeDays;
  final int minimumWeightLogs;
  final int minimumConfirmedPhaseAgeDays;

  const RateTrajectoryControllerConfig({
    this.kcalPerKgPerWeekToDay = 7700 / 7,
    this.proportionalGain = 0.65,
    this.rateErrorDeadbandKgPerWeek = 0.05,
    this.maximumCorrectionCalories = 150,
    this.maximumWeeklyCorrectionChangeCalories = 100,
    this.minimumWindowDays = 14,
    this.minimumIntakeDays = 10,
    this.minimumWeightLogs = 7,
    this.minimumConfirmedPhaseAgeDays = 15,
  });
}

class RateTrajectoryCorrection {
  final int calories;
  final double? rateErrorKgPerWeek;
  final String status;

  const RateTrajectoryCorrection({
    required this.calories,
    required this.rateErrorKgPerWeek,
    required this.status,
  });

  bool get isActive => status == 'active' && calories != 0;
}

class RateTrajectoryController {
  final RateTrajectoryControllerConfig config;

  const RateTrajectoryController({
    this.config = const RateTrajectoryControllerConfig(),
  });

  RateTrajectoryCorrection evaluate({
    required RecommendationGenerationInput input,
    required BodyweightGoal goal,
    required double targetRateKgPerWeek,
    required String algorithmVersion,
    required BayesianObservationPhaseContext phaseContext,
    NutritionRecommendation? previousRecommendation,
  }) {
    final observedRate = input.smoothedWeightSlopeKgPerWeek;
    if (observedRate == null || !observedRate.isFinite) {
      return const RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: null,
        status: 'inactive_no_observation',
      );
    }

    final rateError = targetRateKgPerWeek - observedRate;
    if (!_hasSufficientData(
      windowDays: input.windowDays,
      intakeDays: input.intakeLoggedDays,
      weightLogs: input.weightLogCount,
      qualityFlags: input.qualityFlags,
    )) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_sparse_data',
      );
    }

    if (phaseContext.hasPendingPhaseChange ||
        phaseContext.confirmedPhaseAgeDays <
            config.minimumConfirmedPhaseAgeDays) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_phase_transition',
      );
    }

    if (rateError.abs() <= config.rateErrorDeadbandKgPerWeek) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_deadband',
      );
    }

    final previous = previousRecommendation;
    if (previous == null || previous.algorithmVersion != algorithmVersion) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_no_compatible_history',
      );
    }
    if (previous.goal != goal ||
        (previous.targetRateKgPerWeek - targetRateKgPerWeek).abs() > 0.001) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_goal_changed',
      );
    }

    final previousObservedRate =
        previous.inputSummary.smoothedWeightSlopeKgPerWeek;
    if (previousObservedRate == null ||
        !previousObservedRate.isFinite ||
        !_hasSufficientData(
          windowDays: previous.inputSummary.windowDays,
          intakeDays: previous.inputSummary.intakeLoggedDays,
          weightLogs: previous.inputSummary.weightLogCount,
          qualityFlags: previous.inputSummary.qualityFlags,
        )) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_no_compatible_history',
      );
    }

    final previousRateError = targetRateKgPerWeek - previousObservedRate;
    if (previousRateError.abs() <= config.rateErrorDeadbandKgPerWeek ||
        previousRateError.sign != rateError.sign) {
      return RateTrajectoryCorrection(
        calories: 0,
        rateErrorKgPerWeek: rateError,
        status: 'inactive_not_persistent',
      );
    }

    final rawCorrection =
        (rateError * config.kcalPerKgPerWeekToDay * config.proportionalGain)
            .round()
            .clamp(
              -config.maximumCorrectionCalories,
              config.maximumCorrectionCalories,
            );
    final previousCorrection = previous.trajectoryCorrectionCalories.clamp(
      -config.maximumCorrectionCalories,
      config.maximumCorrectionCalories,
    );
    final correction = rawCorrection.clamp(
      previousCorrection - config.maximumWeeklyCorrectionChangeCalories,
      previousCorrection + config.maximumWeeklyCorrectionChangeCalories,
    );

    return RateTrajectoryCorrection(
      calories: correction,
      rateErrorKgPerWeek: rateError,
      status: correction == 0 ? 'inactive_deadband' : 'active',
    );
  }

  bool _hasSufficientData({
    required int windowDays,
    required int intakeDays,
    required int weightLogs,
    required List<String> qualityFlags,
  }) {
    return windowDays >= config.minimumWindowDays &&
        intakeDays >= config.minimumIntakeDays &&
        weightLogs >= config.minimumWeightLogs &&
        !qualityFlags.contains('unresolved_food_calories');
  }
}
