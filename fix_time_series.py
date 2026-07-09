import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

search_init = """      if (!sessionAggregates.containsKey(wLogId)) {
        sessionAggregates[wLogId] = {
          'date': logRow.startTime,
          'maxWeight': 0.0,
          'totalVolume': 0.0,
          'maxEst1rm': 0.0,
          'setCount': 0,
        };
      }"""

replace_init = """      if (!sessionAggregates.containsKey(wLogId)) {
        sessionAggregates[wLogId] = {
          'date': logRow.startTime,
          'maxWeight': 0.0,
          'totalVolume': 0.0,
          'maxEst1rm': 0.0,
          'maxDistance': 0.0,
          'totalDuration': 0.0,
          'maxPace': double.infinity,
          'setCount': 0,
        };
      }"""

content = content.replace(search_init, replace_init)

search_update = """      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;

      // Update Max Weight
      if (weight > agg['maxWeight']) {
        agg['maxWeight'] = weight;
      }

      // Update Volume
      agg['totalVolume'] += (weight * reps);

      // Update Max Est. 1RM (Brzycki formula)
      if (reps > 0 && reps <= 10) {
        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > (agg['maxEst1rm'] as double)) {
          agg['maxEst1rm'] = est1rm;
        }
      }

      // Update Set Count
      agg['setCount'] += 1;"""

replace_update = """      final weight = setRow.weight ?? 0.0;
      final reps = setRow.reps ?? 0;
      final dist = setRow.distance ?? 0.0;
      final dur = setRow.durationSeconds ?? 0;

      // Update Max Weight
      if (weight > agg['maxWeight']) {
        agg['maxWeight'] = weight;
      }

      // Update Volume
      agg['totalVolume'] += (weight * reps);

      // Update Max Est. 1RM (Brzycki formula)
      if (reps > 0 && reps <= 10) {
        final est1rm = weight * (36 / (37 - reps));
        if (est1rm > (agg['maxEst1rm'] as double)) {
          agg['maxEst1rm'] = est1rm;
        }
      }

      // Cardio
      if (dist > (agg['maxDistance'] as double)) {
        agg['maxDistance'] = dist;
      }
      agg['totalDuration'] = (agg['totalDuration'] as double) + dur;
      if (dist > 0 && dur > 0) {
        final pace = dur / dist;
        if (pace < (agg['maxPace'] as double)) {
          agg['maxPace'] = pace;
        }
      }

      // Update Set Count
      agg['setCount'] += 1;"""

content = content.replace(search_update, replace_update)

# Fix maxPace initialization before sorting list
search_sort = """    // Return as chronologically sorted list
    final resultList = sessionAggregates.values.toList();
    resultList.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return resultList;"""

replace_sort = """    // Return as chronologically sorted list
    final resultList = sessionAggregates.values.toList();
    for (var r in resultList) {
      if (r['maxPace'] == double.infinity) {
        r['maxPace'] = 0.0;
      }
    }
    resultList.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );
    return resultList;"""

content = content.replace(search_sort, replace_sort)

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
