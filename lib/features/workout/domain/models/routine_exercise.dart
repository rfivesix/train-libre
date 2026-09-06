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

/// Reorders a single item from [oldIndex] to [newIndex] within a list that may
/// contain contiguous superset groups.
///
/// Rules:
/// 1. If the item stays adjacent to any member of its original superset group,
///    it retains that group (e.g. swapping positions within the superset).
/// 2. If the item is dropped strictly between two members of another superset
///    group, it joins that superset group (e.g. turning a pair into a triset).
/// 3. In all other cases (e.g. moved away from its superset, moved to workout
///    edges, or placed adjacent to the outer border of another superset), its
///    superset group is cleared.
/// 4. Finally, normalization is applied to dissolve any singletons (groups with
///    fewer than 2 members) and resolve broken non-contiguous runs.
List<T> reorderWithSupersets<T>({
  required List<T> items,
  required int oldIndex,
  required int newIndex,
  required int? Function(T item) getGroup,
  required T Function(T item, int? group) withGroup,
}) {
  if (oldIndex < 0 || oldIndex >= items.length || items.isEmpty) {
    return List.of(items);
  }
  final remaining = List<T>.of(items);
  final moving = remaining.removeAt(oldIndex);
  final targetIndex = newIndex.clamp(0, remaining.length);

  final oldGroup = getGroup(moving);
  final prevNeighbor = targetIndex > 0 ? remaining[targetIndex - 1] : null;
  final nextNeighbor =
      targetIndex < remaining.length ? remaining[targetIndex] : null;
  final prevGroup = prevNeighbor != null ? getGroup(prevNeighbor) : null;
  final nextGroup = nextNeighbor != null ? getGroup(nextNeighbor) : null;

  int? newGroup;
  if (oldGroup != null && (prevGroup == oldGroup || nextGroup == oldGroup)) {
    newGroup = oldGroup;
  } else if (prevGroup != null && prevGroup == nextGroup) {
    newGroup = prevGroup;
  } else {
    newGroup = null;
  }

  remaining.insert(targetIndex, withGroup(moving, newGroup));

  return normalizeListWithSupersets(
    remaining,
    getGroup: getGroup,
    withGroup: withGroup,
  );
}

/// Generic normalization of superset groups in a list of items.
List<T> normalizeListWithSupersets<T>(
  List<T> items, {
  required int? Function(T item) getGroup,
  required T Function(T item, int? group) withGroup,
}) {
  final runCountByGroup = <int, int>{};
  int? previousGroup;
  for (final item in items) {
    final group = getGroup(item);
    if (group != null && group != previousGroup) {
      runCountByGroup[group] = (runCountByGroup[group] ?? 0) + 1;
    }
    previousGroup = group;
  }

  final memberCountByGroup = <int, int>{};
  for (final item in items) {
    final group = getGroup(item);
    if (group != null) {
      memberCountByGroup[group] = (memberCountByGroup[group] ?? 0) + 1;
    }
  }

  return items.map((item) {
    final group = getGroup(item);
    final valid = group == null ||
        (runCountByGroup[group] == 1 && (memberCountByGroup[group] ?? 0) >= 2);
    return valid ? item : withGroup(item, null);
  }).toList();
}

/// Reorders a single exercise from [oldIndex] to [newIndex], handling superset
/// preservation, insertion, and cleanup.
List<RoutineExercise> reorderRoutineExercise(
  List<RoutineExercise> exercises,
  int oldIndex,
  int newIndex,
) {
  return reorderWithSupersets<RoutineExercise>(
    items: exercises,
    oldIndex: oldIndex,
    newIndex: newIndex,
    getGroup: (e) => e.supersetGroup,
    withGroup: (e, group) => group == null
        ? e.copyWith(clearSupersetGroup: true)
        : e.copyWith(supersetGroup: group),
  );
}

/// Backwards compatibility alias for [reorderRoutineExercise].
List<RoutineExercise> moveRoutineExerciseGroup(
  List<RoutineExercise> exercises,
  int oldIndex,
  int newIndex,
) =>
    reorderRoutineExercise(exercises, oldIndex, newIndex);

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
