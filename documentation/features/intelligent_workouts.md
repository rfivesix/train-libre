# Estimated 1-Rep Max (1RM)

Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre estimates a one-rep maximum from a logged set using the Brzycki equation. It is a calculated training metric, not a measured maximal lift or a safety assessment.

## Formula and valid range

For an effective set load `w` in kilograms and repetition count `r`, the app calculates:

```text
estimated 1RM = w × 36 / (37 − r)
```

The shared calculation accepts `1 ≤ r ≤ 12` and returns no estimate when repetitions are missing or outside that range, or when effective load is missing or non-positive. Some screens apply narrower display eligibility: the live set-row preview, for example, excludes sets above 10 repetitions and warm-up sets. The formula does not use RIR or effort to adjust the estimate.

## How effective load is resolved

Before applying the formula, Train Libre resolves the recorded load from the exercise tracking type and load mode:

- For ordinary loaded exercises, a positive logged weight is used directly.
- For assisted exercises, effective load is body weight minus logged assistance. If body weight is unavailable, or the resulting load is not positive, no estimate is produced.
- For bodyweight and weighted-bodyweight exercises, effective load is body weight plus logged added weight. If body weight is unavailable, only a positive logged added weight is used; otherwise there is no estimate.

The implementation uses the exercise's recorded load mode when available in a workout snapshot, so later catalog changes do not necessarily redefine how that set was logged.

## Bodyweight history

Historical statistics load positive weight measurements in date order and look up the latest measurement on or before the workout's start time. A set before the first recorded measurement has no inferred bodyweight; the app does not extrapolate backward or substitute a generic weight. If the history query fails, the statistics path treats the history as empty.

Live-workout estimates instead use the latest recorded bodyweight at the time the workout loads it. Therefore a bodyweight exercise can have a different effective load in a live workout than in a historical calculation for an earlier date.

## Where the estimate is used

The shared estimate is used in live set previews, workout summaries and details, exercise statistics, personal-record comparisons, and workout progression. Historical statistics calculate estimates per set using that session's bodyweight lookup; live progression uses the current bodyweight value supplied by the workout view model. Personal-record and progression logic may use the estimate as one input, but the estimate alone does not guarantee a record or a recommendation.

The model does not establish that a set is safe, prevent injury, or measure structural capacity. It also does not adjust for sleep, hydration, soreness, or other day-to-day conditions. Treat it as an approximate strength-tracking value and interpret changes in the context of the logged exercise and set.

## Source

- Brzycki, M. (1993). *Strength Testing—Predicting a One-Rep Max from Reps-to-Fatigue*. Journal of Physical Education, Recreation & Dance, 64(1), 88–90. [DOI: 10.1080/07303084.1993.10606684](https://doi.org/10.1080/07303084.1993.10606684). The citation identifies the equation; it does not validate every Train Libre use case or establish clinical or safety claims.
