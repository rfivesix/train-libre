import re

with open("CHANGELOG.md", "r") as f:
    content = f.read()

new_entries = """### Fixed
- **Cardio Analytics Isolation:** Strictly isolated Cardio exercises from bodybuilding and hypertrophy metrics. Cardio data points are now filtered out of weekly set volumes, tonnage charts, consistency trackers, and muscle readiness states to prevent analytics pollution.
- **Cardio UI Data Artifacts:** Fixed a bug on the `ExerciseDetailScreen` where cardio PRs and time-series history displayed as "0" due to queries incorrectly falling back to strength constraints. Passed `isCardio` explicitly down the repository stack to retrieve duration, distance, and pace properly.
- **Cardio Heatmap Exclusion:** Completely removed the `DualBodyHighlighter` distribution map and primary/secondary muscle chip sections from the `ExerciseDetailScreen` when viewing a Cardio exercise.
- **Unified Cardio Duration Input:** Standardized cardio input fields across the Live Workout, Edit Routine, and Log History screens. The `Duration` field now uniformly opens the `showAdaptiveDurationPicker` with immediate UI feedback, while the `Distance` and `Intensity` fields retain standard native keyboard text inputs.

"""

search = "## [1.0.0-alpha.7] - 2026-07-09\n"

# Check if "### Fixed" exists under [1.0.0-alpha.7]
# Actually, I can just insert it right under the version header!

content = content.replace(search, search + "\n" + new_entries)

with open("CHANGELOG.md", "w") as f:
    f.write(content)
