import re

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "r") as f:
    content = f.read()

# 1. Update _loadExerciseMuscleLookup
muscle_lookup_search = r"final query = dbInstance.select\(dbInstance.exercises\);"
muscle_lookup_replace = """final query = dbInstance.select(dbInstance.exercises)..where((t) => t.categoryName.isNull() | t.categoryName.lower().isNotValue('cardio'));"""
content = content.replace(muscle_lookup_search, muscle_lookup_replace)

# 2. Add LEFT JOIN exercises to queries
def add_join_and_filter(content, query_names):
    for qname in query_names:
        # Find the query declaration
        start_idx = content.find(qname)
        if start_idx == -1:
            print("Not found:", qname)
            continue
            
        # Find the join section
        join_start = content.find("dbInstance.select(dbInstance.setLogs).join([", start_idx)
        if join_start == -1:
            continue
            
        join_end = content.find("])", join_start)
        
        # Add the left outer join
        new_join = """      drift.innerJoin(
        dbInstance.workoutLogs,
        dbInstance.workoutLogs.id.equalsExp(
          dbInstance.setLogs.workoutLogId,
        ),
      ),
      drift.leftOuterJoin(
        dbInstance.exercises,
        dbInstance.exercises.id.equalsExp(dbInstance.setLogs.exerciseId),
      ),"""
      
        # Find innerJoin to replace
        inner_join_start = content.find("drift.innerJoin(", join_start)
        inner_join_end = content.find("),", inner_join_start)
        inner_join_end = content.find("),", inner_join_end + 1) + 2
        
        if "drift.leftOuterJoin" not in content[join_start:join_end]:
            content = content[:inner_join_start] + new_join + content[inner_join_end:]
            
        # Find the where clause
        where_start = content.find("..where(", join_start)
        where_end = content.find(";", where_start)
        
        if "(dbInstance.exercises.categoryName.isNull()" not in content[where_start:where_end]:
            # Inject filter right after .where(
            content = content[:where_start + 8] + """
        (dbInstance.exercises.categoryName.isNull() | 
         dbInstance.exercises.categoryName.lower().isNotValue('cardio')) &
""" + content[where_start + 8:]
            
    return content

content = add_join_and_filter(content, ["getWeeklyVolumeData", "getMonthlyVolumeData", "getNotablePrImprovements"])

with open("lib/features/workout/data/sources/parts/workout_stats_queries.dart", "w") as f:
    f.write(content)
