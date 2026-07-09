import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

# 1. Update getRecentGlobalPRs
# Add AND s1.exercise_name_snapshot NOT IN (SELECT name_de FROM exercises WHERE category_name COLLATE NOCASE = 'cardio' UNION SELECT name_en FROM exercises WHERE category_name COLLATE NOCASE = 'cardio')
# Wait, a simpler way is joining exercises:
# We can't easily join on snapshot. Let's just exclude category = 'cardio' by joining exercises on s1.exercise_id = exercises.id
recent_prs_replacement = """
      FROM set_logs s1
      JOIN workout_logs wl ON wl.id = s1.workout_log_id
      LEFT JOIN exercises e ON e.id = s1.exercise_id
      WHERE s1.is_completed = 1
        AND s1.set_type != 'warmup'
        AND s1.weight > 0
        AND s1.reps  > 0
        AND wl.status = 'completed'
        AND (e.category_name IS NULL OR e.category_name COLLATE NOCASE != 'cardio')
"""
content = re.sub(r"FROM set_logs s1\s*JOIN workout_logs wl ON wl.id = s1.workout_log_id\s*WHERE s1.is_completed = 1\s*AND s1.set_type != 'warmup'\s*AND s1.weight > 0\s*AND s1.reps  > 0\s*AND wl.status = 'completed'", recent_prs_replacement.strip(), content)

# 2. Update getWeeklyVolumeData
# Need to add left outer join with exercises and filter out cardio
weekly_volume_search = r"dbInstance.workoutLogs.startTime.isBetweenValues\(\s*since,\s*now.add\(const Duration\(days: 1\)\),\s*\),"
weekly_volume_replace = """dbInstance.workoutLogs.startTime.isBetweenValues(
              since,
              now.add(const Duration(days: 1)),
            ) &
            (dbInstance.exercises.categoryName.isNull() |
             dbInstance.exercises.categoryName.lower().isNotValue('cardio')),"""

# Since getWeeklyVolumeData doesn't have exercises joined, we need to add the join
weekly_volume_join_search = r"drift.innerJoin\(\s*dbInstance.workoutLogs,\s*dbInstance.workoutLogs.id.equalsExp\(\s*dbInstance.setLogs.workoutLogId,\s*\),\s*\),"
weekly_volume_join_replace = """drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),"""

content = content.replace(weekly_volume_join_search, weekly_volume_join_replace, 1) # Only first occurrence, wait, it's safer to just rewrite the method

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
