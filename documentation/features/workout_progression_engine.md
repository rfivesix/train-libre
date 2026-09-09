# Workout progression

The live workout offers a small, editable recommendation for eligible
load-and-repetition exercises. Its purpose is to pre-fill ordinary weight and
repetition fields at the useful moment; it is not a separate workout flow.

## What the user sees

With Training Autonomy set to **Suggest**, the app fills only the first open
working set when comparable history is available. The user can overwrite either
field and completes the set with the usual check action. There are no policy
selectors, completion reasons, review cards, confirmation dialogs, equipment
configuration controls, or progression-specific menus in a live workout.

After the first working set is completed, the remaining open working sets get
their targets. A value entered by the user always wins over a generated value,
including if an asynchronous history lookup finishes afterwards.

Cardio, duration, distance, variable-load and other exercises without a stable
load-and-repetition axis continue to log normally, but receive no strength
progression recommendation.

## Recommendation rule

Only the first working set of the most recent completed comparable workout is
used to start the next one. Warm-up and drop sets are excluded. Exercise
matching uses the canonical exercise UUID, with the existing legacy name
fallback for old records.

For a repetition range `[L, U]`, the next first set is simple double
progression:

| Previous first set | Suggested next first set |
| --- | --- |
| Below `L` repetitions | Hold the load and target `L` |
| `L` through `U - 1` repetitions | Hold the load and add one repetition |
| At least `U` repetitions | Advance one standard equipment increment and target `L` |

For a fixed repetition target, the app projects a load capable of that target
from the previous first set's estimated 1RM, while limiting an increase to one
standard equipment increment. A recorded RIR contributes to that estimate as
additional repetitions to failure; a missing RIR uses only the performed
repetitions. Without a repetition target it repeats the prior load and leaves
repetitions empty.

The completed first working set is the strength anchor for every later set in
that workout. The app uses its shared Brzycki estimated-1RM calculation. A
missing RIR or RIR `0` retains 95% capacity for the next set; RIR `1` through
`4+` retain 96% through 99%. Each completed prior working set contributes one
such factor, while unfinished sets use the normal 95% forecast. The resulting
load is rounded conservatively to the normal equipment increment. Each later
set uses the routine's authored lower repetition target, or its fixed
repetition target.
Bodyweight exercises receive repetition targets only. Assisted and
weighted-bodyweight exercises retain their own load semantics and use body
weight only where it is available; the app does not invent it.

The recommendation is deliberately a starting point. It does not diagnose
fatigue, pain, form, recovery or readiness, and it never changes the routine.

## Persistence and updates

Saving a workout writes every retained set and the completed workout record in
one SQLite transaction, then verifies the retained rows. Untouched empty rows
and unfinished generated placeholders are discarded, so workout history shows
only used sets. Manually entered open sets and all completed sets are retained.
This avoids the former delete-before-save path that could lose entered sets if
finalization was interrupted.

The simplification does not require a schema migration. Existing progression
metadata remains readable for backup, restore and historical records, while new
workouts use algorithm version `progression_v1.7_rir`.
