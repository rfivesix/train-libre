// lib/features/profile/domain/services/goal_trajectory_calculator.dart

class TrajectoryRecalculationResult {
  final double targetWeight;
  final DateTime targetDate;
  final double weeklyRateKg;
  final bool isSafeRate;
  final String? warningMessage;

  const TrajectoryRecalculationResult({
    required this.targetWeight,
    required this.targetDate,
    required this.weeklyRateKg,
    this.isSafeRate = true,
    this.warningMessage,
  });
}

class GoalTrajectoryCalculator {
  static const double maxSafeLossRateKgPerWeek = -1.5;
  static const double recommendedMaxLossRateKgPerWeek = -1.0;
  static const double maxSafeGainRateKgPerWeek = 0.75;
  static const double recommendedMaxGainRateKgPerWeek = 0.5;
  static const int minGoalDurationDays = 7;

  /// Validates whether a weekly rate is physiologically safe.
  static bool isRateSafe(double weeklyRateKg) {
    if (weeklyRateKg < maxSafeLossRateKgPerWeek) return false;
    if (weeklyRateKg > maxSafeGainRateKgPerWeek) return false;
    return true;
  }

  /// Calculates weekly rate given start, target weight and target date.
  static double calculateWeeklyRate({
    required double startWeight,
    required double targetWeight,
    required DateTime startDate,
    required DateTime targetDate,
  }) {
    final days = targetDate.difference(startDate).inDays;
    if (days <= 0) return 0.0;
    final weeks = days / 7.0;
    final delta = targetWeight - startWeight;
    return delta / weeks;
  }

  /// Calculates estimated target date given start, target weight and weekly rate.
  static DateTime calculateTargetDate({
    required double startWeight,
    required double targetWeight,
    required DateTime startDate,
    required double weeklyRateKg,
  }) {
    if (weeklyRateKg.abs() < 0.001) return startDate.add(const Duration(days: 90));
    final delta = targetWeight - startWeight;
    final weeks = delta / weeklyRateKg;
    final days = (weeks * 7.0).round().clamp(minGoalDurationDays, 365 * 5);
    return startDate.add(Duration(days: days));
  }

  /// Calculates target weight given start, target date and weekly rate.
  static double calculateTargetWeight({
    required double startWeight,
    required DateTime startDate,
    required DateTime targetDate,
    required double weeklyRateKg,
  }) {
    final days = targetDate.difference(startDate).inDays;
    final weeks = days / 7.0;
    return startWeight + (weeklyRateKg * weeks);
  }

  /// Resolver for the 6 adjustment paths:
  ///
  /// Path 1: User changes targetWeight, keeps targetDate -> recalculates weeklyRate
  static TrajectoryRecalculationResult onWeightChangedKeepDate({
    required double startWeight,
    required double newTargetWeight,
    required DateTime startDate,
    required DateTime fixedTargetDate,
  }) {
    final rate = calculateWeeklyRate(
      startWeight: startWeight,
      targetWeight: newTargetWeight,
      startDate: startDate,
      targetDate: fixedTargetDate,
    );
    return _buildResult(
      targetWeight: newTargetWeight,
      targetDate: fixedTargetDate,
      weeklyRateKg: rate,
    );
  }

  /// Path 2: User changes targetWeight, keeps weeklyRate -> recalculates targetDate
  static TrajectoryRecalculationResult onWeightChangedKeepRate({
    required double startWeight,
    required double newTargetWeight,
    required DateTime startDate,
    required double fixedWeeklyRate,
  }) {
    final date = calculateTargetDate(
      startWeight: startWeight,
      targetWeight: newTargetWeight,
      startDate: startDate,
      weeklyRateKg: fixedWeeklyRate,
    );
    return _buildResult(
      targetWeight: newTargetWeight,
      targetDate: date,
      weeklyRateKg: fixedWeeklyRate,
    );
  }

  /// Path 3: User changes targetDate, keeps targetWeight -> recalculates weeklyRate
  static TrajectoryRecalculationResult onDateChangedKeepWeight({
    required double startWeight,
    required double fixedTargetWeight,
    required DateTime startDate,
    required DateTime newTargetDate,
  }) {
    final rate = calculateWeeklyRate(
      startWeight: startWeight,
      targetWeight: fixedTargetWeight,
      startDate: startDate,
      targetDate: newTargetDate,
    );
    return _buildResult(
      targetWeight: fixedTargetWeight,
      targetDate: newTargetDate,
      weeklyRateKg: rate,
    );
  }

  /// Path 4: User changes targetDate, keeps weeklyRate -> recalculates targetWeight
  static TrajectoryRecalculationResult onDateChangedKeepRate({
    required double startWeight,
    required DateTime startDate,
    required DateTime newTargetDate,
    required double fixedWeeklyRate,
  }) {
    final weight = calculateTargetWeight(
      startWeight: startWeight,
      startDate: startDate,
      targetDate: newTargetDate,
      weeklyRateKg: fixedWeeklyRate,
    );
    return _buildResult(
      targetWeight: weight,
      targetDate: newTargetDate,
      weeklyRateKg: fixedWeeklyRate,
    );
  }

  /// Path 5: User changes weeklyRate, keeps targetWeight -> recalculates targetDate
  static TrajectoryRecalculationResult onRateChangedKeepWeight({
    required double startWeight,
    required double fixedTargetWeight,
    required DateTime startDate,
    required double newWeeklyRate,
  }) {
    final date = calculateTargetDate(
      startWeight: startWeight,
      targetWeight: fixedTargetWeight,
      startDate: startDate,
      weeklyRateKg: newWeeklyRate,
    );
    return _buildResult(
      targetWeight: fixedTargetWeight,
      targetDate: date,
      weeklyRateKg: newWeeklyRate,
    );
  }

  /// Path 6: User changes weeklyRate, keeps targetDate -> recalculates targetWeight
  static TrajectoryRecalculationResult onRateChangedKeepDate({
    required double startWeight,
    required DateTime startDate,
    required DateTime fixedTargetDate,
    required double newWeeklyRate,
  }) {
    final weight = calculateTargetWeight(
      startWeight: startWeight,
      startDate: startDate,
      targetDate: fixedTargetDate,
      weeklyRateKg: newWeeklyRate,
    );
    return _buildResult(
      targetWeight: weight,
      targetDate: fixedTargetDate,
      weeklyRateKg: newWeeklyRate,
    );
  }

  static TrajectoryRecalculationResult _buildResult({
    required double targetWeight,
    required DateTime targetDate,
    required double weeklyRateKg,
  }) {
    final safe = isRateSafe(weeklyRateKg);
    String? warning;
    if (weeklyRateKg < maxSafeLossRateKgPerWeek) {
      warning = 'Die berechnete Abnahmerate ist sehr steil (über 1,5 kg/Woche). Ein moderateres Tempo schützt Muskelmasse.';
    } else if (weeklyRateKg > maxSafeGainRateKgPerWeek) {
      warning = 'Die berechnete Zunahmerate ist sehr hoch (über 0,75 kg/Woche). Ein moderateres Tempo minimiert Fettaufbau.';
    }
    return TrajectoryRecalculationResult(
      targetWeight: targetWeight,
      targetDate: targetDate,
      weeklyRateKg: weeklyRateKg,
      isSafeRate: safe,
      warningMessage: warning,
    );
  }
}
