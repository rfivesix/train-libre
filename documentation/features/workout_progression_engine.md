# Workout progression

The live workout offers a small, editable recommendation for eligible
load-and-repetition exercises. Its purpose is to pre-fill ordinary weight and
repetition fields at the useful moment; it is not a separate workout flow.

Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

## What the user sees

Training Autonomy defaults to **Off**. The Settings page offers **Off** and
**Suggest**, and the live workout keyboard accessory has an on/off toggle. A
one-time opt-in sheet can appear in a workout when eligible history exists and
the setting is Off. With **Suggest**, the app fills only the first open working
set when comparable history is available. The user can overwrite either field.
Checking a suggested set records the visible values as a performed set; there
is no additional per-set confirmation or review. The feature has no completion
reason or review card, and it does not offer equipment configuration controls.

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
matching uses the canonical exercise UUID, with a legacy name fallback when a
history row has no exercise UUID.

For a loaded exercise with a repetition range `[L, U]`, the next first set
follows these rules:

| Previous first set | Suggested next first set |
| --- | --- |
| Below `L` repetitions | Estimate a load for `L` reps from the prior set; if that estimate is unavailable, hold the load |
| `L` through `U - 1` repetitions | Hold the load and add one repetition |
| At least `U` repetitions | Move one increment harder for that load mode and target `L` |

For a fixed repetition target, when a valid estimate is available for up to 12
effective repetitions, the app projects a load capable of that target from the
previous first set's estimated 1RM, while limiting a harder step to one
standard equipment increment. A decrease can be larger when the estimate
calls for it. A recorded RIR contributes to that estimate as
additional repetitions to failure; a missing RIR uses only the performed
repetitions. If the estimate is unavailable or the target exceeds 12 reps, it
holds the prior load. Without a repetition target it repeats the prior load
and leaves repetitions empty.

For each later loaded set, the app estimates capacity from the immediately
preceding completed set using the Brzycki equation, then multiplies it by a
per-set retention factor. Missing RIR or RIR `0` retain 95% capacity; RIR `1`
through `4+` retain 96% through 99% (values above 4 use the 99% cap). The next
test load is normally the previous real load. For external and
weighted-bodyweight modes, when routine weights define a different positive
next-set weight at least one equipment increment away, their ratio to the
first template weight is applied to today's real first-set load and rounded
to a usable increment before calculating repetitions. Assisted mode uses the
previous visible assistance amount instead.

For a range `[L, U]`, the calculated repetitions determine the next target:

| Projection at the rounded test load | Suggested next set |
| --- | --- |
| Above `U` | One normal increment harder for that load mode, `U` reps |
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
For external loads, generic equipment floors prevent suggestions below the
configured minimum for a standard barbell, dumbbell, cable, or machine; unknown
equipment uses the generic increment without a minimum. The database does not
store a user's specific gym inventory, so these class defaults do not describe
a particular facility.

The recommendation is deliberately a starting point. It does not diagnose
fatigue, pain, form, recovery or readiness, and it never changes the routine.

## Persistence and updates

Each suggestion records its reason and algorithm version on the set row. The
current engine version is `progression_v1.8_jit`. Suggested values are stored
as ordinary set values; if the user changes them, the record marks the
prescription overridden. The engine does not automatically complete a set or
change a routine.
