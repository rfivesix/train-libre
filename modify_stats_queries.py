import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

# Modify getExercisePRs signature
content = re.sub(
    r'Future<Map<String, SetLog\?>> getExercisePRs\(\s*String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\) async \{',
    '''Future<Map<String, SetLog?>> getExercisePRs(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async {''',
    content
)

# Modify getExerciseTimeSeriesData signature
content = re.sub(
    r'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(\s*String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\) async \{',
    '''Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(
    String exerciseName, {
    String? altName,
    String? exerciseUuid,
    bool isCardio = false,
  }) async {''',
    content
)

# Now, implement the inner logic changes.
# For getExercisePRs:
# find "final prMap = <String, SetLog?>{" and replace its initialization and logic
prs_logic_find = """    final prMap = <String, SetLog?>{
      'Est. 1RM': null,
      '1 RM': null,
      '2-3 RM': null,
      '4-6 RM': null,
      '7-10 RM': null,
      '11-15 RM': null,
    };

    double bestEst1rmValue = 0.0;
    SetLog? bestEst1rmSet;

    // Helper function to determine the bracket name
    String? getBracket(int reps) {
      if (reps == 1) return '1 RM';
      if (reps >= 2 && reps <= 3) return '2-3 RM';
      if (reps >= 4 && reps <= 6) return '4-6 RM';
      if (reps >= 7 && reps <= 10) return '7-10 RM';
      if (reps >= 11 && reps <= 15) return '11-15 RM';
      return null;
    }

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);

      final setLog = SetLog(
        id: setRow.localId,
        workoutLogId: logRow.localId,
        exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
        setType: setRow.setType,
        weightKg: setRow.weight,
        reps: setRow.reps,
        isCompleted: setRow.isCompleted,
      );

      final reps = setLog.reps ?? 0;
      final weight = setLog.weightKg ?? 0.0;

      if (reps <= 0 || weight <= 0) continue;

      // Track absolute best Est. 1RM
      if (reps <= 10) {
        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > bestEst1rmValue) {
          bestEst1rmValue = est1rm;
          bestEst1rmSet = setLog;
        }
      }

      final bracket = getBracket(reps);
      if (bracket != null) {
        final currentPr = prMap[bracket];
        if (currentPr == null || weight > (currentPr.weightKg ?? 0.0)) {
          prMap[bracket] = setLog;
        } else if (weight == currentPr.weightKg &&
            reps > (currentPr.reps ?? 0)) {
          prMap[bracket] = setLog;
        }
      }
    }

    if (bestEst1rmSet != null) {
      prMap['Est. 1RM'] = bestEst1rmSet;
    }"""

prs_logic_replace = """    final prMap = <String, SetLog?>{};

    if (isCardio) {
      prMap['Best Distance'] = null;
      prMap['Longest Duration'] = null;
      prMap['Fastest Pace'] = null;

      double bestDistance = 0.0;
      int longestDuration = 0;
      double fastestPace = double.infinity;

      for (final r in rows) {
        final setRow = r.readTable(dbInstance.setLogs);
        final logRow = r.readTable(dbInstance.workoutLogs);

        final setLog = SetLog(
          id: setRow.localId,
          workoutLogId: logRow.localId,
          exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
          setType: setRow.setType,
          distanceKm: setRow.distance,
          durationSeconds: setRow.durationSeconds,
          isCompleted: setRow.isCompleted,
        );

        final dist = setLog.distanceKm ?? 0.0;
        final dur = setLog.durationSeconds ?? 0;
        
        if (dist <= 0 && dur <= 0) continue;

        if (dist > bestDistance) {
          bestDistance = dist;
          prMap['Best Distance'] = setLog;
        }
        if (dur > longestDuration) {
          longestDuration = dur;
          prMap['Longest Duration'] = setLog;
        }
        if (dist > 0 && dur > 0) {
          final pace = dur / dist; // seconds per km
          if (pace < fastestPace) {
            fastestPace = pace;
            prMap['Fastest Pace'] = setLog;
          }
        }
      }
    } else {
      prMap.addAll({
        'Est. 1RM': null,
        '1 RM': null,
        '2-3 RM': null,
        '4-6 RM': null,
        '7-10 RM': null,
        '11-15 RM': null,
      });

      double bestEst1rmValue = 0.0;
      SetLog? bestEst1rmSet;

      String? getBracket(int reps) {
        if (reps == 1) return '1 RM';
        if (reps >= 2 && reps <= 3) return '2-3 RM';
        if (reps >= 4 && reps <= 6) return '4-6 RM';
        if (reps >= 7 && reps <= 10) return '7-10 RM';
        if (reps >= 11 && reps <= 15) return '11-15 RM';
        return null;
      }

      for (final r in rows) {
        final setRow = r.readTable(dbInstance.setLogs);
        final logRow = r.readTable(dbInstance.workoutLogs);

        final setLog = SetLog(
          id: setRow.localId,
          workoutLogId: logRow.localId,
          exerciseName: setRow.exerciseNameSnapshot ?? exerciseName,
          setType: setRow.setType,
          weightKg: setRow.weight,
          reps: setRow.reps,
          isCompleted: setRow.isCompleted,
        );

        final reps = setLog.reps ?? 0;
        final weight = setLog.weightKg ?? 0.0;

        if (reps <= 0 || weight <= 0) continue;

        if (reps <= 10) {
          final est1rm = weight * (36 / (37 - reps));
          if (est1rm > bestEst1rmValue) {
            bestEst1rmValue = est1rm;
            bestEst1rmSet = setLog;
          }
        }

        final bracket = getBracket(reps);
        if (bracket != null) {
          final currentPr = prMap[bracket];
          if (currentPr == null || weight > (currentPr.weightKg ?? 0.0)) {
            prMap[bracket] = setLog;
          } else if (weight == currentPr.weightKg &&
              reps > (currentPr.reps ?? 0)) {
            prMap[bracket] = setLog;
          }
        }
      }

      if (bestEst1rmSet != null) {
        prMap['Est. 1RM'] = bestEst1rmSet;
      }
    }"""
content = content.replace(prs_logic_find, prs_logic_replace)

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
