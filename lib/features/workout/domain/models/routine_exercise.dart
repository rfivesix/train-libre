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

class SupersetMembership {
  final int group;
  final int groupIndex;
  final int memberIndex;
  final int memberCount;

  const SupersetMembership({
    required this.group,
    required this.groupIndex,
    required this.memberIndex,
    required this.memberCount,
  });

  bool get isFirst => memberIndex == 0;
  bool get isLast => memberIndex == memberCount - 1;
  String get label => '${_alphabeticLabel(groupIndex)}${memberIndex + 1}';
}

SupersetMembership? supersetMembershipAt(
  List<RoutineExercise> exercises,
  int index,
) {
  if (index < 0 || index >= exercises.length) return null;
  final group = exercises[index].supersetGroup;
  if (group == null) return null;

  final groups = <int>[];
  for (final exercise in exercises) {
    final current = exercise.supersetGroup;
    if (current != null && !groups.contains(current)) groups.add(current);
  }

  var start = index;
  while (start > 0 && exercises[start - 1].supersetGroup == group) {
    start--;
  }
  var end = index;
  while (
      end + 1 < exercises.length && exercises[end + 1].supersetGroup == group) {
    end++;
  }

  return SupersetMembership(
    group: group,
    groupIndex: groups.indexOf(group),
    memberIndex: index - start,
    memberCount: end - start + 1,
  );
}

List<RoutineExercise> moveRoutineExerciseGroup(
  List<RoutineExercise> exercises,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= exercises.length || exercises.isEmpty) {
    return List.of(exercises);
  }
  final targetIndex = newIndex.clamp(0, exercises.length - 1);
  final sourceRange = _groupRangeAt(exercises, oldIndex);
  if (targetIndex >= sourceRange.$1 && targetIndex <= sourceRange.$2) {
    return List.of(exercises);
  }
  final targetRange = _groupRangeAt(exercises, targetIndex);
  final moving = exercises.sublist(sourceRange.$1, sourceRange.$2 + 1);
  final result = List<RoutineExercise>.of(exercises)
    ..removeRange(sourceRange.$1, sourceRange.$2 + 1);

  final sourceLength = sourceRange.$2 - sourceRange.$1 + 1;
  final insertionIndex = oldIndex < targetIndex
      ? targetRange.$2 - sourceLength + 1
      : targetRange.$1;
  result.insertAll(insertionIndex.clamp(0, result.length), moving);
  return normalizeSupersetGroups(result);
}

/// Toggles the connection between two adjacent exercises.
///
/// Connecting merges their complete contiguous groups. Disconnecting preserves
/// each side of a larger group as its own superset instead of clearing the
/// entire group. A side with one exercise is intentionally left ungrouped.
List<RoutineExercise> toggleSupersetConnectionAfter(
  List<RoutineExercise> exercises,
  int upperIndex,
) {
  if (upperIndex < 0 || upperIndex + 1 >= exercises.length) {
    return List.of(exercises);
  }

  final result = List<RoutineExercise>.of(exercises);
  final upper = result[upperIndex];
  final lower = result[upperIndex + 1];
  final upperGroup = upper.supersetGroup;
  final lowerGroup = lower.supersetGroup;

  if (upperGroup != null && upperGroup == lowerGroup) {
    final range = _groupRangeAt(result, upperIndex);
    final leftStart = range.$1;
    final leftEnd = upperIndex;
    final rightStart = upperIndex + 1;
    final rightEnd = range.$2;
    final nextGroup = _nextSupersetGroup(result);

    for (var index = leftStart; index <= leftEnd; index++) {
      result[index] = result[index].copyWith(
        clearSupersetGroup: leftEnd == leftStart,
        supersetGroup: upperGroup,
      );
    }
    for (var index = rightStart; index <= rightEnd; index++) {
      result[index] = result[index].copyWith(
        clearSupersetGroup: rightEnd == rightStart,
        supersetGroup: nextGroup,
      );
    }
  } else {
    final upperRange = _groupRangeAt(result, upperIndex);
    final lowerRange = _groupRangeAt(result, upperIndex + 1);
    final mergedGroup = upperGroup ?? lowerGroup ?? _nextSupersetGroup(result);
    for (var index = upperRange.$1; index <= lowerRange.$2; index++) {
      result[index] = result[index].copyWith(supersetGroup: mergedGroup);
    }
  }

  return normalizeSupersetGroups(result);
}

int _nextSupersetGroup(List<RoutineExercise> exercises) {
  var maxGroup = 0;
  for (final exercise in exercises) {
    final group = exercise.supersetGroup;
    if (group != null && group > maxGroup) maxGroup = group;
  }
  return maxGroup + 1;
}

(int, int) _groupRangeAt(List<RoutineExercise> exercises, int index) {
  final group = exercises[index].supersetGroup;
  if (group == null) return (index, index);
  var start = index;
  var end = index;
  while (start > 0 && exercises[start - 1].supersetGroup == group) {
    start--;
  }
  while (
      end + 1 < exercises.length && exercises[end + 1].supersetGroup == group) {
    end++;
  }
  return (start, end);
}

String _alphabeticLabel(int index) {
  var value = index + 1;
  final buffer = StringBuffer();
  while (value > 0) {
    value--;
    buffer.writeCharCode(65 + value % 26);
    value ~/= 26;
  }
  return buffer.toString().split('').reversed.join();
}
