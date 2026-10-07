import 'dart:convert';

import '../../../exercise_catalog/domain/models/exercise.dart';
import 'routine.dart';
import 'routine_exercise.dart';
import 'set_template.dart';

enum TrainingPlanKind { week, sequence }

enum PlannedDayStatus { rest, planned, ongoing, completed, partial, skipped }

/// An authored day contains no generated training advice. Its routine snapshot
/// is frozen with the plan revision so history survives template edits/deletion.
class TrainingPlanDay {
  const TrainingPlanDay({this.routineUuid, this.routineSnapshot});

  final String? routineUuid;
  final Map<String, dynamic>? routineSnapshot;
  bool get isRest => routineSnapshot == null;
  String? get routineName => routineSnapshot?['name'] as String?;

  Map<String, dynamic> toJson() => {
        'routineUuid': routineUuid,
        'routineSnapshot': routineSnapshot,
      };

  factory TrainingPlanDay.fromJson(Map<String, dynamic> json) =>
      TrainingPlanDay(
        routineUuid: json['routineUuid'] as String?,
        routineSnapshot: json['routineSnapshot'] == null
            ? null
            : Map<String, dynamic>.from(json['routineSnapshot'] as Map),
      );

  Routine? get routine {
    final raw = routineSnapshot;
    if (raw == null) return null;
    return Routine(
      id: (raw['id'] as num?)?.toInt(),
      name: raw['name'] as String,
      exercises: (raw['exercises'] as List<dynamic>? ?? []).map((item) {
        final row = Map<String, dynamic>.from(item as Map);
        return RoutineExercise(
          id: (row['id'] as num?)?.toInt(),
          exercise: Exercise.fromMap(
              Map<String, dynamic>.from(row['exercise'] as Map)),
          setTemplates: (row['setTemplates'] as List<dynamic>? ?? [])
              .map((set) =>
                  SetTemplate.fromMap(Map<String, dynamic>.from(set as Map)))
              .toList(),
          pauseSeconds: (row['pause_seconds'] as num?)?.toInt(),
          supersetGroup: (row['superset_group'] as num?)?.toInt(),
          notes: row['notes'] as String?,
          progressionData: row['progression_data'] as String?,
        );
      }).toList(),
    );
  }

  static String encodeDays(List<TrainingPlanDay> days) =>
      jsonEncode(days.map((day) => day.toJson()).toList());

  static List<TrainingPlanDay> decodeDays(String value) =>
      (jsonDecode(value) as List<dynamic>)
          .map((day) =>
              TrainingPlanDay.fromJson(Map<String, dynamic>.from(day as Map)))
          .toList();
}

class ManualTrainingPlan {
  const ManualTrainingPlan({
    required this.id,
    required this.name,
    required this.kind,
    required this.days,
    required this.revisionId,
    required this.revisionNumber,
    required this.active,
    this.activationId,
    this.startedOn,
  });

  final String id;
  final String name;
  final TrainingPlanKind kind;
  final List<TrainingPlanDay> days;
  final String revisionId;
  final int revisionNumber;
  final bool active;
  final String? activationId;
  final DateTime? startedOn;
}

class PlannedCalendarDay {
  const PlannedCalendarDay({
    required this.date,
    required this.slotIndex,
    required this.day,
    required this.status,
    this.occurrenceId,
    this.workoutLogId,
    this.revisionId,
  });

  final DateTime date;
  final int slotIndex;
  final TrainingPlanDay day;
  final PlannedDayStatus status;
  final String? occurrenceId;
  final int? workoutLogId;
  final String? revisionId;
}
