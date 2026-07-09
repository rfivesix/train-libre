import re

files = [
    "lib/features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart",
    "lib/features/exercise_catalog/data/exercise_catalog_repository.dart",
    "lib/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart",
    "lib/features/workout/data/sources/workout_local_data_source.dart"
]

for file in files:
    with open(file, "r") as f:
        content = f.read()

    # Domain / interface definitions
    content = re.sub(
        r'(Future<Map<String, SetLog\?>> getExercisePRs\(\s*String exerciseName,\s*\{\s*String\? altName,\s*String\? exerciseUuid,\s*)(\}\);)',
        r'\1bool isCardio = false,\2',
        content
    )
    content = re.sub(
        r'(Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(\s*String exerciseName,\s*\{\s*String\? altName,\s*String\? exerciseUuid,\s*)(\}\);)',
        r'\1bool isCardio = false,\2',
        content
    )
    
    # Implementation definitions
    content = re.sub(
        r'(Future<Map<String, SetLog\?>> getExercisePRs\(\s*String exerciseName,\s*\{\s*String\? altName,\s*String\? exerciseUuid,\s*)(\}\)\s*async\s*\{)',
        r'\1bool isCardio = false,\2',
        content
    )
    content = re.sub(
        r'(Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(\s*String exerciseName,\s*\{\s*String\? altName,\s*String\? exerciseUuid,\s*)(\}\)\s*async\s*\{)',
        r'\1bool isCardio = false,\2',
        content
    )

    # Method calls
    content = re.sub(
        r'(return [a-zA-Z_0-9]+\.getExercisePRs\(\s*exerciseName,\s*altName:\s*altName,\s*exerciseUuid:\s*exerciseUuid)(\s*\);)',
        r'\1, isCardio: isCardio\2',
        content
    )
    content = re.sub(
        r'(return [a-zA-Z_0-9]+\.getExerciseTimeSeriesData\(\s*exerciseName,\s*altName:\s*altName,\s*exerciseUuid:\s*exerciseUuid)(\s*\);)',
        r'\1, isCardio: isCardio\2',
        content
    )
    
    with open(file, "w") as f:
        f.write(content)

