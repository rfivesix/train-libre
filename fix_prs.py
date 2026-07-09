import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

search_prs_where = """    // Qualifying sets for PRs:
    // isCompleted == true, setType != 'warmup', weight > 0, reps > 0
    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            dbInstance.setLogs.weight.isBiggerThanValue(0) &
            dbInstance.setLogs.reps.isBiggerThanValue(0),
      );"""

replace_prs_where = """    // Qualifying sets for PRs:
    // isCompleted == true, setType != 'warmup', (weight > 0 & reps > 0 OR distance > 0 OR duration > 0)
    final query = dbInstance.select(dbInstance.setLogs).join([
      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
    ])
      ..where(
        exerciseMatch &
            dbInstance.setLogs.isCompleted.equals(true) &
            dbInstance.setLogs.setType.isNotIn(['warmup']) &
            (isCardio 
              ? (dbInstance.setLogs.distance.isBiggerThanValue(0.0) | dbInstance.setLogs.durationSeconds.isBiggerThanValue(0))
              : (dbInstance.setLogs.weight.isBiggerThanValue(0.0) & dbInstance.setLogs.reps.isBiggerThanValue(0))),
      );"""

content = content.replace(search_prs_where, replace_prs_where)

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
