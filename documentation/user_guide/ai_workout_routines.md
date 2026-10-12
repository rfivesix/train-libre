# Create a workout routine with an AI assistant

Use the OpenExerciseDB catalog to choose real exercises, then ask an AI assistant to prepare a Train Libre routine JSON file. The app’s import preview is the final check before saving.

AI-generated routines use the same versioned JSON format that Train Libre already accepts for shared-item imports. There is no separate AI import or app-side catalog integration: OpenExerciseDB is the reference for matching exercise IDs and names, which are copied into the existing `uuid` and `name` fields.

## Find exercises in the catalog

- [Search and browse OpenExerciseDB](https://rfivesix.github.io/OpenExerciseDB/exercise-search.html) for names in any listed language, IDs, muscles, or equipment. The page works without JavaScript; use your browser’s Find command.
- [Download the machine-readable JSON catalog](https://rfivesix.github.io/OpenExerciseDB/exercises.json) to search records programmatically. Each record includes a stable string `id`, canonical English `name`, localized names, status, muscles, equipment, and classification fields.
- Use records marked `recommended_for_routines: true` (currently active exercises). Do not recommend merged or retired records for a new routine.

OpenExerciseDB IDs are exact strings, not necessarily UUID-formatted values. Train Libre imports each catalog `id` unchanged as its exercise identifier, and routine import resolves the exercise’s `uuid` against that same identifier. For example, catalog ID `"475"` is valid and remains `"475"` in `uuid`.

For each matched exercise, copy the catalog `id` exactly into `uuid` and copy the catalog’s canonical English `name` exactly into `name`. Never generate an ID, alter an ID, rename a match, or silently replace a missing exercise with a similar one. If there is no suitable match, ask the user what they prefer. If they approve a custom/unmatched exercise, omit `uuid`, clearly label it as custom in its name, and include only user-confirmed details; do not present guessed catalog metadata as fact. Import first tries `uuid`, then an exact exercise name, and creates a custom exercise only when neither resolves.

## Routine JSON format

Use this versioned JSON envelope, which is the format accepted by the app’s share/import codec:

```json
{
  "v": 1,
  "t": "routine",
  "n": "Pull day",
  "d": {
    "exercises": [
      {
        "uuid": "475",
        "name": "Pull-Up",
        "category": "Back",
        "muscles": ["Lats"],
        "tracking": "bodyweight_reps",
        "loadMode": "bodyweight",
        "equipment": "bodyweight",
        "pause": 120,
        "sets": [
          {"type": "normal", "reps": "6-10", "rir": 2}
        ]
      }
    ]
  }
}
```

The example uses the active OpenExerciseDB record `"475"` / `"Pull-Up"`. Routine envelope fields are: `v` (integer `1`), `t` (the string `"routine"`), `n` (a nonblank routine name, at most 200 characters), and `d` (an object containing `exercises`). There may be at most 100 exercises. The `exercises` array may be empty, although a useful routine normally has at least one exercise.

Each exercise requires a nonblank string `name` and a `sets` array of at most 100 entries. Optional exercise fields are `uuid` (string or null), `category` (string), `muscles` and `secondaryMuscles` (arrays of strings), `tracking`, `loadMode`, and `equipment` (strings), `pause` and `superset` (numbers), `notes` (string up to 10,000 characters), and `progression` (string). These are the exact accepted JSON keys; use camel case where shown.

Each set requires `type` (string). Optional `reps` is a string; `weight` and `rir` are numbers; `repMin` and `repMax` are integers. The codec checks these types but does not enforce an enum or numeric range for these fields. The app’s set-type controls use `normal`, `warmup`, `failure`, and `dropset`; use one of those values. Weight is in kilograms. Provide only fields that make sense for the exercise and user’s request.

The codec ignores additional object keys, but omit unsupported fields to keep the file clear. Do not add root keys such as `name` or `exercises`; the routine name and exercise list belong at `n` and `d.exercises` respectively.

## Import and review

In Train Libre, open **Data & Backup** and choose the import action for JSON or pasted text. The exact menu wording can vary by platform/version. Review the parsed routine and every exercise in the in-app preview. Confirm that names, exercise matches, sets, targets, and rest times are correct before importing. The user should review and approve the completed routine; the assistant should never treat a valid JSON parse as approval.

The catalog is discoverable from both [the search page](https://rfivesix.github.io/OpenExerciseDB/exercise-search.html) and the [direct JSON download](https://rfivesix.github.io/OpenExerciseDB/exercises.json). Provide these links together with any existing routine export when asking an AI assistant to make a routine.
