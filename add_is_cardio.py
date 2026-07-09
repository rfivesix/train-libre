import re
with open("lib/features/exercise_catalog/domain/models/exercise.dart", "r") as f:
    content = f.read()

# Add isCardio
new_content = content.replace("  final List<String> secondaryMuscles;", "  final List<String> secondaryMuscles;\n\n  /// Whether this exercise is categorized as Cardio.\n  bool get isCardio => categoryName.trim().toLowerCase() == 'cardio';")

with open("lib/features/exercise_catalog/domain/models/exercise.dart", "w") as f:
    f.write(new_content)
