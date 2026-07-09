import re

files = [
    "lib/features/workout/presentation/workout_log_detail_screen.dart",
    "lib/features/workout/presentation/workout_summary_screen.dart"
]

for file in files:
    with open(file, "r") as f:
        content = f.read()
    
    if "workout_log_detail_screen.dart" in file:
        search = """    for (final name in _groupedSets.keys) {
      final ex = _exerciseDetails[name];
      if (ex == null) continue;"""
        
        replace = """    for (final name in _groupedSets.keys) {
      final ex = _exerciseDetails[name];
      if (ex == null || ex.isCardio) continue;"""
        
        content = content.replace(search, replace)
    
    elif "workout_summary_screen.dart" in file:
        search = """    for (final ex in _exerciseDetails.values) {
      final exerciseSlugs = <BodyPartSlug>{};"""
        
        replace = """    for (final ex in _exerciseDetails.values) {
      if (ex.isCardio) continue;
      final exerciseSlugs = <BodyPartSlug>{};"""
        
        content = content.replace(search, replace)

    with open(file, "w") as f:
        f.write(content)
