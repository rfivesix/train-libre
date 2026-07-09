import re

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "r") as f:
    content = f.read()

search = """  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasMuscles = exercise.primaryMuscles.isNotEmpty ||"""

replace = """  Widget build(BuildContext context) {
    if (exercise.isCardio) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hasMuscles = exercise.primaryMuscles.isNotEmpty ||"""

content = content.replace(search, replace)

with open("lib/features/exercise_catalog/presentation/exercise_detail_screen.dart", "w") as f:
    f.write(content)
