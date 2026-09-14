# Muscle Recovery & Readiness Model

> **Non-medical disclaimer:** This remains a fitness-oriented, log-based
> readiness heuristic for healthy people. It is not a measure of biological
> recovery, an injury-risk prediction, or medical advice. Its purpose is to
> make recorded training exposure understandable and comparable over time.

## Quick Overview

The tracker converts completed training sets into a muscle-specific,
time-decaying **residual load**. That residual load becomes one readiness score
and one matching state:

| Output | Meaning |
| --- | --- |
| Last session load | Only the latest workout's calculated dose for this muscle. |
| Residual load | Latest load plus the diminished remaining effect of recent earlier sessions. |
| Readiness | A 0–100 log-based estimate derived from residual load. |
| Recovering | Readiness below 60. |
| Ready | Readiness from 60 up to, but not including, 85. |
| Fresh | Readiness of 85 or more. |
| Data confidence | Based on how much of the latest session has a plausible logged RIR. |

Different muscles keep different baseline decay rates: the current profile
lets biceps and triceps decay faster than quads, hamstrings, glutes, and lower
back. Training dose and recency still matter more than the muscle label alone.

### Tracker presentation

The state is communicated once by its enclosing section. Each muscle row then
contains only its changing values: muscle name, numeric readiness, a shared
three-zone readiness scale (recovering / ready / fresh) with a score marker,
and — unless already fresh — compact remaining hours. Tapping a row exposes
supporting values in structured detail rows: latest-session load and age,
remaining forecast(s), and RIR coverage. Role ratios, qualitative
load-pressure labels, duplicated state badges, and repeated prose are
intentionally not presented as primary guidance.

### Worked Examples

These examples use the current engineering calibration: 10 repetitions,
primary role, RIR 2 equals `1.0 × 0.8 × 1.0 = 0.8` load units per set. They
show the exact behaviour of the model rather than claiming that the displayed
hours are biological measurements.

| Scenario | Last session load | At session end | After 24 h | After 48 h | Fresh from |
| --- | ---: | --- | --- | --- | --- |
| Chest: 3 direct sets × 10 reps at RIR 2 | 2.40 | Residual 2.40, **51**, Recovering | 1.72, **59**, Recovering | 1.23, **67**, Ready | about 122 h |
| Triceps: 3 secondary sets × 10 reps at RIR 2 | 0.72 | Residual 0.72, **78**, Ready | 0.48, **84**, Ready | 0.32, **89**, Fresh | about 30 h |
| Chest: today's 1 set × 10 reps at RIR 3, plus a Failure set 13 days ago | 0.70 | Residual 0.71, **78**, Ready | 0.51, **83**, Ready | 0.37, **87**, Fresh | about 45 h |

The third row illustrates the central correction over v1: the old Failure set still
has a tiny residual effect, but it does not turn today's single RIR-3 set into
a falsely large "last load" or an all-session high-fatigue flag.

## 1. What Changed from v1

v1 had useful inputs — completed sets, repetitions, RIR, set type, exercise
modality, primary/secondary muscle assignments, movement patterns, and workout
timestamps — but combined them in a way that could misrepresent the latest
load:

- It uses the **latest relevant session time** as the clock, but uses the sum
  of equivalent sets from **all sessions in the 14-day lookback** to extend
  that latest session's recovery window.
- A previous failure session can set one `highSessionFatigue` flag for the
  whole lookback, even when the latest session was light.
- RIR is reduced to a binary trigger (`avgRIR <= 0.5`), despite being logged
  per set. Repetitions and set type have almost no recovery-specific effect.
- A session with less than 1.0 equivalent set is discarded completely. This
  loses several small, recent secondary-muscle exposures instead of allowing
  them to accumulate modestly.
- The status boundary and the displayed readiness score disagree: the current
  `Fresh` state begins while the current score is still 85/100.

The current model replaces the all-or-nothing, fixed-lookback aggregation with a transparent
**residual training-load estimate**. Every valid training session creates a
muscle-specific load impulse that gradually decays. Recent sessions matter
most; older sessions naturally fade rather than abruptly disappearing or
continuing to inflate the latest session.

## 2. Evidence and Design Boundaries

The model follows the direction of the evidence, not a claim that a universal
formula can determine a person's exact recovery time:

- Total volume, set duration, and proximity to failure are important acute
  determinants of voluntary-performance and perceived-fatigue impairment in
  resistance training. [Varela-Olalla et al., 2025](https://pubmed.ncbi.nlm.nih.gov/40644670/)
- RIR is useful for prescribing effort, but its accuracy is person- and
  load-dependent; it is less dependable at lighter loads. It must therefore
  be a bounded signal, not an absolute truth or a sharp all-or-nothing rule.
  [Hughes et al., 2020](https://pubmed.ncbi.nlm.nih.gov/33337690/)
- Recovery time varies by protocol, individual, and outcome. For example, a
  controlled comparison of squat, bench press, and deadlift sessions did not
  justify a simple "larger muscle/exercise = universally longer recovery"
  rule. [Zourdos et al., 2019](https://pubmed.ncbi.nlm.nih.gov/30779596/)
- Resistance-training load has no single accepted monitoring formula. Session
  load, perceived exertion, recovery intervals, and performance each provide
  different information. [McGuigan, 2017](https://pubmed.ncbi.nlm.nih.gov/26780346/)

Accordingly, all numeric weights and time constants in the current model are **engineering
calibrations**, must be documented as such, and require deterministic tests.
They are deliberately not presented as medical thresholds or direct copies of
one study.

## 3. Inputs and Eligibility

### 3.1 Existing data used by the current model

| Input | Source | Current use |
| --- | --- | --- |
| Completion, reps, duration | `set_logs` | Identifies a performed set and provides bounded work context. |
| RIR | `set_logs.rir` | Per-set proximity-to-failure modifier when plausible. |
| Set type | `set_logs.set_type` | Excludes warm-ups; treats explicit failure deterministically. |
| Workout end time | `workout_logs.end_time` | Starts the post-session decay clock; falls back to start time for historical data. |
| Modality | exercise catalog | Includes strength and plyometric work; excludes cardio, mobility, stretching, and balance. |
| Primary/secondary roles | `exercise_muscles` | Splits a set's local exposure among assigned muscles. |
| Movement pattern | exercise catalog | Explains the exposure and supports a separate session-demand signal. |
| Muscle profile | domain configuration | Preserves different baseline recovery kinetics per muscle group. |

The data model already has `exercise_muscles.contribution`. The current model uses it when
populated; the current shipped catalog generally leaves it empty, so the
explicit fallback role weights apply in ordinary use.

### 3.2 Eligible sets

- A set must be completed and contain repetitions or a duration.
- `strength` and `plyometric` modalities are eligible. Existing legacy
  fallbacks remain for older or user-created exercises without catalog
  metadata.
- Warm-up sets contribute no recovery dose.
- A `failure` set has RIR 0 by definition, regardless of an absent saved RIR.
- A dropset contributes the work that the user actually logged, but receives
  **no invented dropset multiplier**. The app does not store the individual
  reductions, repetitions, or effort of the sub-sets needed to justify one.
- Missing, implausible, or unusually high RIR values use a neutral fallback
  for the calculation and lower data-confidence; they must not be silently
  interpreted as maximal effort.

## 4. Per-Set Exposure

For each eligible set `s` and affected muscle `m`, calculate a bounded local
exposure:

\[
E_{s,m} = B_s \cdot W_{role}(s,m) \cdot W_{effort}(RIR_s) \cdot W_{reps}(s)
\]

Where:

- `B_s` is one completed working-set unit.
- `W_role` uses the catalog contribution when it exists. Until then, it uses
  an explicit, conservative fallback: primary `1.0`, secondary `0.3`.
- `W_effort` is a smooth, capped curve: lower RIR raises exposure gradually;
  it is not a single `+24 h` step.
- `W_reps` is only a bounded context modifier alongside RIR. Raw repetition
  count and tonnage must not be treated as universal intensity measures:
  five heavy repetitions and twenty light repetitions are not directly
  comparable from logs alone.

The current core calibration is deliberately modest: primary/secondary
fallbacks are `1.0`/`0.3`; RIR 0 through 5 maps smoothly from `1.0` to `0.5`
in `0.1` steps; missing or implausible RIR uses `0.7`; and repetitions are
bounded between `0.8` and `1.1`. These are documented engineering defaults,
covered by regression tests, and may be recalibrated only alongside an
explicit evidence and test update.

The model retains direct and indirect exposure separately in the payload.
That lets the UI explain *why* a muscle is affected without claiming that a
secondary role is identical to direct work.

## 5. Session and Time-Decay Model

### 5.1 Session impulse

Aggregate the per-set exposures by muscle within one completed workout:

\[
L_{session,m} = \sum_{s \in session} E_{s,m}
\]

Small sessions are not discarded. A very small secondary contribution remains
small, but several relevant exposures can add up over time.

The payload keeps `lastSessionLoad` distinct from any accumulated value. A
multi-day total is never labelled as the latest load.

### 5.2 Residual exposure

At the current time `t`, each session contributes an exponentially decaying
residual:

\[
R_m(t) = \sum_j L_{j,m} \cdot e^{-\Delta t_j / \tau_m}
\]

- `\Delta t_j` is measured from `workout_logs.end_time`; historical sessions
  without it fall back to `start_time`.
- `\tau_m` is the muscle group's baseline time constant.
- The calculation queries a sufficiently conservative history horizon; it has
  no behavioural discontinuity at an arbitrary 14-day boundary.

This is the key correction over v1: a hard session thirteen days ago has only
a tiny residual effect, while two moderate sessions in the last 48 hours can
meaningfully combine.

### 5.3 Different muscle recovery kinetics are retained

The current model explicitly retains different baseline recovery profiles. Quads,
hamstrings, glutes, adductors, and lower back may use slower baseline decay
than smaller groups such as biceps, triceps, calves, and shoulders. The
profiles are calibration defaults, not biological promises; they represent a
transparent prior that is then adjusted by the user's recorded dose, effort,
and recency.

The existing muscle alias mapping and catalogue vocabulary remain the single
source for resolving exercises into the tracked major groups.

## 6. Movement Patterns and Systemic Demand

Movement patterns must not be used to apply a second, hidden local-muscle
multiplier: the primary/secondary role already allocates local exposure.
Doing both would double count compound movements.

Instead, the current model records movement-pattern exposure in two honest ways:

1. **Exposure context:** the payload records whether recent load came from
   horizontal pushes, squats, hinges, or direct isolation work.
2. **No hidden double counting:** a pattern is not silently added to every
   muscle's residual exposure after primary/secondary roles already allocated
   that set.

Missing or unclassified patterns lower explanatory detail but do not prevent
the underlying muscle calculation when roles are known.

## 7. Readiness, States, and Confidence

The engine maps residual exposure to a continuous log-based readiness estimate
and derives the state from that **same score**. This removes the current
`Fresh at 85/100` contradiction.

The typed result contains:

- `lastSessionAt`, `lastSessionLoad`, `lastSessionDirectLoad`, and
  `lastSessionIndirectLoad`
- `residualLoad` and its associated readiness score
- RIR coverage (`setsWithRir / eligibleSets`)
- direct/indirect and movement-pattern summaries
- `dataConfidence`: high at 80% or more RIR coverage in the latest session,
  medium from 40% to below 80%, low below 40%, and none without a session
- state (`recovering`, `ready`, `fresh`) derived from the readiness score

## 8. Scope Limits

- Do not use RPE as a principal strength-training input. It exists in the
  schema but is not collected through the ordinary strength-set flow.
- Do not infer true relative intensity from raw kilograms, because bodyweight,
  assistance, exercise mechanics, and missing bodyweight make it unreliable.
- Do not manufacture a precise per-muscle contribution table before the
  catalog actually provides validated `contribution` data.
- Do not claim injury prediction, DOMS measurement, muscle-protein synthesis,
  or clinical recovery.
- Do not add a database migration: the current model can derive its data from existing logs.

## 9. Verification Coverage

The implementation is covered by deterministic tests for:

1. Readiness and residual load decline monotonically as time passes.
2. A RIR-0 failure set produces more exposure than otherwise comparable RIR-1,
   RIR-2, and RIR-3+ sets, without an unbounded jump.
3. Missing RIR applies the neutral fallback and reduces confidence.
4. A thirteen-day-old failure session does not substantially inflate a light
   session today.
5. Two recent moderate sessions combine through residual exposure.
6. Several sub-1.0 secondary exposures accumulate rather than disappear.
7. Primary exposure exceeds otherwise equal secondary exposure.
8. Warm-up is excluded; failure and dropset handling match the input contract.
9. Start-time fallback works for historical logs without an end time.
10. Each muscle's distinct baseline profile changes decay/readiness in the
    intended direction.
11. State boundaries and displayed readiness score always agree.
12. Legacy exercises without current catalog metadata retain their existing safe
    fallback classification.
