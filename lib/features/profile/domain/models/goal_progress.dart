// lib/features/profile/domain/models/goal_progress.dart

import 'goal_model.dart';

enum GoalProgressState {
  waitingForBaseline,
  inProgress,
  targetMet,
  maintenanceStable,
  maintenanceDrifting,
}

class GoalProgress {
  final Goal goal;
  final double? baselineValue;
  final DateTime? baselineDate;
  final double? currentValue;
  final DateTime? currentDate;
  final double? targetValue;
  final DateTime? targetDate;
  final double? deltaSinceStart;
  final double? remainingDistance;
  final double? progressPercentage;
  final bool isInToleranceBand;
  final double? trendRateKgPerWeek;
  final GoalProgressState state;

  const GoalProgress({
    required this.goal,
    this.baselineValue,
    this.baselineDate,
    this.currentValue,
    this.currentDate,
    this.targetValue,
    this.targetDate,
    this.deltaSinceStart,
    this.remainingDistance,
    this.progressPercentage,
    this.isInToleranceBand = false,
    this.trendRateKgPerWeek,
    required this.state,
  });

  bool get isWaitingForBaseline => state == GoalProgressState.waitingForBaseline;
  bool get isTargetMet => state == GoalProgressState.targetMet;

  factory GoalProgress.calculate({
    required Goal goal,
    required double? baselineValue,
    required DateTime? baselineDate,
    required double? currentValue,
    required DateTime? currentDate,
    double? trendRateKgPerWeek,
  }) {
    if (baselineValue == null || currentValue == null) {
      return GoalProgress(
        goal: goal,
        baselineValue: baselineValue,
        baselineDate: baselineDate,
        currentValue: currentValue,
        currentDate: currentDate,
        targetValue: goal.targetValue,
        targetDate: goal.targetDate,
        trendRateKgPerWeek: trendRateKgPerWeek,
        state: GoalProgressState.waitingForBaseline,
      );
    }

    final delta = currentValue - baselineValue;
    final target = goal.targetValue;

    if (goal.isMaintenanceOrRecomp) {
      // Tolerance band: default ±1.0 kg around baseline (or target if specified)
      final center = target ?? baselineValue;
      final diff = (currentValue - center).abs();
      final inBand = diff <= 1.0;

      return GoalProgress(
        goal: goal,
        baselineValue: baselineValue,
        baselineDate: baselineDate,
        currentValue: currentValue,
        currentDate: currentDate,
        targetValue: target,
        targetDate: goal.targetDate,
        deltaSinceStart: delta,
        isInToleranceBand: inBand,
        trendRateKgPerWeek: trendRateKgPerWeek,
        state: inBand
            ? GoalProgressState.maintenanceStable
            : GoalProgressState.maintenanceDrifting,
      );
    }

    if (target == null) {
      // Directional goal without a specific number
      return GoalProgress(
        goal: goal,
        baselineValue: baselineValue,
        baselineDate: baselineDate,
        currentValue: currentValue,
        currentDate: currentDate,
        targetDate: goal.targetDate,
        deltaSinceStart: delta,
        trendRateKgPerWeek: trendRateKgPerWeek,
        state: GoalProgressState.inProgress,
      );
    }

    // Goal has numeric target
    final remaining = (currentValue - target).abs();
    final totalDistance = (target - baselineValue).abs();

    double? pct;
    bool met = false;

    if (goal.preset == GoalPreset.loseWeight ||
        (baselineValue > target && goal.preset != GoalPreset.gainWeight)) {
      // Losing weight: current should decrease towards target
      if (currentValue <= target) {
        met = true;
        pct = 1.0;
      } else if (totalDistance > 0.001) {
        final achieved = baselineValue - currentValue;
        pct = (achieved / totalDistance).clamp(0.0, 1.0);
      }
    } else {
      // Gaining weight: current should increase towards target
      if (currentValue >= target) {
        met = true;
        pct = 1.0;
      } else if (totalDistance > 0.001) {
        final achieved = currentValue - baselineValue;
        pct = (achieved / totalDistance).clamp(0.0, 1.0);
      }
    }

    return GoalProgress(
      goal: goal,
      baselineValue: baselineValue,
      baselineDate: baselineDate,
      currentValue: currentValue,
      currentDate: currentDate,
      targetValue: target,
      targetDate: goal.targetDate,
      deltaSinceStart: delta,
      remainingDistance: remaining,
      progressPercentage: pct,
      trendRateKgPerWeek: trendRateKgPerWeek,
      state: met ? GoalProgressState.targetMet : GoalProgressState.inProgress,
    );
  }
}
