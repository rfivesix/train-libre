import re

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "r") as f:
    content = f.read()

search_prs = """    final prs = await _repository.getExercisePRs(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );"""

replace_prs = """    final prs = await _repository.getExercisePRs(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );"""

content = content.replace(search_prs, replace_prs)

search_ts = """    final tsData = await _repository.getExerciseTimeSeriesData(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
    );"""

replace_ts = """    final tsData = await _repository.getExerciseTimeSeriesData(
      exercise.nameDe,
      altName: altName,
      exerciseUuid: exerciseUuid,
      isCardio: exercise.isCardio,
    );"""

content = content.replace(search_ts, replace_ts)

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "w") as f:
    f.write(content)
