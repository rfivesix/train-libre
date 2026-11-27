# Sleep score (v4)

The sleep score is a descriptive, non-clinical product heuristic. Its weights, curves, limits, component targets and labels have **not** been clinically validated. It is not a diagnosis, treatment advice, or a measurement of actual recovery. Consumer device sleep stages are estimates, not polysomnography. Sources below support considering several dimensions of sleep; they do not validate this formula.

## What is scored

The score describes the main sleep episode assigned to its **local wake date**. The longest episode is the anchor; other same-day episodes connected by gaps of at most 90 minutes are treated as fragments of it. More distant sessions are excluded as naps. This is a heuristic: a nearby nap or split sleep across wake dates may be classified incorrectly. Overlapping fragments are repaired into one timeline before measuring duration, so overlap is not counted twice. A session without an observed asleep segment cannot supply a sleep duration.

Sleep duration is required. With only duration the app still displays an explicitly **limited-data estimate**; it does not imply that continuity or stages were good. The completeness percentage is the sum of available weights, not confidence or scientific accuracy. Missing data are omitted and the other weights are normalized to their sum. For example, eight hours of duration alone produces 100 with 45% coverage; six hours alone produces 75 with 45% coverage. These numbers describe progress toward the eight-hour product target, not measured sleep quality. A score is unavailable when no valid positive sleep duration is observed. The app should show limited coverage alongside the estimate.

| Component | Weight | Subscore from 0 to 1 | Availability |
|---|---:|---|---|
| Duration | 45% | `min(asleepMinutes / 480, 1)` | Observed asleep duration > 0; the fixed eight-hour target is a product choice. Longer sleep is not automatically penalized. |
| Continuity | 25% | Mean of available efficiency and wake-after-sleep-onset (WASO) scores. Efficiency: `clamp(efficiencyPercent / 90, 0, 1)`. WASO: `1 / (1 + (max(WASOminutes − 20, 0) / 30)^2)`. | Efficiency requires an observed in-bed interval; WASO requires observed wake data. An asleep-only record does not imply perfect efficiency or no awakenings. |
| Deep | 10% | `clamp(deepMinutes / 90, 0, 1)` | Deep stage present, no unknown timeline segments and unspecified asleep at most 5% of total sleep. |
| REM | 10% | `clamp(REMminutes / 100, 0, 1)` | REM stage present, no unknown timeline segments and unspecified asleep at most 5% of total sleep. |
| Regularity | 10% | `1 / (1 + SD_hours²)` | At least five valid days and a rolling mid-sleep SD; seven days is marked stable. The lookback spans the target day and preceding 14 days. Mid-sleep is estimated from the longest session’s start and duration, not from a physiological measurement; circular clock arithmetic prevents midnight boundary artifacts. This is a heuristic based on schedule variability, **not** the Sleep Regularity Index (SRI). |

A stage not supplied by a device remains unknown; a supplied zero is zero. Coverage can vary across devices and nights, so scores with different available inputs are not perfectly comparable. Low-fidelity consumer stages and irregular or incomplete timelines can still distort the estimate. HealthKit's core stage maps to light; Health Connect's light maps to light; generic asleep is unspecified and never invented as deep or REM.

The stage list percentages use recorded sleep time plus recorded awake time as the denominator. Unspecified sleep contributes to recorded sleep time, but is not assigned to a specific stage; percentages therefore need not add up to 100%. Missing awake samples do not establish that there was no wakefulness.

The normalized weighted mean is scaled to 0–100. To prevent a very short night from being raised too far by other dimensions, the final score is the smaller of that mean and `durationSubscore × 100 + 15`, capped at 100. This continuous duration ceiling is disclosed when it changes the final result. For example, a four-hour night cannot exceed 65 even if all other inputs are perfect. There is no fixed clock-time penalty and no stage or time multiplier. HRV and heart rate are contextual measurements and do not enter this score. Display bands (80+ good, 60–79 average, below 60 poor) are product labels, not clinical classifications.

## History and synchronization

Analyses are tagged `sleep-health-score-v4`. On first read, existing locally stored canonical sessions and stages are reprocessed chronologically without requiring Health access. Analysis writes are transactional and cancellation rolls them back; raw data and canonical sessions are retained. A completed migration is idempotent. New imports trigger a full local recalculation so downstream rolling regularity is not left stale. Existing nights may therefore change because the formula and available inputs changed. Data absent from local canonical records cannot be reconstructed; missing values remain unavailable. Initial platform import and delta-sync windows are separate from this local recalculation; see [Health sync](health_sync_export.md).

Source time-zone information is currently not consistently persisted; local wake-date grouping uses the device's current local time. Travel, daylight-saving changes, source corrections, fragmented nights and sessions crossing local dates can affect grouping and interpretation.

## Evidence and limitations

- Watson et al. (2015), *Recommended Amount of Sleep for a Healthy Adult*, AASM/SRS consensus. Its recommendation concerns adult sleep duration, not this app's eight-hour target or formula. [PubMed](https://pubmed.ncbi.nlm.nih.gov/26039963/).
- Ohayon et al. (2017), *National Sleep Foundation’s sleep quality recommendations: first report*. Discusses sleep-quality indicators, not this scoring formula. [PubMed](https://pubmed.ncbi.nlm.nih.gov/28346153/).
- Buysse (2014), *Sleep Health: Can We Define It? Does It Matter?* Discusses multidimensional sleep health and does not validate this app's score. [Sleep](https://academic.oup.com/sleep/article/37/1/9/2454038).
