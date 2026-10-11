# Prepare a compatible workout CSV

Prepare a CSV with one row per exercise set so Train Libre can group the rows into dated workouts.

## 1. Add a header row

Use a header row and include a workout date and exercise name on every data row. The importer recognizes these generic column names (spaces and hyphens are normalized to underscores; matching is case-insensitive):

| Information | Accepted headers |
| --- | --- |
| Workout date and time | `start_time`, `start`, `date`, `workout_date`, `datum` |
| Exercise | `exercise`, `exercise_title`, `exercise_name`, `übung`, `name_der_übung` |
| Workout title (recommended) | `title`, `routine`, `workout`, `name`, `workout_name` |
| Weight | `weight`, `weight_kg`, `weight_lbs`, `gewicht`, `mass`, `lbs` |
| Weight unit (optional) | `weight_unit`, `unit` |
| Repetitions | `reps`, `repetition`, `wiederholungen`, `wiederh.`, `repetitionen` |
| Distance | `distance`, `distance_km`, `distance_mi`, `distance_miles`, `distance_m`, `distance_meters`, `distanz`, `entfernung` |
| Distance unit (optional) | `distance_unit` |
| Set duration | `duration`, `duration_seconds`, `seconds`, `sekunden`, `dauer`, `zeit` |
| Set type | `set_type`, `type`, `typ` |
| Effort | `rpe`, `rir`, `reps_in_reserve` |
| Set note | `set_notes`, `notes`, `notizen` |
| Workout note | `description`, `workout_notes`, `workout_comments`, `notiz`, `workout_notizen` |
| Workout end | `end_time`, `end` |

Train Libre also detects Hevy and Strong exports from their identifying headers and maps their layouts automatically. For a generic file, use `start_time` plus an exercise column; a missing title becomes **Imported Workout**. Rows with no valid date are skipped. Rows with no exercise name are imported as **Unknown Exercise**, so add the exercise column to avoid that result.

## 2. Use one row per set

Repeat the workout title and start date/time for every set in that workout. The importer groups rows with the same title and start time into one workout. For example:

```csv
title,start_time,exercise,weight_kg,reps,set_type,rpe
Upper body,2026-05-20 10:00:00,Bench Press,60,8,warmup,6
Upper body,2026-05-20 10:00:00,Bench Press,80,5,normal,8
Upper body,2026-05-20 10:00:00,Row,50,10,normal,7
```

Use `weight_kg` for kilograms or `weight_lbs` for pounds. These explicit headers determine conversion automatically. With a plain `weight` column, choose **Metric (kg)** or **Imperial (lbs)** to match the file when the import asks for its weight unit. Alternatively, include `weight_unit` values such as `kg` or `lbs` on each row. Weight values are stored in kilograms after import.

Distances are stored in kilometres. A plain `distance` value is treated as kilometres. Use `distance_mi` or `distance_miles` for miles, `distance_m` or `distance_meters` for metres, or `distance_km` for kilometres; a `distance_unit` column can specify `mi`, `mile`, `miles`, `m`, `meter`, or `meters`.

## 3. Format dates and values

Every row needs a date the importer can parse. Recommended unambiguous formats are `2026-05-20 10:00:00` and `2026-05-20T10:00:00`. The importer also accepts date-times such as `20.05.2026 10:00`, `05/20/2026 10:00`, and month-name forms such as `20 May 2026, 10:00` or `20 Okt. 2026, 10:00`. Slash dates can be ambiguous between month-first and day-first conventions, so prefer the ISO format and include both date and time.

Use numeric values for repetitions, weight, distance, RPE, and RIR. Decimal points are supported. Decimal commas are also parsed, and a semicolon-delimited CSV can keep a value such as `100,5` together. Set duration accepts seconds (for example, `1800`) or a clock duration such as `00:30:00`. The optional `end_time` can supply the workout’s end date and time; without it, a workout duration can supply the end time.

In a generic file, `duration` is the set duration. In a Strong export layout, `Duration` means the workout duration; use `Seconds` for the set duration, as Strong does.

For set types, `warmup` or `w`, `failure` or `f`, and `dropset` or `d` are recognized. Other values are treated as a normal set. Keep a consistent delimiter throughout the CSV and quote any text field containing that delimiter, such as a workout title or note.

## Common import problems

- **Rows are skipped:** check that each row has a valid date in the date column and at least as many fields as the header.
- **The import preview has no workouts:** include a header row and at least one dated data row; check that the date header uses a supported name.
- **Weights are converted incorrectly:** use `weight_kg` or `weight_lbs`, add a `weight_unit` column, or select the matching unit when prompted for a plain `weight` column.
- **A decimal value shifts into another column:** use the same delimiter for all columns and quote delimiter characters inside text values. For decimal commas, a semicolon-delimited file is suitable.
- **An imported workout is skipped as a duplicate:** Train Libre skips a completed workout with the same title and start time. Change neither value just to force an import unless that reflects the source data; see [Import workout history and other data](importing_data.md) for the import workflow.

For full exports from Hevy or Strong, use the original CSV or XLSX export when possible. The importer recognizes their layouts; for other spreadsheet details, see [Import workout history and other data](importing_data.md).
