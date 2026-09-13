# Muscle Recovery & Readiness Model v2 — Implementation Plan

> **Status: core engine implemented; UI follow-up pending.** This document is
> the approved replacement plan for `muscle_recovery_model.md`. The existing
> document remains linked until the recovery-screen redesign has shipped.

> **Non-medical disclaimer:** This remains a fitness-oriented, log-based
> readiness heuristic for healthy people. It is not a measure of biological
> recovery, an injury-risk prediction, or medical advice. Its purpose is to
> make recorded training exposure understandable and comparable over time.

## 1. Why a v2 Model Is Needed

The current tracker has useful inputs — completed sets, repetitions, RIR,
set type, exercise modality, primary/secondary muscle assignments, movement
patterns, and workout timestamps — but combines them in a way that can
misrepresent the latest load:

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

v2 replaces the all-or-nothing, fixed-lookback aggregation with a transparent
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

Accordingly, all numeric weights and time constants in v2 are **engineering
calibrations**, must be documented as such, and require deterministic tests.
They are deliberately not presented as medical thresholds or direct copies of
one study.

## 3. Inputs and Eligibility

### 3.1 Existing data used by v2

| Input | Source | v2 use |
| --- | --- | --- |
| Completion, reps, duration | `set_logs` | Identifies a performed set and provides bounded work context. |
| RIR | `set_logs.rir` | Per-set proximity-to-failure modifier when plausible. |
| Set type | `set_logs.set_type` | Excludes warm-ups; treats explicit failure deterministically. |
| Workout end time | `workout_logs.end_time` | Starts the post-session decay clock; falls back to start time for historical data. |
| Modality | exercise catalog | Includes strength and plyometric work; excludes cardio, mobility, stretching, and balance. |
| Primary/secondary roles | `exercise_muscles` | Splits a set's local exposure among assigned muscles. |
| Movement pattern | exercise catalog | Explains the exposure and supports a separate session-demand signal. |
| Muscle profile | domain configuration | Preserves different baseline recovery kinetics per muscle group. |

The data model already has `exercise_muscles.contribution`, but the shipped
catalog intentionally leaves it empty. v2 must use it only when populated and
must otherwise show that fallback role weights were used.

### 3.2 Eligible sets

- A set must be completed and contain repetitions or a duration.
- `strength` and `plyometric` modalities are eligible. Existing legacy
  fallbacks remain for older or user-created exercises without catalog
  metadata.
- Warm-up sets contribute no v2 recovery dose.
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
  it is not a single `+24 h` step. The exact calibration is decided together
  with tests and documented before release.
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

The model must retain direct and indirect exposure separately in the payload.
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

The payload keeps `lastSessionLoad` distinct from any accumulated value. UI
text must never label a multi-day total as the latest load.

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

v2 explicitly retains different baseline recovery profiles. Quads,
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

Instead, v2 records movement-pattern exposure in two honest ways:

1. **Explanation:** a muscle card can state that its recent load came from
   horizontal pushes, squats, hinges, or direct isolation work.
2. **Separate session-demand context:** compound, whole-body patterns can
   contribute to an optional, clearly labelled session-demand indicator. It
   is not silently added to every muscle's residual exposure.

Missing or unclassified patterns lower explanatory detail but do not prevent
the underlying muscle calculation when roles are known.

## 7. Readiness, States, and Confidence

The engine maps residual exposure to a continuous log-based readiness estimate
and derives the state from that **same score**. This removes the current
`Fresh at 85/100` contradiction.

The typed result should contain at least:

- `lastSessionAt`, `lastSessionLoad`, `lastSessionDirectLoad`, and
  `lastSessionIndirectLoad`
- `residualLoad` and its associated readiness score
- RIR coverage (`setsWithRir / eligibleSets`)
- direct/indirect and movement-pattern summaries
- `dataConfidence` with reasons, such as missing RIR, fallback muscle roles,
  or missing end time
- state (`recovering`, `ready`, `fresh`) derived from the readiness score

The compact UI should lead with the state, score, and confidence. Technical
breakdowns remain available on expansion; UI work begins only after the engine
and tests are accepted.

## 8. Explicit Non-Goals for the First v2 Release

- Do not use RPE as a principal strength-training input. It exists in the
  schema but is not collected through the ordinary strength-set flow.
- Do not infer true relative intensity from raw kilograms, because bodyweight,
  assistance, exercise mechanics, and missing bodyweight make it unreliable.
- Do not manufacture a precise per-muscle contribution table before the
  catalog actually provides validated `contribution` data.
- Do not claim injury prediction, DOMS measurement, muscle-protein synthesis,
  or clinical recovery.
- Do not add a database migration: v2 can derive its data from existing logs.

## 9. Implementation Sequence

1. Create a pure `RecoveryLoadEngine` domain service with typed input and
   typed output. Keep database querying and Flutter UI outside it.
2. Update recovery retrieval to pass individual sets, role assignments,
   movement patterns, and end timestamps into the engine.
3. Add the v2 payload fields while retaining safe parsing defaults for older
   callers and widgets.
4. Replace the old fixed-window and 14-day aggregate logic only after the
   pure-engine tests pass.
5. Rewrite `muscle_recovery_model.md` from the accepted v2 behaviour and
   replace this draft as the public documentation source.
6. Redesign the Recovery Tracker UI around the new typed payload.

## 10. Required Regression Tests

The implementation must cover at least:

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
12. Legacy exercises without v2 catalog metadata retain their existing safe
    fallback classification.

## 11. Future Optional Signal

After v2 is stable, a voluntary short check-in for local soreness, perceived
readiness, sleep, or stress can complement the log-only estimate. It must
remain optional and be presented as a separate self-report signal. Subjective
well-being measures can be sensitive to acute and chronic training changes,
but they are complementary rather than a replacement for training data.
[Saw et al., 2016](https://pubmed.ncbi.nlm.nih.gov/26423706/)
