import re

# 1. Update domain interface
with open("lib/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart", "r") as f:
    content = f.read()
    
content = re.sub(
    r'Future<Map<String, SetLog\?>> getExercisePRs\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<Map<String, SetLog?>> getExercisePRs(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

content = re.sub(
    r'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

with open("lib/features/exercise_catalog/domain/repositories/exercise_catalog_repository.dart", "w") as f:
    f.write(content)

# 2. Update data implementation
with open("lib/features/exercise_catalog/data/exercise_catalog_repository.dart", "r") as f:
    content = f.read()

content = re.sub(
    r'Future<Map<String, SetLog\?>> getExercisePRs\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\) async \{',
    'Future<Map<String, SetLog?>> getExercisePRs(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false}) async {',
    content
)
content = re.sub(
    r'return _localDataSource\.getExercisePRs\(exerciseName, altName: altName, exerciseUuid: exerciseUuid\);',
    'return _localDataSource.getExercisePRs(exerciseName, altName: altName, exerciseUuid: exerciseUuid, isCardio: isCardio);',
    content
)

content = re.sub(
    r'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\) async \{',
    'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false}) async {',
    content
)
content = re.sub(
    r'return _localDataSource\.getExerciseTimeSeriesData\(exerciseName, altName: altName, exerciseUuid: exerciseUuid\);',
    'return _localDataSource.getExerciseTimeSeriesData(exerciseName, altName: altName, exerciseUuid: exerciseUuid, isCardio: isCardio);',
    content
)

with open("lib/features/exercise_catalog/data/exercise_catalog_repository.dart", "w") as f:
    f.write(content)

# 3. Update data source interface
with open("lib/features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart", "r") as f:
    content = f.read()

content = re.sub(
    r'Future<Map<String, SetLog\?>> getExercisePRs\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<Map<String, SetLog?>> getExercisePRs(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

content = re.sub(
    r'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

with open("lib/features/exercise_catalog/data/sources/exercise_catalog_local_data_source.dart", "w") as f:
    f.write(content)

# 4. Update data source implementation
with open("lib/features/workout/data/sources/workout_local_data_source.dart", "r") as f:
    content = f.read()

content = re.sub(
    r'Future<Map<String, SetLog\?>> getExercisePRs\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<Map<String, SetLog?>> getExercisePRs(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

content = re.sub(
    r'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData\(String exerciseName, \{\s*String\? altName,\s*String\? exerciseUuid,\s*\}\);',
    'Future<List<Map<String, dynamic>>> getExerciseTimeSeriesData(String exerciseName, {String? altName, String? exerciseUuid, bool isCardio = false});',
    content
)

with open("lib/features/workout/data/sources/workout_local_data_source.dart", "w") as f:
    f.write(content)
