# Sleep Health Score (SHS v3)

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre calculates a 0–100 sleep score from available duration, continuity, stage architecture, timing, and regularity inputs. The weights, curves, targets, and penalty thresholds below are product heuristics. The score is not a validated clinical instrument, and the cited sleep research does not validate these formulas or cutoffs.

## Version and persistence

The current analysis version is `sleep-health-score-v3`. The import pipeline passes that version to the scorer and saves it with each nightly analysis. It is version metadata: the scorer does not select a different formula based on the version string. Reimports can recompute and replace analyses.

## Inputs and imported data

The import pipeline repairs each imported stage timeline, calculates nightly metrics, combines sessions for a night, and scores the resulting inputs. It calculates sleep duration, time in bed, efficiency, and wake after sleep onset from the imported session and stage timeline. It derives stage percentages only for stages present in the timeline. An absent stage remains unknown; it is not inferred from another stage.

Apple Health `core`/`asleep_core` maps to light sleep; `deep` and `rem` map to their corresponding stages. Health Connect `light`, `deep`, and `rem` map to those stages. Generic `asleep` or `asleep_unspecified` maps to an unspecified-asleep stage, not light, deep, or REM. Unspecified sleep contributes to total sleep time, but does not supply the deep or REM percentages required for architecture scoring.

Consequently:

- Architecture scoring is unavailable unless duration, deep percentage, and REM percentage are present. If either deep or REM is missing, its architecture score and corresponding stage penalty cannot be calculated.
- Missing light-stage percentage is treated as 0% by the architecture formula, so it does not incur a light-stage penalty. In the continuity fallback it also means no light-stage penalty.
- A night with only unspecified-asleep stages can still have duration, continuity, and timing inputs, but no architecture score or deep/REM penalty.
- If a repaired timeline is empty, the metric calculator produces zero total sleep, zero efficiency, and zero WASO. This is a consequence of that import path, not evidence that the person slept zero minutes.

The timing calculation uses the local start time of the selected core session, not a detected physiological sleep onset. It adds half the combined sleep duration to that start time to estimate mid-sleep. If sessions are fragmented or combined, this estimate need not be the midpoint of actual sleep episodes.

## Base score

Each available domain has a score from 0 to 1. The weighted mean is renormalized over available domains, then scaled to 0–100:

\[
S_{base}=100\,\frac{\sum_{i\in A} w_i S_i}{\sum_{i\in A} w_i}
\]

| Domain | Weight | Availability |
|---|---:|---|
| Duration | 0.30 | Duration is present |
| Continuity | 0.20 | Always produced; see fallback below |
| Architecture | 0.25 | Duration, deep %, and REM % are present |
| Timing | 0.15 | Session start time and duration are present |
| Regularity | 0.10 | Rolling mid-sleep SD is present and at least 5 valid days are available |

The score’s completeness field is the sum of active domain weights, not a confidence or accuracy estimate. If no weighted component is available, the result is unavailable. The result is labeled `good` at 80 or above, `average` at 60 or above, and `poor` below 60; these are display bands, not clinical classifications.

## Domain calculations

### Duration

Let `h` be total sleep time in hours. The score is 1.0 from 7 through 9 hours. Below 7 hours it decays from 7; above 9 it decays from 9. Both sides use a Gaussian with a one-hour spread. Above 10.5 hours the score is 0.

\[
S_D(h)=\begin{cases}
1 & 7\le h\le9\\
0 & h>10.5\\
\exp(-(h-7)^2/2) & h<7\\
\exp(-(h-9)^2/2) & 9<h\le10.5
\end{cases}
\]

### Continuity

Sleep efficiency is mapped through a logistic curve centered at 90%. WASO has a 20-minute grace period, then a quadratic rational penalty with a 30-minute scale. If both are present, continuity is their equal-weight mean; if just one is present, that value is used.

\[
S_{SE}=\frac{1}{1+e^{-50(SE-0.90)}},\qquad
S_{WASO}=\frac{1}{1+(\max(W-20,0)/30)^2}
\]

Only when **both** efficiency and WASO inputs are null, the scorer uses this fallback:

\[
S_{C}=0.9P_{light}+0.1S_D
\]

Here `P_light` is 1 through 65% light sleep and decays as a Gaussian penalty above 65%; if light percentage is absent, it defaults to 0%. If duration is absent, its fallback contribution is 0. This is a continuity proxy, not a measurement of fragmentation. The standard import pipeline calculates and supplies both efficiency and WASO, so this null-input fallback is not the usual imported-night path.

### Stage architecture

The architecture formula estimates deep and REM subscores from their absolute minutes (`duration × stage percentage`). The deep curve rises toward 90 minutes and the REM curve toward 100 minutes, each with a 40-minute Gaussian spread. Light sleep is unpenalized through 65%; above that percentage, a 7-percentage-point Gaussian spread is used. The combined score is:

\[
S_A=\operatorname{clamp}((0.45A_{N3}+0.45A_{REM})P_{light}+0.10,0,1)
\]

The 0.10 term is part of the implementation. When light percentage is absent it uses `P_light = 1`. Architecture scoring is omitted when duration, deep percentage, or REM percentage is missing.

### Timing

The scorer estimates mid-sleep from the local core-session start time plus half the duration, normalizing across midnight. The timing score is a Gaussian centered at 03:30 with a one-hour spread; when mid-sleep is later than 05:30, an additional Gaussian penalty with a half-hour spread applies. These clock targets are model choices, not an assessment of a person’s circadian phase.

### Regularity

For each target night, the pipeline groups sessions by local wake date, keeps the longest session per date, and calculates the sample standard deviation of estimated mid-sleep times over the lookback window (from 14 days before the target date through that date). With fewer than two sessions, the pipeline supplies an SD of zero. The scorer uses regularity only when at least five valid regularity days are reported; it marks the input stable at seven or more days. Its score is:

\[
S_R=\frac{1}{1+(SD_{mid}/1.0)^2}
\]

This is a schedule-variability heuristic. A zero SD supplied by the pipeline does not establish that a person has a regular sleep schedule when there are too few sessions to compare.

## Final stage and timing penalties

After calculating the weighted base score, the scorer computes available penalties and applies the smallest multiplier. This is a software rule, not a measured biological bottleneck:

| Input | Multiplier reaches 1.0 at | Lower endpoint | Multiplier at lower endpoint |
|---|---:|---:|---:|
| REM minutes | 60 min | 40 min | 0.65 |
| Deep minutes | 70 min | 40 min | 0.60 |
| Total sleep time | 6.5 h | 5.0 h | 0.50 |
| Estimated mid-sleep | 05:30 | 07:30 | 0.55 |

Each value is linearly interpolated and clamped between its endpoints. Values beyond the range retain the endpoint multiplier. Missing REM or deep-stage inputs omit their respective penalty. The final score is `clamp(base × minimum available multiplier, 0, 100)`; if no penalty input is present, the multiplier is 1.

## Scientific context and limitations

Sleep duration, efficiency, wake after sleep onset, timing, and other sleep dimensions appear in sleep-health recommendations and multidimensional sleep-health frameworks. Train Libre’s SHS is its own weighted and penalized heuristic; it is not the National Sleep Foundation recommendation, the AASM/SRS sleep-duration consensus, or RU-SATED, and none of those sources validate this implementation’s targets, weights, or score bands. Consumer-device stage labels are vendor classifications mapped into app categories; they are not equivalent to a polysomnography diagnosis.

The calculations depend on the source device’s session and stage data, the completeness of that data, and the app’s timeline repair and aggregation. A score can therefore change when imported data changes even if the person’s actual sleep did not. Use it as a descriptive trend within the app, not to make health decisions.

## References

- Ohayon et al. (2017), *National Sleep Foundation’s sleep quality recommendations: first report*. This consensus paper discusses sleep-quality indicators; it does not specify Train Libre’s formula. [PubMed](https://pubmed.ncbi.nlm.nih.gov/28346153/) · DOI: [10.1016/j.sleh.2016.11.006](https://doi.org/10.1016/j.sleh.2016.11.006)
- Watson et al. (2015), *Recommended Amount of Sleep for a Healthy Adult: A Joint Consensus Statement of the American Academy of Sleep Medicine and Sleep Research Society*. This statement addresses recommended duration for healthy adults; it does not validate Train Libre’s scoring curve. [PubMed](https://pubmed.ncbi.nlm.nih.gov/26039963/) · DOI: [10.5665/sleep.4716](https://doi.org/10.5665/sleep.4716)
- Buysse (2014), *Sleep Health: Can We Define It? Does It Matter?* A perspective on multidimensional sleep health, not a validation of this score. [Oxford Academic](https://academic.oup.com/sleep/article/37/1/9/2454038) · DOI: [10.5665/sleep.3298](https://doi.org/10.5665/sleep.3298)
