# Bayesian TDEE Estimate and Adaptive Calorie Target

> **Scope and limits:** Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

Train Libre separates two related calculations:

1. A recursive Bayesian filter estimates maintenance calories (TDEE) from logged intake and bodyweight trend, starting from a profile-based prior.
2. A bounded controller may adjust the recommended calorie target when recent weight change persistently differs from the selected goal rate.

The controller does not change the displayed maintenance estimate or its uncertainty. These are estimates from user-entered and imported records, not measurements of energy expenditure.

## 1. Inputs and evaluation window

The adaptive input window contains 14 calendar days. Its end is anchored to the completed day before the check-in weekday: the active goal's start weekday, or Monday when no goal is active. This keeps repeated refreshes within one due week on the same input window.

The adapter uses:

- The latest logged weight on each day in the window. It smooths those available daily values with an EWMA using $\alpha=0.35$, then fits a linear regression against their actual day offsets to estimate kg/week. Missing days are not filled with estimated weights.
- Logged food calories and unlinked fluid-entry calories. Intake is averaged over days with a positive calorie total; days without logged calories are not treated as zero-intake days. Unresolved food calories are flagged.
- A profile-based maintenance prior using current or recent weight, body-fat percentage when available, profile details, declared activity, workouts, steps, and the user's extra-cardio setting. When there is no weight in the window, the adapter may use the latest prior measurement or the active goal's baseline; if no positive weight is available, generation fails.

The profile prior bootstraps the filter; subsequent eligible estimates chain from the saved posterior. A missing weight trend or missing logged intake prevents an observation update, but the filter can still return a prediction from its prior.

## 2. Maintenance observation

When both a weight slope and at least one positive-calorie intake day are available, the observation is:

$$M_t = \text{averageLoggedCalories}_t - \left(\text{smoothedWeightSlopeKgPerWeek}_t \cdot \frac{7700}{7}\right)$$

The conversion coefficient is fixed at **7,700 kcal/kg** in the current model. It is an engineering approximation for translating weekly mass change into a daily energy-balance signal; it does not establish the tissue composition of short-term scale changes. If either input is missing, no maintenance observation is formed for that refresh.

## 3. Observation uncertainty

The model combines a baseline variance, intake-day variability, and weight-slope uncertainty:

$$V_{ref} = V_{base} + V_{intake} + V_{slope}$$

$$V_{base}=120^2$$

$$V_{intake}=\left(\frac{320}{\sqrt{\max(\text{intakeLoggedDays},1)}}\right)^2$$

$$V_{slope}=\left(\frac{0.55\cdot(7700/7)}{\sqrt{\max(\text{weightLogCount}-1,1)}}\right)^2$$

The reference variance is multiplied by a phase factor: 2.25 for confirmed phase days 1–7, 1.50 for days 8–14, and 1.00 after day 14. This changes uncertainty, not the observation coefficient or its direction.

Completeness and quality add further penalties. For a window of $D$ days, with $I$ logged intake days and $W$ logged weight days:

$$C=\frac{1}{\sqrt{\operatorname{clamp}(I/D,0.05,1)\cdot\operatorname{clamp}((W-1)/(D-1),0.05,1)}}$$

The observation variance is $R=V_{ref}\cdot C^2\cdot M_{qual}^2$, where $M_{qual}$ starts at 1.12 when fewer than five intake days are logged, 1.10 when fewer than five weight logs are present, and 1.30 when unresolved food calories are flagged; applicable penalties multiply. History-based calibration may then scale observation variance and process variance, within configured bounds. These constants and multipliers are model choices, not validated measures of an individual's true error.

## 4. Recursive estimate

The latent state is maintenance calories per day. The default weekly process standard deviation is 60 kcal/day, giving baseline process variance $Q_{process}=60^2=3600$. Recent posterior movement can adjust this process variance. The implementation advances the variance once per elapsed due week and caps variance relative to the reference observation variance.

For each eligible observation, the filter predicts from the prior and updates with the standard scalar Kalman equations:

$$X_{t|t-1}=X_{t-1}$$

$$P_{t|t-1}=\min(P_{t-1}+Q_{process}\Delta t, P_{cap})$$

$$K_t=\frac{P_{t|t-1}}{P_{t|t-1}+R_t}$$

$$X_t=X_{t|t-1}+K_t(M_t-X_{t|t-1})$$

$$P_t=(1-K_t)P_{t|t-1}$$

Without an observation, the filter makes a prediction-only step: the mean is not updated by intake/weight data, while uncertainty can grow with elapsed due weeks. The posterior mean is clamped to 1,200–5,000 kcal/day. There is no separate gain limiter in the filter. Adjacent rolling windows can overlap; the implementation does not explicitly model their covariance, so the result should not be read as if each weekly observation were independent evidence.

The interface displays the maintenance estimate and a range calculated as the posterior mean plus or minus **one posterior standard deviation**. This is an uncertainty display, not a 95% interval or a calibrated probability statement. Confidence labels are separate heuristic categories based on data sufficiency and filter state.

## 5. History-based noise calibration

The model retains up to eight recent posterior means and observation residuals. After at least four history samples, residual variability can adjust observation variance ($R$), and root-mean-square changes in posterior means can adjust process variance ($Q$). Both adjustments are blended with their defaults and clamped to configured ranges.

When the recommendation algorithm version changes, the next service refresh recomputes the recommendation. The stored posterior mean and variance are retained, while the histories used for noise calibration are cleared before the new model runs. This avoids mixing residual history from the prior observation model with the fixed-coefficient model.

## 6. Bounded trajectory controller

The base calorie target is the estimated maintenance plus a rounded goal-rate adjustment:

$$C_{base}=X_t+\operatorname{round}\left(\text{targetRateKgPerWeek}\cdot\frac{7700}{7}\right)$$

The controller compares the selected target rate with the observed smoothed weight slope:

$$e_t=\text{targetRateKgPerWeek}-\text{observedRateKgPerWeek}$$

It only calculates a correction when both the current and previous recommendations have compatible algorithm versions, the same goal and target rate, sufficient data, and errors beyond the 0.05 kg/week deadband in the same direction. The current window must be at least 14 days and contain at least 10 logged intake days and 7 weight logs, with no unresolved-food-calorie flag. A pending phase change or a confirmed phase younger than 15 days also disables correction.

For eligible observations, the controller rounds $0.65\cdot(7700/7)\cdot e_t$ to whole kcal/day, clamps it to $[-150,150]$, then limits its change from the previous correction to at most 100 kcal/day. With no compatible previous recommendation, correction is zero. The final calorie target adds the correction to the base target and applies a 1,200 kcal/day floor. This controller does not adjust the maintenance estimate.

## 7. Persistence, application, and telemetry

The latest generated recommendation snapshot and recursive estimator state are saved in local app preferences. The snapshot includes its due-week key and algorithm version. Within the same due week, a refresh reuses the stored pre-update prior so it does not apply the same due-week observation repeatedly. When a new due week is processed, the prior posterior is advanced by the elapsed due weeks.

Generating or refreshing a recommendation does not by itself replace active calorie or macro targets. The app applies a generated recommendation only through an explicit apply action; a separate workflow may also recalculate and apply after the user chooses that action.

Recommendation generation calls the optional telemetry service with counts of weight logs and intake days, window length, effective sample size, confidence category, warning level, quality flags, and presence indicators for slope/intake. Telemetry transmission is governed by the app's telemetry opt-in. These properties are not the underlying daily calorie or bodyweight series.

## 8. Interpretation and limitations

The estimate cannot identify why bodyweight changed. Hydration, sodium, glycogen, gastrointestinal contents, menstrual-cycle effects, logging omissions, and tissue composition can all affect short-term trends. A smooth estimate or high interface confidence does not remove those limitations, and the model is not evidence that a particular calorie target is medically appropriate.
