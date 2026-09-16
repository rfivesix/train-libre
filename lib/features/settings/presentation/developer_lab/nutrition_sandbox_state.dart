// lib/features/settings/presentation/developer_lab/nutrition_sandbox_state.dart

import 'package:flutter/foundation.dart';

import '../../../profile/domain/models/goal_model.dart';
import '../../../profile/domain/services/weekly_goal_review_service.dart';

class NutritionSandboxState extends ChangeNotifier {
  // Goal Definition
  GoalPreset _preset = GoalPreset.loseWeight;
  double _baselineWeightKg = 85.0;
  double _targetWeightKg = 78.0;
  int _totalPlannedWeeks = 12;
  double _desiredWeeklyRateKg = 0.58;

  // Timeline & State
  int _elapsedWeeks = 4;
  double _currentWeightKg = 83.2;
  double _recentRateKgPerWeek = -0.45;
  double _operatingRateKgPerWeek = -0.45;

  // Intake & Sufficiency
  int _weightObservationCount = 5;
  int _nutritionLoggedDays = 7;
  int _currentCalories = 2150;
  int _averageLoggedCalories = 2170;
  double _tdeeEstimate = 2650.0;

  // Recommended Calories output if adjustment is triggered
  int _recommendedCalories = 2000;
  final int _recommendedProtein = 160;
  final int _recommendedCarbs = 200;
  final int _recommendedFat = 60;

  // Constructor with initial calculation
  NutritionSandboxState() {
    _recalculateDerivedPace();
  }

  // Getters
  GoalPreset get preset => _preset;
  double get baselineWeightKg => _baselineWeightKg;
  double get targetWeightKg => _targetWeightKg;
  int get totalPlannedWeeks => _totalPlannedWeeks;
  double get desiredWeeklyRateKg => _desiredWeeklyRateKg;
  int get elapsedWeeks => _elapsedWeeks;
  double get currentWeightKg => _currentWeightKg;
  double get recentRateKgPerWeek => _recentRateKgPerWeek;
  double get operatingRateKgPerWeek => _operatingRateKgPerWeek;
  int get weightObservationCount => _weightObservationCount;
  int get nutritionLoggedDays => _nutritionLoggedDays;
  int get currentCalories => _currentCalories;
  int get averageLoggedCalories => _averageLoggedCalories;
  double get tdeeEstimate => _tdeeEstimate;
  int get recommendedCalories => _recommendedCalories;
  int get recommendedProtein => _recommendedProtein;
  int get recommendedCarbs => _recommendedCarbs;
  int get recommendedFat => _recommendedFat;

  void reset() {
    _preset = GoalPreset.loseWeight;
    _baselineWeightKg = 85.0;
    _targetWeightKg = 78.0;
    _totalPlannedWeeks = 12;
    _elapsedWeeks = 4;
    _currentWeightKg = 83.2;
    _recentRateKgPerWeek = -0.45;
    _operatingRateKgPerWeek = -0.45;
    _weightObservationCount = 5;
    _nutritionLoggedDays = 7;
    _currentCalories = 2150;
    _averageLoggedCalories = 2170;
    _tdeeEstimate = 2650.0;
    _recommendedCalories = 2000;
    _recalculateDerivedPace();
    notifyListeners();
  }

  // Setters with notifyListeners()
  void setPreset(GoalPreset value) {
    _preset = value;
    _recalculateDerivedPace();
    notifyListeners();
  }

  void setBaselineWeight(double value) {
    _baselineWeightKg = (value * 10).roundToDouble() / 10.0;
    _recalculateDerivedPace();
    notifyListeners();
  }

  void setTargetWeight(double value) {
    _targetWeightKg = (value * 10).roundToDouble() / 10.0;
    _recalculateDerivedPace();
    notifyListeners();
  }

  void setTotalPlannedWeeks(int value) {
    _totalPlannedWeeks = value;
    _recalculateDerivedPace();
    notifyListeners();
  }

  void setDesiredWeeklyRate(double value) {
    _desiredWeeklyRateKg = (value * 100).roundToDouble() / 100.0;
    notifyListeners();
  }

  void setElapsedWeeks(int value) {
    _elapsedWeeks = value;
    notifyListeners();
  }

  void setCurrentWeight(double value) {
    _currentWeightKg = (value * 10).roundToDouble() / 10.0;
    notifyListeners();
  }

  void setRecentRate(double value) {
    _recentRateKgPerWeek = (value * 100).roundToDouble() / 100.0;
    notifyListeners();
  }

  void setOperatingRate(double value) {
    _operatingRateKgPerWeek = (value * 100).roundToDouble() / 100.0;
    notifyListeners();
  }

  void setWeightObservationCount(int value) {
    _weightObservationCount = value;
    notifyListeners();
  }

  void setNutritionLoggedDays(int value) {
    _nutritionLoggedDays = value;
    notifyListeners();
  }

  void setCurrentCalories(int value) {
    _currentCalories = value;
    notifyListeners();
  }

  void setAverageLoggedCalories(int value) {
    _averageLoggedCalories = value;
    notifyListeners();
  }

  void setTdeeEstimate(double value) {
    _tdeeEstimate = value;
    notifyListeners();
  }

  void setRecommendedCalories(int value) {
    _recommendedCalories = value;
    notifyListeners();
  }

  void _recalculateDerivedPace() {
    final delta = (_targetWeightKg - _baselineWeightKg).abs();
    if (_totalPlannedWeeks > 0) {
      _desiredWeeklyRateKg =
          ((delta / _totalPlannedWeeks) * 100).round() / 100.0;
    }
  }

  // --- Engine Evaluation ---

  DateTime get baselineDate =>
      DateTime.now().subtract(Duration(days: _elapsedWeeks * 7));

  DateTime get targetDate =>
      baselineDate.add(Duration(days: _totalPlannedWeeks * 7));

  DateTime get reviewDate => DateTime.now();

  Goal buildSyntheticGoal() {
    final sign = _preset == GoalPreset.loseWeight
        ? -1.0
        : (_preset == GoalPreset.gainWeight ? 1.0 : 0.0);
    return Goal(
      id: 'sandbox-goal-id',
      preset: _preset,
      title: _preset == GoalPreset.loseWeight
          ? 'Gewicht verlieren (Sandbox)'
          : (_preset == GoalPreset.gainWeight
              ? 'Gewicht aufbauen (Sandbox)'
              : 'Gewicht halten (Sandbox)'),
      reason: 'Sandbox Testziel für die Adaptive Engine',
      status: GoalStatus.active,
      startDate: baselineDate,
      targetDate: targetDate,
      targetMetric: 'weight',
      targetValue: _targetWeightKg,
      targetUnit: 'kg',
      desiredWeeklyRateKg: sign * _desiredWeeklyRateKg,
      isNutritionDriver: true,
      createdAt: baselineDate,
      updatedAt: DateTime.now(),
    );
  }

  GoalReviewAssessment evaluateAssessment() {
    final goal = buildSyntheticGoal();
    return WeeklyGoalTrajectoryAssessmentService.evaluate(
      goal: goal,
      baselineDate: baselineDate,
      baselineValue: _baselineWeightKg,
      reviewDate: reviewDate,
      currentSmoothedValue: _currentWeightKg,
      recentRateKgPerWeek: _recentRateKgPerWeek,
      operatingRateKgPerWeek: _operatingRateKgPerWeek,
      weightObservationCount: _weightObservationCount,
      nutritionLoggedDays: _nutritionLoggedDays,
      averageLoggedCalories: _averageLoggedCalories.toDouble(),
      currentCalories: _currentCalories,
    );
  }

  GoalReviewRecord buildSyntheticReviewRecord() {
    final assessment = evaluateAssessment();
    final canAdjust = assessment.nutritionAction == 'adjust_targets';

    return GoalReviewRecord(
      id: 'sandbox-review-${DateTime.now().millisecondsSinceEpoch}',
      goalId: 'sandbox-goal-id',
      windowStart: reviewDate.subtract(const Duration(days: 7)),
      windowEnd: reviewDate,
      status: 'pending',
      trajectoryStatus: assessment.overallStatus,
      observedRateKgPerWeek: _recentRateKgPerWeek,
      confidenceLevel:
          assessment.dataQuality == 'sufficient' ? 'high' : 'uncalibrated',
      tdeeEstimate: _tdeeEstimate,
      recommendedCalories: canAdjust ? _recommendedCalories : null,
      recommendedProtein: canAdjust ? _recommendedProtein : null,
      recommendedCarbs: canAdjust ? _recommendedCarbs : null,
      recommendedFat: canAdjust ? _recommendedFat : null,
      algorithmVersion: 'weekly_goal_review_2_0',
      explanation: buildExplanation(assessment),
      assessment: assessment,
      createdAt: DateTime.now(),
    );
  }

  String buildExplanation(GoalReviewAssessment assessment) {
    switch (assessment.nutritionAction) {
      case 'insufficient_data':
        return 'Train Libre kalibriert sich noch auf deine Daten. Für eine verlässliche Empfehlung fehlen in den letzten 7 Tagen noch Wiegungen oder Kalorientage.';
      case 'trajectory_change_needed':
        return 'Dein Zieldatum liegt in der Vergangenheit oder erfordert eine physiologisch bedenkliche Anpassungsrate. Passe deinen Plan an.';
      case 'keep_targets_intake_differs':
        return 'Dein Gewichtsverlauf weicht ab, aber die getrackten Kalorien erklären den Unterschied. Behalte deine Zielkalorien bei.';
      case 'adjust_targets':
        return 'Dein Gewichtsverlauf weicht trotz Einhaltung der Zielkalorien vom Plan ab. Die Engine schlägt eine Kalorienanpassung vor.';
      case 'keep_targets':
      default:
        return 'Alles läuft planmäßig! Deine aktuellen Ziele unterstützen deinen Weg optimal.';
    }
  }

  void loadScenarioValues({
    required GoalPreset preset,
    required double baselineWeight,
    required double targetWeight,
    required int totalWeeks,
    required int elapsedWeeks,
    required double currentWeight,
    required double recentRate,
    required double operatingRate,
    required int weightObservations,
    required int loggedDays,
    required int currentCalories,
    required int averageLoggedCalories,
    required double tdee,
    int? recommendedCalories,
  }) {
    _preset = preset;
    _baselineWeightKg = baselineWeight;
    _targetWeightKg = targetWeight;
    _totalPlannedWeeks = totalWeeks;
    _elapsedWeeks = elapsedWeeks;
    _currentWeightKg = currentWeight;
    _recentRateKgPerWeek = recentRate;
    _operatingRateKgPerWeek = operatingRate;
    _weightObservationCount = weightObservations;
    _nutritionLoggedDays = loggedDays;
    _currentCalories = currentCalories;
    _averageLoggedCalories = averageLoggedCalories;
    _tdeeEstimate = tdee;
    if (recommendedCalories != null) {
      _recommendedCalories = recommendedCalories;
    }
    _recalculateDerivedPace();
    notifyListeners();
  }
}
