/// The independent sequences through which a set can be compared with a
/// previous workout. Raw row order is deliberately not a position: users are
/// free to add or remove warm-ups without shifting their working sets.
enum WorkoutSetLane { warmup, working, dropset }

class WorkoutSetPosition {
  final WorkoutSetLane lane;
  final int ordinal;

  const WorkoutSetPosition(this.lane, this.ordinal);
}

abstract final class WorkoutSetPositionMapper {
  static WorkoutSetLane laneFor(String setType) => switch (setType) {
        'warmup' => WorkoutSetLane.warmup,
        'dropset' => WorkoutSetLane.dropset,
        _ => WorkoutSetLane.working,
      };

  static bool isWorking(String setType) =>
      laneFor(setType) == WorkoutSetLane.working;

  /// Returns the lane and one-based ordinal for [index] in the supplied row
  /// sequence. A normal and failure set deliberately share the working lane.
  static WorkoutSetPosition positionAt(List<String> setTypes, int index) {
    final lane = laneFor(setTypes[index]);
    var ordinal = 0;
    for (var i = 0; i <= index; i++) {
      if (laneFor(setTypes[i]) == lane) ordinal++;
    }
    return WorkoutSetPosition(lane, ordinal);
  }

  /// Finds the row in [previousSetTypes] holding the same lane/ordinal as the
  /// current row. Returns null rather than borrowing another lane's value.
  static int? matchingPreviousIndex({
    required List<String> currentSetTypes,
    required int currentIndex,
    required List<String> previousSetTypes,
  }) {
    final position = positionAt(currentSetTypes, currentIndex);
    var ordinal = 0;
    for (var index = 0; index < previousSetTypes.length; index++) {
      if (laneFor(previousSetTypes[index]) != position.lane) continue;
      ordinal++;
      if (ordinal == position.ordinal) return index;
    }
    return null;
  }
}
