import 'set_log.dart';

/// Stable identity for one exercise card in a workout log.
///
/// Modern rows use [exerciseBlock], allowing the same exercise to appear in
/// multiple cards. Legacy rows have no block and intentionally retain the old
/// name-based grouping behavior.
class ExerciseBlockKey {
  final int? exerciseBlock;
  final String exerciseName;

  const ExerciseBlockKey({
    required this.exerciseBlock,
    required this.exerciseName,
  });

  factory ExerciseBlockKey.fromSet(SetLog set) => ExerciseBlockKey(
        exerciseBlock: set.exerciseBlock,
        exerciseName: set.exerciseName,
      );

  Object get anchorId =>
      exerciseBlock == null ? 'legacy:$exerciseName' : 'block:$exerciseBlock';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ExerciseBlockKey) return false;
    if (exerciseBlock != null || other.exerciseBlock != null) {
      return exerciseBlock != null && exerciseBlock == other.exerciseBlock;
    }
    return exerciseName == other.exerciseName;
  }

  @override
  int get hashCode => exerciseBlock == null
      ? Object.hash('legacy', exerciseName)
      : Object.hash('block', exerciseBlock);
}

Map<ExerciseBlockKey, List<SetLog>> groupSetsByExerciseBlock(
  Iterable<SetLog> sets,
) {
  final groups = <ExerciseBlockKey, List<SetLog>>{};
  for (final set in sets) {
    groups.putIfAbsent(ExerciseBlockKey.fromSet(set), () => []).add(set);
  }
  return groups;
}
