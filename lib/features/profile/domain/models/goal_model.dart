// lib/features/profile/domain/models/goal_model.dart

import 'dart:convert';

enum GoalStatus {
  active,
  retired,
  superseded,
  draft;

  static GoalStatus fromString(String value) {
    switch (value) {
      case 'active':
        return GoalStatus.active;
      case 'retired':
        return GoalStatus.retired;
      case 'superseded':
        return GoalStatus.superseded;
      case 'draft':
        return GoalStatus.draft;
      default:
        return GoalStatus.active;
    }
  }

  String get key => name;
}

enum GoalPreset {
  loseWeight,
  gainWeight,
  maintainWeight,
  recomposition,
  custom;

  static GoalPreset fromString(String value) {
    switch (value) {
      case 'loseWeight':
        return GoalPreset.loseWeight;
      case 'gainWeight':
        return GoalPreset.gainWeight;
      case 'maintainWeight':
        return GoalPreset.maintainWeight;
      case 'recomposition':
        return GoalPreset.recomposition;
      case 'custom':
        return GoalPreset.custom;
      default:
        return GoalPreset.custom;
    }
  }

  String get key => name;
}

enum GoalTrackingMode {
  open,
  weeklyRate,
  targetWeight;

  static GoalTrackingMode fromString(String? value) => switch (value) {
        'open' => GoalTrackingMode.open,
        'targetWeight' => GoalTrackingMode.targetWeight,
        _ => GoalTrackingMode.weeklyRate,
      };
}

class Goal {
  final String id;
  final String? userId;
  final String area;
  final GoalPreset preset;
  final String title;
  final String? reason;
  final GoalStatus status;
  final DateTime startDate;
  final GoalTrackingMode trackingMode;
  final String? baselineMeasurementId;
  final double? baselineValueKg;
  final DateTime? baselineDate;
  final DateTime? targetDate;
  final String? targetMetric;
  final double? targetValue;
  final String? targetUnit;
  final double? desiredWeeklyRateKg;
  final bool isNutritionDriver;
  final String? predecessorGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? retiredAt;

  const Goal({
    required this.id,
    this.userId,
    this.area = 'body_composition',
    required this.preset,
    required this.title,
    this.reason,
    this.status = GoalStatus.active,
    required this.startDate,
    this.trackingMode = GoalTrackingMode.weeklyRate,
    this.baselineMeasurementId,
    this.baselineValueKg,
    this.baselineDate,
    this.targetDate,
    this.targetMetric,
    this.targetValue,
    this.targetUnit,
    this.desiredWeeklyRateKg,
    this.isNutritionDriver = false,
    this.predecessorGoalId,
    required this.createdAt,
    required this.updatedAt,
    this.retiredAt,
  });

  bool get isActive => status == GoalStatus.active;
  bool get isRetired => status == GoalStatus.retired;
  bool get isSuperseded => status == GoalStatus.superseded;

  bool get isWeightGoal =>
      targetMetric == 'weight' ||
      preset == GoalPreset.loseWeight ||
      preset == GoalPreset.gainWeight ||
      preset == GoalPreset.maintainWeight;

  bool get isMaintenanceOrRecomp =>
      preset == GoalPreset.maintainWeight || preset == GoalPreset.recomposition;

  bool get hasNumericTarget => targetValue != null;
  bool get hasTargetDate => targetDate != null;
  bool get isDirectionalOnly => targetValue == null && targetDate == null;

  Goal copyWith({
    String? id,
    String? userId,
    String? area,
    GoalPreset? preset,
    String? title,
    String? reason,
    GoalStatus? status,
    DateTime? startDate,
    GoalTrackingMode? trackingMode,
    String? baselineMeasurementId,
    double? baselineValueKg,
    DateTime? baselineDate,
    DateTime? targetDate,
    String? targetMetric,
    double? targetValue,
    String? targetUnit,
    double? desiredWeeklyRateKg,
    bool? isNutritionDriver,
    String? predecessorGoalId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? retiredAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      area: area ?? this.area,
      preset: preset ?? this.preset,
      title: title ?? this.title,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      trackingMode: trackingMode ?? this.trackingMode,
      baselineMeasurementId:
          baselineMeasurementId ?? this.baselineMeasurementId,
      baselineValueKg: baselineValueKg ?? this.baselineValueKg,
      baselineDate: baselineDate ?? this.baselineDate,
      targetDate: targetDate ?? this.targetDate,
      targetMetric: targetMetric ?? this.targetMetric,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      desiredWeeklyRateKg: desiredWeeklyRateKg ?? this.desiredWeeklyRateKg,
      isNutritionDriver: isNutritionDriver ?? this.isNutritionDriver,
      predecessorGoalId: predecessorGoalId ?? this.predecessorGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      retiredAt: retiredAt ?? this.retiredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'area': area,
      'preset': preset.key,
      'title': title,
      'reason': reason,
      'status': status.key,
      'start_date': startDate.toIso8601String(),
      'tracking_mode': trackingMode.name,
      'baseline_measurement_id': baselineMeasurementId,
      'baseline_value_kg': baselineValueKg,
      'baseline_date': baselineDate?.toIso8601String(),
      'target_date': targetDate?.toIso8601String(),
      'target_metric': targetMetric,
      'target_value': targetValue,
      'target_unit': targetUnit,
      'desired_weekly_rate_kg': desiredWeeklyRateKg,
      'is_nutrition_driver': isNutritionDriver,
      'predecessor_goal_id': predecessorGoalId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'retired_at': retiredAt?.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      area: (map['area'] as String?) ?? 'body_composition',
      preset: GoalPreset.fromString(map['preset'] as String),
      title: map['title'] as String,
      reason: map['reason'] as String?,
      status: GoalStatus.fromString(map['status'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      trackingMode:
          GoalTrackingMode.fromString(map['tracking_mode'] as String?),
      baselineMeasurementId: map['baseline_measurement_id'] as String?,
      baselineValueKg: (map['baseline_value_kg'] as num?)?.toDouble(),
      baselineDate: map['baseline_date'] == null
          ? null
          : DateTime.parse(map['baseline_date'] as String),
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      targetMetric: map['target_metric'] as String?,
      targetValue: (map['target_value'] as num?)?.toDouble(),
      targetUnit: map['target_unit'] as String?,
      desiredWeeklyRateKg: (map['desired_weekly_rate_kg'] as num?)?.toDouble(),
      isNutritionDriver: (map['is_nutrition_driver'] as bool?) ?? false,
      predecessorGoalId: map['predecessor_goal_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      retiredAt: map['retired_at'] != null
          ? DateTime.parse(map['retired_at'] as String)
          : null,
    );
  }
}

class GoalEvent {
  final String id;
  final String goalId;
  final String eventType; // 'created', 'superseded', 'retired', 'resumed'
  final String actor; // 'user', 'user_accepted_recommendation', 'engine'
  final String? recommendationId;
  final String? reason;
  final String? algorithmVersion;
  final DateTime? occurredAt;
  final DateTime createdAt;

  const GoalEvent({
    required this.id,
    required this.goalId,
    required this.eventType,
    this.actor = 'user',
    this.recommendationId,
    this.reason,
    this.algorithmVersion,
    this.occurredAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'event_type': eventType,
      'actor': actor,
      'recommendation_id': recommendationId,
      'reason': reason,
      'algorithm_version': algorithmVersion,
      'occurred_at': occurredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalEvent.fromMap(Map<String, dynamic> map) {
    return GoalEvent(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      eventType: map['event_type'] as String,
      actor: (map['actor'] as String?) ?? 'user',
      recommendationId: map['recommendation_id'] as String?,
      reason: map['reason'] as String?,
      algorithmVersion: map['algorithm_version'] as String?,
      occurredAt: map['occurred_at'] != null
          ? DateTime.parse(map['occurred_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class GoalReviewRecord {
  final String id;
  final String goalId;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String
      status; // 'pending', 'applied', 'deferred', 'dismissed', 'goal_changed'
  final String?
      trajectoryStatus; // 'on_track', 'slower', 'faster', 'calibrating'
  final double? observedRateKgPerWeek;
  final String? confidenceLevel; // 'high', 'moderate', 'low', 'uncalibrated'
  final double? tdeeEstimate;
  final int? recommendedCalories;
  final int? recommendedProtein;
  final int? recommendedCarbs;
  final int? recommendedFat;
  final String? decision;
  final String algorithmVersion;
  final String? explanation;
  final GoalReviewAssessment? assessment;
  final DateTime createdAt;

  const GoalReviewRecord({
    required this.id,
    required this.goalId,
    required this.windowStart,
    required this.windowEnd,
    this.status = 'pending',
    this.trajectoryStatus,
    this.observedRateKgPerWeek,
    this.confidenceLevel,
    this.tdeeEstimate,
    this.recommendedCalories,
    this.recommendedProtein,
    this.recommendedCarbs,
    this.recommendedFat,
    this.decision,
    required this.algorithmVersion,
    this.explanation,
    this.assessment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'window_start': windowStart.toIso8601String(),
      'window_end': windowEnd.toIso8601String(),
      'status': status,
      'trajectory_status': trajectoryStatus,
      'observed_rate_kg_per_week': observedRateKgPerWeek,
      'confidence_level': confidenceLevel,
      'tdee_estimate': tdeeEstimate,
      'recommended_calories': recommendedCalories,
      'recommended_protein': recommendedProtein,
      'recommended_carbs': recommendedCarbs,
      'recommended_fat': recommendedFat,
      'decision': decision,
      'algorithm_version': algorithmVersion,
      'explanation': explanation,
      'assessment_json':
          assessment == null ? null : jsonEncode(assessment!.toMap()),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GoalReviewRecord.fromMap(Map<String, dynamic> map) {
    return GoalReviewRecord(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      windowStart: DateTime.parse(map['window_start'] as String),
      windowEnd: DateTime.parse(map['window_end'] as String),
      status: (map['status'] as String?) ?? 'pending',
      trajectoryStatus: map['trajectory_status'] as String?,
      observedRateKgPerWeek:
          (map['observed_rate_kg_per_week'] as num?)?.toDouble(),
      confidenceLevel: map['confidence_level'] as String?,
      tdeeEstimate: (map['tdee_estimate'] as num?)?.toDouble(),
      recommendedCalories: map['recommended_calories'] as int?,
      recommendedProtein: map['recommended_protein'] as int?,
      recommendedCarbs: map['recommended_carbs'] as int?,
      recommendedFat: map['recommended_fat'] as int?,
      decision: map['decision'] as String?,
      algorithmVersion: map['algorithm_version'] as String,
      explanation: map['explanation'] as String?,
      assessment:
          GoalReviewAssessment.tryParse(map['assessment_json'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class GoalReviewAssessment {
  final String overallStatus;
  final String recentMomentumStatus;
  final double? baselineValue;
  final double? expectedValue;
  final double? currentSmoothedValue;
  final double? trajectoryGap;
  final double? plannedRateKgPerWeek;
  final double? recentRateKgPerWeek;
  final double? overallRateKgPerWeek;
  final double? requiredRemainingRateKgPerWeek;
  final DateTime? projectedTargetDate;
  final int weightObservationCount;
  final int nutritionLoggedDays;
  final double? averageLoggedCalories;
  final String dataQuality;
  final String nutritionAction;

  const GoalReviewAssessment({
    required this.overallStatus,
    required this.recentMomentumStatus,
    this.baselineValue,
    this.expectedValue,
    this.currentSmoothedValue,
    this.trajectoryGap,
    this.plannedRateKgPerWeek,
    this.recentRateKgPerWeek,
    this.overallRateKgPerWeek,
    this.requiredRemainingRateKgPerWeek,
    this.projectedTargetDate,
    required this.weightObservationCount,
    required this.nutritionLoggedDays,
    this.averageLoggedCalories,
    required this.dataQuality,
    required this.nutritionAction,
  });

  Map<String, dynamic> toMap() => {
        'overallStatus': overallStatus,
        'recentMomentumStatus': recentMomentumStatus,
        'baselineValue': baselineValue,
        'expectedValue': expectedValue,
        'currentSmoothedValue': currentSmoothedValue,
        'trajectoryGap': trajectoryGap,
        'plannedRateKgPerWeek': plannedRateKgPerWeek,
        'recentRateKgPerWeek': recentRateKgPerWeek,
        'overallRateKgPerWeek': overallRateKgPerWeek,
        'requiredRemainingRateKgPerWeek': requiredRemainingRateKgPerWeek,
        'projectedTargetDate': projectedTargetDate?.toIso8601String(),
        'weightObservationCount': weightObservationCount,
        'nutritionLoggedDays': nutritionLoggedDays,
        'averageLoggedCalories': averageLoggedCalories,
        'dataQuality': dataQuality,
        'nutritionAction': nutritionAction,
      };

  factory GoalReviewAssessment.fromMap(Map<String, dynamic> map) =>
      GoalReviewAssessment(
        overallStatus: map['overallStatus'] as String? ?? 'calibrating',
        recentMomentumStatus:
            map['recentMomentumStatus'] as String? ?? 'unclear',
        baselineValue: (map['baselineValue'] as num?)?.toDouble(),
        expectedValue: (map['expectedValue'] as num?)?.toDouble(),
        currentSmoothedValue: (map['currentSmoothedValue'] as num?)?.toDouble(),
        trajectoryGap: (map['trajectoryGap'] as num?)?.toDouble(),
        plannedRateKgPerWeek: (map['plannedRateKgPerWeek'] as num?)?.toDouble(),
        recentRateKgPerWeek: (map['recentRateKgPerWeek'] as num?)?.toDouble(),
        overallRateKgPerWeek: (map['overallRateKgPerWeek'] as num?)?.toDouble(),
        requiredRemainingRateKgPerWeek:
            (map['requiredRemainingRateKgPerWeek'] as num?)?.toDouble(),
        projectedTargetDate: map['projectedTargetDate'] == null
            ? null
            : DateTime.tryParse(map['projectedTargetDate'] as String),
        weightObservationCount: map['weightObservationCount'] as int? ?? 0,
        nutritionLoggedDays: map['nutritionLoggedDays'] as int? ?? 0,
        averageLoggedCalories:
            (map['averageLoggedCalories'] as num?)?.toDouble(),
        dataQuality: map['dataQuality'] as String? ?? 'insufficient',
        nutritionAction:
            map['nutritionAction'] as String? ?? 'insufficient_data',
      );

  static GoalReviewAssessment? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? GoalReviewAssessment.fromMap(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }
}
