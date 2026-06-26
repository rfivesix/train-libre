# Fitness-Oriented Bayesian TDEE Estimator & Adaptive Diet Phase Engine

> [!IMPORTANT]
> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking performance and dietary habits. It is not intended for clinical use, diagnostics, or managing medical conditions (such as eating disorders or endocrine/metabolic diseases). All calorie estimates, adaptive calculations, and target adjustment suggestions are sports-science-inspired abstractions and engineering design choices rather than prescriptive clinical thresholds or direct experimental derivations.

The **Bayesian TDEE Estimator** is the mathematical foundation of Train Libre's adaptive diet recommendations. It runs entirely on-device, implementing a customized one-dimensional **Recursive Kalman Filter** to estimate a user's latent Total Daily Energy Expenditure (TDEE). Unlike simple moving averages or static calculators, this estimator models metabolic changes dynamically, using a simplified dynamic energy balance heuristic inspired by Hall’s mathematical models of human body weight change and energy imbalance. It assigns mathematical certainty to logging habits, scales observation variance based on logging completeness, and automatically manages calorie target changes.

---

## 1. The Observation Model

At any given week *t*, the estimator receives a logging context containing the user's average calorie intake, bodyweight readings, and active diet phase. It computes an **Observed Maintenance** value (*M_t*) by adjusting average calorie intake against body mass change:

$$M_t = \text{avgLoggedCalories}_t - \left(\text{smoothedWeightSlopeKgPerWeek}_t \cdot \frac{\text{kcalPerKg}_t}{7}\right)$$

### Dynamic Kcal/Kg Scaling (Ramp Model)
The energetic value of bodyweight changes (*kcalPerKg*) is not static. During transitions to new diet phases, water weight fluctuations and metabolic adaptations skew short-term readings. To compensate, Train Libre implements a **9-Week Linear Ramp**:

*   **Week 1**: Starts at a highly conservative baseline:
    $$\text{kcalPerKg} = 3000 \text{ kcal/kg}$$
*   **Weeks 2 to 8**: Linear transition toward the mature baseline:
    $$\text{kcalPerKg}_t = 3000 + (7700 - 3000) \cdot \left(\frac{t_{\text{weeks}} - 1}{8}\right)$$
*   **Week 9+ (Mature)**: Scales to the physiological standard:
    $$\text{kcalPerKg} = 7700 \text{ kcal/kg}$$

*Note: The 3000→7700 kcal/kg 9-week linear ramp is an engineering safeguard and modeling abstraction to attenuate early water-driven weight changes; it is not directly specified in any single study but is chosen to be conservative relative to empirically observed weight change energy densities.*

This linear transition prevents sudden, massive adjustments to calorie recommendations during the initial, highly volatile weeks of a new diet phase.

---

## 2. Mathematical Modeling of Uncertainty (Observation Variance)

A Kalman Filter relies on the ratio of system process noise to observation noise to adjust its update weight (Kalman Gain). Train Libre computes the **Observation Variance** (*R_t*) dynamically for each logging cycle based on data density and accuracy.

*Note: Numeric values for base model error, day-to-day logging noise, and slope deviations are heuristic engineering parameters and modeling abstractions calibrated from the variability reported in free-living energy intake modeling studies rather than formal inferential statistics from a single paper.*

### Step 2.1: Reference Variance (*V_ref*)
The baseline uncertainty is a combination of three independent standard error sources:

$$V_{\text{ref}} = V_{\text{base}} + V_{\text{intake}} + V_{\text{slope}}$$

Where:
*   **Base Model Mismatch (*V_base*)**: Represents residual model error under ideal logging conditions (default standard deviation: 120 kcal/day):
    $$V_{\text{base}} = 120^2 = 14400$$
*   **Intake Day-to-Day Error (*V_intake*)**: Models the standard error of food logs over the window (default day-to-day deviation: 320 kcal/day):
    $$V_{\text{intake}} = \left(\frac{320}{\sqrt{\text{intakeLoggedDays}}}\right)^2$$
*   **Weight Slope Error (*V_slope*)**: Models the standard error of the linear weight trend based on weight reading density (default trend deviation: 0.55 kg/week):
    $$V_{\text{slope}} = \left(\frac{0.55 \cdot \frac{\text{kcalPerKg}}{7}}{\sqrt{\text{weightLogCount} - 1}}\right)^2$$

### Step 2.2: Completeness Penalty Multiplier (*M_comp*)
If the user logs sparsely, the uncertainty of the observation must be penalized. Train Libre calculates localized completeness coefficients clamped between 0.05 and 1.0:

$$\text{intakeCompleteness} = \text{clamp}\left(\frac{\text{intakeLoggedDays}}{\text{windowDays}}, 0.05, 1.0\right)$$

$$\text{weightCompleteness} = \text{clamp}\left(\frac{\text{weightLogCount} - 1}{\text{windowDays} - 1}, 0.05, 1.0\right)$$

The completeness multiplier *M_comp* scales observation variance quadratically:

$$M_{\text{comp}} = \frac{1}{\sqrt{\text{intakeCompleteness} \cdot \text{weightCompleteness}}}$$

### Step 2.3: Data Quality Multipliers (*M_qual*)
The engine applies multiplicative penalties for sparse data or unresolved logs:
*   **Sparse Intake Penalty**: If *intakeLoggedDays* < 5, apply a multiplier of 1.12.
*   **Sparse Weight Penalty**: If *weightLogCount* < 5, apply a multiplier of 1.10.
*   **Unresolved Food Calories**: If the user logged custom food items with unlinked or incomplete nutritional profiles, apply a multiplier of 1.30.

### Final Combined Observation Variance (*R_t*)
$$R_t = V_{\text{ref}} \cdot M_{\text{comp}}^2 \cdot M_{\text{qual}}^2$$

Sparse logging or unlinked foods rapidly balloon *R_t*, signaling the filter to discount the current week's observation and lean heavily on the prior estimate.

---

## 3. The Kalman Filter Update Equations

At each logging cycle, the filter runs a prediction step followed by a correction step.

### Step 3.1: The Prediction Step
The system state moves forward in time. The prior mean remains constant, but the state uncertainty (*P*) increases due to metabolic drift (process noise *Q* = 40² = 1600 kcal²/week):

$$X_{t|t-1} = X_{t-1}$$

$$P_{t|t-1} = \min\left(P_{t-1} + Q \cdot \Delta t, \, V_{\text{cap}}\right)$$

Where Δ*t* is the number of weeks elapsed since the last observation, and the variance cap *V_cap* = 10 · *V_ref* bounds maximum uncertainty.

### Step 3.2: The Correction Step (Kalman Gain)
If an observation is available (i.e., both intake and weight were logged), the filter computes the **Kalman Gain** (*K_t*) and updates the posterior state:

$$K_t = \frac{P_{t|t-1}}{P_{t|t-1} + R_t}$$

$$X_t = X_{t|t-1} + K_t \cdot \left(M_t - X_{t|t-1}\right)$$

$$P_t = (1 - K_t) \cdot P_{t|t-1}$$

### Step 3.3: Clamping & Bounds
To maintain physiological safety, the posterior mean *X_t* is strictly clamped:

$$\text{clamp}(X_t, \, 1200\text{ kcal}, \, 5000\text{ kcal})$$

Posterior variance is kept above a floor of 1.0:

$$\text{clamp}(P_t, \, 1.0, \, V_{\text{cap}})$$

---

## 4. History-Based Adaptive Calibration

To accommodate individual logging variance, Train Libre maintains a rolling 8-week history of posterior means, observation residuals, and implied maintenance logs to perform on-the-fly calibration of *Q* and *R*.

### Observation Noise Calibration (*R_scale*)
If the user's historical residuals differ wildly from predictions, the base observation noise is scaled dynamically:

$$\text{residualVariance} = \frac{1}{N-1} \sum_{i=1}^N (e_i - \bar{e})^2$$

$$R_{\text{scale}} = \text{clamp}\left(\frac{\text{residualVariance}}{R_{\text{base}}}, \, 0.50, \, 2.60\right)$$

### Latent Process Noise Calibration (*Q_scale*)
If the user's actual calculated TDEE is shifting rapidly week-to-week, the process noise *Q* (metabolic drift) is increased to allow faster filter tracking:

$$\text{weeklyRmsDelta} = \sqrt{\frac{1}{N-1} \sum_{i=2}^N (X_i - X_{i-1})^2}$$

$$Q_{\text{scale}} = \text{clamp}\left(\left(\frac{\text{weeklyRmsDelta}}{40}\right)^2, \, 0.60, \, 1.90\right)$$

---

## 5. Residual Variance Bias & Stabilization Heuristic

### Residual Bias Indicators
The estimator summarizes the 8-week history of residuals (*e_t* = *M_t* - *X_{t|t-1}*) to check for persistent systematic bias. These indicators are data-quality suggestions rather than metabolic or clinical diagnostics:
*   **Potential Logging Variance Indicator (data-quality hint, not a metabolic diagnosis)**: If the mean residual is > +40 kcal/day, the user's logs may be under-reporting portion sizes or overestimating calorie burns.
*   **Potential Logging Variance Indicator (data-quality hint, not a metabolic diagnosis)**: If the mean residual is < -40 kcal/day, the user's logs may be over-reporting portion sizes.

### Confidence Ratings
Recommendations are given an interpretative confidence rating based on logging history and uncertainty:
1.  **High Confidence**: Logging history ≥ 21 days, effective sample size ≥ 10, and posterior variance ≤ 25% of the variance cap.
2.  **Medium Confidence**: Logging history ≥ 14 days, effective sample size ≥ 7, and posterior variance ≤ 45% of the variance cap.
3.  **Low Confidence**: Logging history ≥ 7 days, effective sample size ≥ 4, and posterior variance ≤ 70% of the variance cap.
4.  **Not Enough Data**: Assigned if the above conditions are unmet, or during the initial stabilization bootstrap phase.

---

## 6. Non-Clinical Heuristic Disclaimer
The Bayesian TDEE Estimator is a sports-science-inspired, non-clinical fitness heuristic based on thermodynamic energy balance concepts and recursive filtering. While highly stable for healthy individuals tracking physical performance, it is not a diagnostic tool and does not apply to clinical conditions (such as eating disorders, endocrine disorders, or metabolic pathologies). The underlying mathematical model is based on healthy population averages and may not apply to individuals with metabolic or medical concerns. Users should consult a qualified healthcare professional before making changes to their caloric intake.

---

## 7. Scientific References & Sources
- Hall, K. D. (2008) — *The dynamics of human body weight change*. DOI: [10.1371/journal.pcbi.1000045](https://doi.org/10.1371/journal.pcbi.1000045)
- Hall et al. (2011) — *Quantification of the effect of energy imbalance on bodyweight*. DOI: [10.1016/S0140-6736(11)60812-X](https://doi.org/10.1016/S0140-6736(11)60812-X)
- Mifflin et al. (1990) — *A new predictive equation for resting energy expenditure in healthy individuals*. DOI: [10.1016/0002-8223(05)80008-1](https://doi.org/10.1016/0002-8223(05)80008-1)
- Müller & Bosy-Westphal (2013) — *Adaptive thermogenesis with weight loss in humans*. DOI: [10.1111/j.1467-789X.2012.01045.x](https://doi.org/10.1111/j.1467-789X.2012.01045.x)
- Frankenfield et al. (2005) — *Comparison of predictive equations for resting metabolic rate*. DOI: [10.1249/MSS.0b013e3181aff2ab](https://doi.org/10.1249/MSS.0b013e3181aff2ab)
- Hall & Chow (2011) — *Estimating changes in free-living energy intake and its confidence interval*. DOI: [10.3945/ajcn.111.014399](https://doi.org/10.3945/ajcn.111.014399)
- Westerterp (2004) — *Diet induced thermogenesis*. DOI: [10.1007/s00421-003-0988-y](https://doi.org/10.1007/s00421-003-0988-y)
