# Muscle Recovery & Readiness Model

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

## What the tracker shows

The tracker turns eligible logged workout sets into a muscle-specific training-load estimate. It applies time decay to recent sessions and maps the remaining estimate to a 0–100 readiness score:

| Output | Meaning |
| --- | --- |
| Last session load | Weighted set exposure from the most recent eligible session for that muscle. |
| Residual load | The decayed sum of eligible session exposures in the selected history window. |
| Readiness | A heuristic score derived from residual load; it is not a measurement of biological recovery. |
| Recovering | Score below 60. |
| Ready | Score from 60 up to, but not including, 85. |
| Fresh | Score of 85 or more. |
| Data confidence | Share of eligible sets in the latest session with an in-range logged RIR. |

The overall label summarizes how many tracked muscles are below the recovering boundary. It is a categorical summary, not an average across muscle scores. Muscles with no eligible history are shown as Fresh with no data confidence whenever some other muscle has data; if there is no eligible data at all, the analysis reports insufficient data.

## Inputs and eligibility

The analytics query reads completed set logs joined to completed workout logs. By default it selects workouts whose **start time** falls within the last 21 days; the Statistics hub can request another selected range. After selection, decay age uses the workout end time when present and start time otherwise. The query horizon limits which sessions reach the calculation; it is not a decay cutoff inside the engine.

A queried set must be marked completed, not be a warm-up, and include repetitions or duration. The exercise filter accepts `strength` and `plyometric` modalities. If modality is absent, legacy and user-created exercises use category/name checks to exclude recognizable cardio. A missing exercise-to-muscle mapping produces no muscle-specific exposure.

The muscle mapping comes from exercise catalog roles when available, with legacy primary/secondary muscle fields as fallback. Duplicate annotations that resolve to the same tracked group are counted once. A finite catalog contribution is clamped to 0–1 and used in place of the role fallback; absent contribution uses 1.0 for primary and 0.3 for secondary. These are engineering weights, not measured proportions of physiological work.

The query passes repetitions, duration, RIR, set type, role, optional catalog contribution, movement pattern, and workout identity/time to the calculation. It does **not** pass logged weight or RPE. Weight and RPE may exist elsewhere in workout data, but they do not contribute to this recovery calculation.

## Per-set exposure

For each eligible set and each mapped muscle, the engine calculates:

\[
E = W_{role} \times W_{effort} \times W_{reps}
\]

One completed set is the base unit. A finite catalog contribution, clamped to 0–1, supplies `W_role`; otherwise the primary/secondary fallback is 1.0/0.3. `W_effort` is 1.0 for an explicit failure set. Otherwise, an integer RIR from 0 through 5 maps linearly from 1.0 down to 0.5 in 0.1 steps. Missing, negative, or greater-than-five RIR uses 0.7 for the exposure calculation.

`W_reps` is a bounded repetition modifier: 0.8 for duration-only sets or up to 4 reps, 0.9 for 5–8, 1.0 for 9–15, 1.05 for 16–30, and 1.1 above 30. The engine does not calculate tonnage or infer relative intensity from kilograms. A failure set’s explicit type sets its effort weight to 1.0 even if no RIR was saved.

For confidence reporting, only RIR values from 0 through 5 count as present. Coverage is calculated over the latest session’s eligible set contributions for that muscle: high at 80% or more, medium at 40% to below 80%, low below 40%, and none when that muscle has no session history. An out-of-range RIR therefore uses the neutral exposure weight and does not increase coverage.

## Session aggregation and decay

Exposures are summed by workout and muscle. Primary-role and secondary-role contributions are also retained separately for display. Smaller contributions are not discarded solely because they are below one set.

At calculation time, each session contributes an exponential residual:

\[
R(t) = \sum_j L_j \times e^{-\Delta t_j / \tau}
\]

`L_j` is that session’s weighted exposure; `Δt` is elapsed time since its workout completion time, with start time used when no end time exists. The decay constant `τ` is a group-specific engineering profile: 60 hours for shoulders, arms, forearms, and calves; 96 hours for quads, hamstrings, glutes, and adductors; 120 hours for lower back; and 72 hours by default. These settings are model parameters, not claims that a muscle biologically recovers in that time.

The score is `100 / (1 + residual / 2.5)`, clamped to 0–100. The engine labels scores below 60 Recovering, scores from 60 to below 85 Ready, and scores of 85 or more Fresh. Its compact forecast estimates when the decaying score reaches those same boundaries. These outputs describe the model’s response to recorded exposure, not an individual’s actual ability to train.

## Movement patterns and presentation

Movement patterns are retained as context for the latest session’s affected muscles. They do not add a separate systemic-demand load or multiply local muscle exposure. For each muscle, the tracker displays the score and state scale; expanded details show the latest session load and age, forecast, and RIR coverage when available.

## Limits

- This is a deterministic heuristic over logged sets, not a clinical recovery assessment, injury-risk prediction, DOMS measure, or muscle-protein-synthesis model.
- The calculation does not use weight, RPE, sleep, pulse, soreness, or an individual recovery calibration.
- Explicit failure is treated as RIR 0 for exposure, but other RIR values rely on the user’s log and are not independently validated.
- Catalog contribution values are accepted when present, but their presence does not establish that they are experimentally measured muscle contributions.
- The result is computed from workout history when requested; this path does not persist a versioned recovery score.
