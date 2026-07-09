import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

# Replace time series logic
time_series_find = """    final Map<int, Map<String, dynamic>> sessionAggregates = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final wLogId = logRow.localId;

      if (!sessionAggregates.containsKey(wLogId)) {
        sessionAggregates[wLogId] = {
          'date': logRow.startTime,
          'maxWeight': 0.0,
          'totalVolume': 0.0,
          'maxEst1rm': 0.0,
          'setCount': 0,
        };
      }

      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;

      if (weight > 0 && reps > 0) {
        if (weight > sessionAggregates[wLogId]!['maxWeight']) {
          sessionAggregates[wLogId]!['maxWeight'] = weight;
        }

        sessionAggregates[wLogId]!['totalVolume'] += (weight * reps);

        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > sessionAggregates[wLogId]!['maxEst1rm']) {
          sessionAggregates[wLogId]!['maxEst1rm'] = est1rm;
        }

        sessionAggregates[wLogId]!['setCount'] += 1;
      }
    }

    final result = sessionAggregates.values.toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return result;"""

time_series_replace = """    final Map<int, Map<String, dynamic>> sessionAggregates = {};

    for (final r in rows) {
      final setRow = r.readTable(dbInstance.setLogs);
      final logRow = r.readTable(dbInstance.workoutLogs);
      final wLogId = logRow.localId;

      if (!sessionAggregates.containsKey(wLogId)) {
        if (isCardio) {
          sessionAggregates[wLogId] = {
            'date': logRow.startTime,
            'maxDistance': 0.0,
            'totalDistance': 0.0,
            'totalDuration': 0,
            'maxPace': double.infinity,
            'setCount': 0,
          };
        } else {
          sessionAggregates[wLogId] = {
            'date': logRow.startTime,
            'maxWeight': 0.0,
            'totalVolume': 0.0,
            'maxEst1rm': 0.0,
            'setCount': 0,
          };
        }
      }

      if (isCardio) {
        final dist = setRow.distance ?? 0.0;
        final dur = setRow.durationSeconds ?? 0;
        if (dist > 0 || dur > 0) {
          if (dist > sessionAggregates[wLogId]!['maxDistance']) {
            sessionAggregates[wLogId]!['maxDistance'] = dist;
          }
          sessionAggregates[wLogId]!['totalDistance'] += dist;
          sessionAggregates[wLogId]!['totalDuration'] += dur;
          
          if (dist > 0 && dur > 0) {
            final pace = dur / dist;
            if (pace < sessionAggregates[wLogId]!['maxPace']) {
              sessionAggregates[wLogId]!['maxPace'] = pace;
            }
          }
          sessionAggregates[wLogId]!['setCount'] += 1;
        }
      } else {
        final weight = setRow.weight ?? 0.0;
        final reps = setRow.reps ?? 0;

        if (weight > 0 && reps > 0) {
          if (weight > sessionAggregates[wLogId]!['maxWeight']) {
            sessionAggregates[wLogId]!['maxWeight'] = weight;
          }

          sessionAggregates[wLogId]!['totalVolume'] += (weight * reps);

          if (reps <= 10) {
            final est1rm = weight * (36 / (37 - reps));
            if (est1rm > sessionAggregates[wLogId]!['maxEst1rm']) {
              sessionAggregates[wLogId]!['maxEst1rm'] = est1rm;
            }
          }

          sessionAggregates[wLogId]!['setCount'] += 1;
        }
      }
    }
    
    // Cleanup inf pace
    if (isCardio) {
      for (final agg in sessionAggregates.values) {
        if (agg['maxPace'] == double.infinity) {
          agg['maxPace'] = 0.0;
        }
      }
    }

    final result = sessionAggregates.values.toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return result;"""

content = content.replace(time_series_find, time_series_replace)

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
