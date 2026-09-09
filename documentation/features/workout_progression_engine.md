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

After a working set is completed, only the directly following open working set
gets its target. Its completed predecessor is the evidence for that one
prescription. A value entered by the user always wins over a generated value,
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

For each later set, the app calculates a fresh Brzycki capacity from the
immediately preceding real set. Missing RIR or RIR `0` retain 95% capacity for
the next set; RIR `1` through `4+` retain 96% through 99%. The next test load
is normally the previous real load. When routine weights deliberately define a
different positive next-set weight, their ratio to the first template weight
is applied to today's real first-set load and rounded to a usable increment
before calculating repetitions.

For a range `[L, U]`, the calculated repetitions determine the next target:

| Projection at the rounded test load | Suggested next set |
| --- | --- |
| Above `U` | One normal increment harder, `U` reps |
| `L` through `U` | Hold the test load, projected reps |
| Below `L` | Lower to the highest usable load capable of `L` reps, `L` reps |

The engine does not use Brzycki beyond 12 effective repetitions. In that case
it holds the test load unless the actual result reached the range maximum, when
it advances by exactly one increment. A result of at most three effective reps
in a range beginning at six or more reps holds the test load and targets the
lower bound, avoiding an implausible deload after insufficient evidence.

Bodyweight exercises receive repetition targets only. Assisted and
weighted-bodyweight exercises retain their own load semantics. Assisted work
uses effective resistance when body weight is available. Without body weight,
it uses a discrete rule: less assistance at the range maximum, more assistance
below the range, and the same assistance with one more rep inside the range.
Generic equipment floors prevent suggestions below an unloaded standard
barbell, the smallest dumbbell, cable or machine increment. The database does
not yet store a user's specific gym inventory, so these floors are deliberately
conservative class defaults rather than claims about a particular facility.

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
workouts use algorithm version `progression_v1.8_jit`.
