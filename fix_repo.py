import re

with open("lib/features/exercise_catalog/data/exercise_catalog_repository.dart", "r") as f:
    content = f.read()

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

with open("lib/features/exercise_catalog/data/exercise_catalog_repository.dart", "w") as f:
    f.write(content)
