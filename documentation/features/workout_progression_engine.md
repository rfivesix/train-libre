# Workout progression v1.5

Implemented from Part 11 of `planning/adaptive-engine.md`. The production entry
point is `ProgressionV15.evaluate`; its algorithm identifier is
`progression_v1.5`. It is a pure function. The live service loads canonical
exercise history and converts the equipment fallback increment to kilograms.
No e1RM estimate selects a prescription. RIR is optional.

## Policies and positions

A policy belongs to one **routine-exercise prescription**, not the catalogue
exercise. The routine editor shows “Develop sets together” or “Develop sets
individually”. When first saving a prescription:

- Equal authored loads and equal valid ranges select independent progression.
- Different loads/ranges, missing loads or ambiguous ranges select linked
  progression.
- An already selected policy remains selected. Generated or performed load
  differences never select another policy.

Existing prescriptions without v1.5 metadata conservatively retain linked
behaviour until configured in the routine editor. Existing explicit authored
loads retain their legacy precedence. A configured v1.5 prescription allows the
selected progression policy to develop its authored working-set structure.

Every workout copies its configuration and authored ranges. Later routine edits
cannot change that snapshot. Accepting a review from an older workout preserves
any subsequently edited routine policy.

Normal and failure sets share a working lane. Warm-ups and drop sets each have
separate lanes and do not enter progression. Interrupted or incomplete working
rows retain their positions; excluding their evidence must not shift another
set into their place. Duplicate exercise blocks within a workout are distinct
sessions for position matching. History lookup uses the canonical exercise UUID.
Rows written before exercise IDs were stored remain readable through the existing
name-snapshot fallback, while a row with a different explicit UUID can never
match by name.

## Progression decision table

For position j with authored range [L, U]:

| Evidence | Linked policy | Independent policy |
|---|---|---|
| All current positions reach their respective ceilings in one comparable session | Each position may take its next real rung | Each position may take its next real rung |
| Only one position reaches its ceiling | Hold the linked loads | That position may take its next real rung |
| Below L | Hold load; target L | Hold load; target L |
| Between L and U | Hold load; target one more repetition | Hold load; target one more repetition |
| At U while held | Target U | Target U |
| No valid range | Repeat matching load/repetitions; never raise | Same |
| No matching history, incompatible context or history older than 21 days | No initial generated value | Same |

A changed load resets repetitions to L only for the position that actually
changes load. Auto-filled values cannot satisfy a progression gate. They can
provide a held historical load, with their uncertainty explained.

For example, independent `60 × 12, 60 × 10, 60 × 9` with ranges 8–12 and a
2.5 kg fallback becomes `62.5 × 8, 60 × 11, 60 × 10`. A linked `70 × 12,
60 × 10, 60 × 9` holds its three corresponding loads.

A manually completed earlier set may anchor later **linked** positions using
their previous load differences. An independent position with its own history
keeps its own suggestion, whether the earlier set was heavier or lighter.
A genuinely new position can provisionally repeat today's latest manually
completed working load under either policy. That explanation explicitly calls
it a new-position baseline. Warm-ups, drop sets and interrupted sets never
anchor working sets. Current-session anchoring may run beyond the 21-day window;
it is not evidence for a future raise.

## Real equipment

`LoadLadder` stores sorted, distinct, non-negative available values. Resolution
is user/gym ladder, then supplied equipment-class ladder, then the existing
unit-aware increment table. No universal dumbbell or machine inventory is
invented. Equipment-class ladders can be supplied to the pure API; the live
app uses an explicitly configured ladder or the increment fallback.

| Fallback | Metric | Imperial |
|---|---:|---:|
| Barbell, cable, assistance, unknown | 2.5 kg | 5 lb |
| Dumbbell | 2 kg | 5 lb |
| Machine | 5 kg | 10 lb |

The next external rung is the smallest available value above the current load.
Within assistance it is the next lower available assistance value. A relative
step of at most 10% is an `ordinaryStep`. A larger step is a `largeStepTrial`:
the current load stays in the field until the user confirms the trial. No
absolute-kilogram exception overrides this guard. Zero external load also
requires a trial rather than an undefined percentage calculation.

An exhausted ladder produces `stepUnavailable`, holding the current load.
The v1.5 domain and backup format retain explicit ladders and equipment
identities, but the live workout and routine editor do not expose provisional
free-text controls for them. Until the planned gym-equipment section supplies a
coherent source of available loads, the live app uses the established fallback
increments unless an existing configuration already contains a ladder.
Equipment identity changes withhold comparisons until an appropriate baseline
exists.

## Reviews and recovery

Reviews are visible, optional and recorded. Offering, accepting, rejecting,
dismissing, confirming a log and recalibrating are separate decisions. An offer
never changes a prescription.

- **Large step:** confirm the displayed real rung, keep the current load or
  dismiss the review. The relative size and ladder source are shown.
- **Over-rep bridge:** declining a large step offers an optional temporary
  `U + 2` target at the held load. A second explicit confirmation activates it.
  It does not change the authored range or historical comparison. The active
  bridge carries through a held-load continuation; reaching it re-offers the
  real rung, never applies it. A different load is not evidence for that bridge.
- **Far above range:** a complete, manually entered set at `U + 3` or higher
  requires confirmation of the log. The conservative path presents exactly the
  next rung for confirmation. Alternatively, the user explicitly enters and
  confirms a new baseline. No multi-rung or e1RM extrapolation is applied.
- **Stall candidate:** the last three comparable manual attempts at the same
  position must all be below L. One or two do not trigger a review. A comparable
  in-range attempt breaks the run. Missing or excluded attempts cannot advance
  it. The review may offer an easier available rung with its percentage, keep
  the plan, or let the user edit the range. No automatic reduction occurs.

Completion state is independently recorded as `completed`, `abandoned`,
`stoppedForPain` or `equipmentInterrupted`. Only completed, user-entered working
sets supply positive progression, overshoot or stall evidence. Pain-marked sets
show stopping/assessment guidance instead of load reviews. Low repetitions
alone never imply pain. Optional context notes are retained without inventing
a causal diagnosis.

The live completion control uses the app's platform-adaptive dropdown. It is
shown only below the most recently completed working set when the entered load
or repetitions fall below the concrete suggestion, or below the routine minimum
when no exact repetition suggestion existed. `completed` remains the default;
the control lets the user explicitly exclude an early stop, pain or an equipment
problem. Completing a later working set removes the control from the earlier
row. Pending progression reviews remain visible only while they require a real
decision. Generic reasons, ladder sources, algorithm versions and event history
are not repeated beneath normal live rows. Workout history shows only a compact
label for exceptional completion states.

Comparability excludes explicit mode/identity changes, substitutions, changed
ranges and non-completed states. Missing legacy context is treated
conservatively; historical ranges remain readable. Technique, tempo, spotter
help and recovery are not inferred from repetition counts.

## Metric boundaries

Assistance is a non-negative magnitude. Progression never subtracts it into a
negative number or reinterprets a negative value as added load.

At zero assistance, a `modeBoundary` review offers bodyweight as a new baseline.
For bodyweight to weighted bodyweight:

- Linked: every current working position reaches its own U in one comparable
  session.
- Independent: every current position has independently reached its U. Early
  positions remain at their ceiling while the others catch up.

Only then is the exercise-level review available. The first real positive
external rung requires confirmation and establishes a **new metric/baseline**.
It is not a percentage increase from zero. Open working positions transition
together; existing completed records retain their original metric. The snapshot
metric controls the load label in live rows and history.

## Storage, lifecycle and compatibility

Schema **31** adds nullable `progression_data` columns to `RoutineExercises` and
`SetLogs`. A typed `ProgressionConfig` encodes a versioned JSON document rather
than spreading a review's interdependent state across unrelated nullable
columns. It contains policy, ladder/source, equipment identity, metric,
completion, temporary bridge state, confirmed baselines and timestamped review
decisions. Each decision stores the exact proposal, reason, policy, source and
algorithm version. Existing prescription columns still retain the authored
repetition range and the suggested load/reason/version.

A stable prescription key links accepted future baselines to the particular
routine-exercise configuration; duplicated prescriptions get a new key. Keys
are independent of database local IDs and survive backup/restore. Completed
set values are never rewritten by accepting a future baseline. Snapshots and
review decisions are included in normal database writes, workout export/import,
backup payloads and restored live sessions. Schema reconciliation can add the
nullable columns on skipped-version databases without fabricating old data.

Typing either generated field rejects the combined suggestion. Completing
untouched generated values remains friction-free but auto-filled/non-evidence.
Accepting a review confirms a target, not its performance: logging that target
untouched likewise remains auto-filled. Explicit manual entry has precedence.
Training autonomy controls delivery, while the service still computes when
suggestions are off.

## Verification and intentional boundaries

Executable fixtures cover all 13 Part 11 acceptance criteria. Domain tests are
supplemented by real SQLite/live-view-model tests, review widget interaction,
backup round trips, restoration, prescription, position-mapper and schema tests.

Linked groups, a complete gym inventory editor, automatic deloads, automatic
mode transitions, e1RM-selected prescriptions and context-based physiological
diagnoses remain deliberately outside v1.5. The existing e1RM statistic does
not participate in the prescription rule. The 10% guide, three-session review,
policy defaults and U + 2 bridge are product decisions, not clinical thresholds.

The evidence boundary and references are maintained in Part 11 of the planning
document, including ACSM's *Progression Models in Resistance Training for
Healthy Adults* (2009), DOI 10.1249/MSS.0b013e3181915670. The user remains the
final authority over load, repetitions and whether to train.
