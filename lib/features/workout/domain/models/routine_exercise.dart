// lib/models/routine_exercise.dart

import '../../../exercise_catalog/domain/models/exercise.dart';
import 'set_template.dart';

/// Represents an exercise associated with a specific routine.
///
/// Links an [Exercise] to a [Routine] and includes templates for sets and pause duration.
class RoutineExercise {
  /// Unique identifier for the routine-exercise association.
  final int? id;

  /// The underlying [Exercise] definition.
  final Exercise exercise;

  /// A list of template sets to be pre-filled when starting a workout with this routine.
  List<SetTemplate> setTemplates;

  /// The recommended pause duration between sets in seconds.
  final int? pauseSeconds; // New field

  /// Identifier of the contiguous superset group within the routine.
  final int? supersetGroup;

  /// Optional notes or instructional reminders for the exercise.
  final String? notes;

  /// Creates a new [RoutineExercise] instance.
  RoutineExercise({
    this.id,
    required this.exercise,
    this.setTemplates = const [],
    this.pauseSeconds, // New field
    this.supersetGroup,
    this.notes,
  });

  /// Converts the [RoutineExercise] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise': exercise.toMap(), // Assumption: Exercise has a toMap method
      'setTemplates': setTemplates.map((st) => st.toMap()).toList(),
      'pause_seconds': pauseSeconds,
      'superset_group': supersetGroup,
      'notes': notes,
    };
  }

  /// Creates a copy of this [RoutineExercise] with the given fields replaced by the new values.
  RoutineExercise copyWith({
    int? id,
    Exercise? exercise,
    List<SetTemplate>? setTemplates,
    int? pauseSeconds,
    int? supersetGroup,
    String? notes,
    bool clearNotes = false,
    bool clearSupersetGroup = false,
  }) {
    return RoutineExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      setTemplates: setTemplates ?? this.setTemplates,
      pauseSeconds: pauseSeconds ?? this.pauseSeconds,
      supersetGroup:
          clearSupersetGroup ? null : (supersetGroup ?? this.supersetGroup),
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }
}

/// Clears invalid superset identifiers while preserving valid contiguous runs.
///
/// A group is valid only when it occurs in exactly one run containing at least
/// two exercises. The returned list preserves input order and object identity
/// for exercises that do not need changing.
List<RoutineExercise> normalizeSupersetGroups(
  List<RoutineExercise> exercises,
) {
  final runCountByGroup = <int, int>{};
  int? previousGroup;
  for (final exercise in exercises) {
    final group = exercise.supersetGroup;
    if (group != null && group != previousGroup) {
      runCountByGroup[group] = (runCountByGroup[group] ?? 0) + 1;
    }
    previousGroup = group;
  }

  final memberCountByGroup = <int, int>{};
  for (final exercise in exercises) {
    final group = exercise.supersetGroup;
    if (group != null) {
      memberCountByGroup[group] = (memberCountByGroup[group] ?? 0) + 1;
    }
  }

  return exercises.map((exercise) {
    final group = exercise.supersetGroup;
    final valid = group == null ||
        (runCountByGroup[group] == 1 && memberCountByGroup[group]! >= 2);
    return valid ? exercise : exercise.copyWith(clearSupersetGroup: true);
  }).toList();
}
