// lib/models/routine.dart
import 'routine_exercise.dart';

/// Represents a structured workout plan or routine.
///
/// A routine consists of a name and a sequence of exercises to be performed.
class Routine {
  /// Unique identifier for the routine.
  final int? id;

  /// The name of the routine (e.g., "Leg Day", "Push A").
  final String name;

  /// The list of exercises included in this routine.
  final List<RoutineExercise> exercises;

  /// Timestamp when the routine was last used (created, saved, or started).
  final DateTime? lastUsedAt;

  /// Timestamp when the routine was originally created.
  final DateTime? createdAt;

  /// Creates a new [Routine] instance.
  Routine({
    this.id,
    required this.name,
    this.exercises = const [],
    this.lastUsedAt,
    this.createdAt,
  });

  /// Converts the [Routine] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((re) => re.toMap()).toList(),
      if (lastUsedAt != null) 'last_used_at': lastUsedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
