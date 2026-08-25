import 'dart:convert';

import 'set_log.dart';

/// Represents a completed or ongoing workout session.
///
/// Tracks the start time, end time, and all sets performed during the session.
class WorkoutLog {
  /// Unique identifier for the workout log.
  final int? id;

  /// The name of the routine used for this workout, if any.
  final String? routineName;

  /// The UUID of the routine used for this workout, if any.
  final String? routineId;

  /// The exact time when the workout session started.
  final DateTime startTime;

  /// The exact time when the workout session ended.
  ///
  /// Can be null if the workout is still in progress.
  final DateTime? endTime;

  /// Optional notes or reflections on the workout session.
  final String? notes;

  /// Original start zone offset in minutes when available.
  final int? startZoneOffsetMinutes;

  /// Original end zone offset in minutes when available.
  final int? endZoneOffsetMinutes;

  /// A list of all [SetLog] entries recorded during this workout.
  final List<SetLog> sets;

  /// Every photo of this workout, relative to the application support directory.
  final List<String> photoPaths;

  /// Creates a new [WorkoutLog] instance.
  WorkoutLog({
    this.id,
    this.routineName,
    this.routineId,
    required this.startTime,
    this.endTime,
    this.notes,
    this.startZoneOffsetMinutes,
    this.endZoneOffsetMinutes,
    this.photoPaths = const [],
    this.sets = const [],
  });

  /// Creates a copy of this [WorkoutLog] with the given fields replaced.
  WorkoutLog copyWith({
    int? id,
    String? routineName,
    String? routineId,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    int? startZoneOffsetMinutes,
    int? endZoneOffsetMinutes,
    List<String>? photoPaths,
    List<SetLog>? sets,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      routineName: routineName ?? this.routineName,
      routineId: routineId ?? this.routineId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      startZoneOffsetMinutes:
          startZoneOffsetMinutes ?? this.startZoneOffsetMinutes,
      endZoneOffsetMinutes: endZoneOffsetMinutes ?? this.endZoneOffsetMinutes,
      photoPaths: photoPaths ?? this.photoPaths,
      sets: sets ?? this.sets,
    );
  }

  /// Creates a [WorkoutLog] instance from a Map, typically from a database row.
  ///
  /// The [sets] list is optional and can be provided if already fetched.
  factory WorkoutLog.fromMap(
    Map<String, dynamic> map, {
    List<SetLog> sets = const [],
  }) {
    List<String> paths = const [];
    if (map['photo_paths'] is List) {
      paths = (map['photo_paths'] as List).whereType<String>().toList();
    } else if (map['photo_path'] is String &&
        (map['photo_path'] as String).isNotEmpty) {
      final first = map['photo_path'] as String;
      final extras = <String>[];
      if (map['photo_extra_paths'] is String &&
          (map['photo_extra_paths'] as String).isNotEmpty) {
        try {
          final decoded = jsonDecode(map['photo_extra_paths'] as String);
          if (decoded is List) {
            extras.addAll(decoded.whereType<String>());
          }
        } catch (_) {}
      }
      paths = [first, ...extras];
    }

    return WorkoutLog(
      id: map['id'],
      routineName: map['routine_name'] ?? map['routineNameSnapshot'],
      routineId: map['routine_id'] ?? map['routineId'],
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      notes: map['notes'],
      photoPaths: paths,
      sets: sets,
    );
  }

  /// Converts the [WorkoutLog] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routine_name': routineName,
      'routine_id': routineId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
      if (photoPaths.isNotEmpty) 'photo_paths': photoPaths,
    };
  }
}
