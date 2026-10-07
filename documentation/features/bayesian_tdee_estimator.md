# Fitness-Oriented Bayesian TDEE Estimator & Adaptive Calorie Controller

> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic for healthy individuals tracking performance and dietary habits. It is not intended for diagnosis, treatment, eating-disorder management, or endocrine and metabolic conditions. Users should consult a qualified healthcare professional before making medically significant dietary changes.

Train Libre separates two related jobs:

1. A one-dimensional recursive Kalman filter estimates latent Total Daily Energy Expenditure (TDEE).
2. A bounded trajectory controller may temporarily adjust the calorie target when measured bodyweight change persistently differs from the selected goal rate.

The controller never changes the displayed maintenance estimate or its uncertainty range. All calculations run locally on the device.

---

## 1. Input Window and Weight Trend

Weekly recommendations use the latest **14 days** of available intake and bodyweight logs. Daily weights are smoothed with an exponentially weighted moving average:

$$S_d = 0.35W_d + 0.65S_{d-1}$$

A linear regression over the smoothed series produces the weekly bodyweight slope. Logged calories are averaged over logged intake days in the same window. Sparse logs remain usable, but receive larger observation variance and may suppress trajectory correction.

Because weekly evaluations use overlapping 14-day windows, adjacent observations are correlated. The estimator therefore uses conservative uncertainty, bounded gain, and target-adjustment limits rather than treating each result as an independent laboratory measurement.

---

## 2. Maintenance Observation Model

For week $t$, observed maintenance is:

$$M_t = \text{avgLoggedCalories}_t - \left(\text{smoothedWeightSlopeKgPerWeek}_t \cdot \frac{7700}{7}\right)$$

The conversion coefficient is fixed at **7,700 kcal/kg**. This is a population-level engineering approximation, not a claim that every kilogram of short-term scale change represents identical tissue composition.

Earlier versions changed this coefficient from 3,000 to 7,700 during the first nine phase weeks. That approach biased the observation itself. The current model keeps the observation equation stable and represents early water-weight uncertainty through observation variance instead.

---

## 3. Observation Variance

The reference variance combines independent heuristic uncertainty sources:

$$V_{\text{ref}} = V_{\text{base}} + V_{\text{intake}} + V_{\text{slope}}$$

$$V_{\text{base}} = 120^2$$

$$V_{\text{intake}} = \left(\frac{320}{\sqrt{\text{intakeLoggedDays}}}\right)^2$$

$$V_{\text{slope}} = \left(\frac{0.55 \cdot \frac{7700}{7}}{\sqrt{\max(\text{weightLogCount}-1,1)}}\right)^2$$

With complete daily logging, the unpenalized reference variance is approximately:

| Window | Approximate variance | Standard deviation |
|---:|---:|---:|
| 7 days | 90,000 kcal²/day² | 300 kcal/day |
| 14 days | 50,000 kcal²/day² | 224 kcal/day |
| 21 days | 38,000 kcal²/day² | 194 kcal/day |

Completeness and quality penalties remain multiplicative:

$$M_{\text{comp}} = \frac{1}{\sqrt{\text{intakeCompleteness}\cdot\text{weightCompleteness}}}$$

$$R_t = V_{\text{ref}}\cdot M_{\text{phase}}\cdot M_{\text{comp}}^2\cdot M_{\text{qual}}^2$$

Phase-transition uncertainty is:

| Confirmed phase age | $M_{\text{phase}}$ |
|---|---:|
| Days 1–7 | 2.25 |
| Days 8–14 | 1.50 |
| Day 15+ | 1.00 |

This lowers trust in early phase observations without changing their direction or implied maintenance value.

---

## 4. Recursive Kalman Filter

The latent state $X_t$ is maintenance calories in kcal/day. The default weekly process standard deviation is 60 kcal/day, so:

$$Q = 60^2 = 3600$$

Prediction:

$$X_{t|t-1}=X_{t-1}$$

$$P_{t|t-1}=\min(P_{t-1}+Q\Delta t,V_{\text{cap}})$$

Correction:

$$K_t=\frac{P_{t|t-1}}{P_{t|t-1}+R_t}$$

$$X_t=X_{t|t-1}+K_t(M_t-X_{t|t-1})$$

$$P_t=(1-K_t)P_{t|t-1}$$

For typical dense-data observation variance, the steady-state gain is approximately 0.24–0.28. This allows meaningful adaptation while keeping isolated water-weight changes from directly controlling the estimate. Maintenance remains clamped between 1,200 and 5,000 kcal/day.

---

## 5. History-Based Noise Calibration

Train Libre retains up to eight weekly posterior, residual, and implied-maintenance values. Residual variance can scale $R$, while posterior movement can scale $Q$, within conservative bounds.

This calibration models changing signal quality. It is not driven by target-rate error: being behind a goal does not itself prove that latent TDEE became more volatile.

After an algorithm upgrade that changes the observation equation, the current posterior and covariance are retained, but old calibration histories are cleared so incompatible residual regimes are not mixed.

---

## 6. Bounded Trajectory Controller

The calorie target begins with the posterior maintenance estimate plus the selected goal-rate adjustment:

$$C_{\text{base}} = X_t + \text{targetRate}\cdot\frac{7700}{7}$$

When two consecutive eligible observations show rate error beyond the deadband and in the same direction, the controller calculates:

$$e_t=\text{targetRate}-\text{observedRate}$$

$$C_{\text{trajectory}}=\operatorname{clip}\left(0.65\cdot1100\cdot e_t,-150,150\right)$$

The correction may change by at most 100 kcal/day between weekly recommendations. The final target is:

$$C_t=C_{\text{base}}+C_{\text{trajectory}}$$

The controller is disabled when:

- the rate error is within ±0.05 kg/week;
- fewer than 14 usable days, 10 intake days, or 7 weights are present;
- food calories are unresolved;
- a phase change is pending or the confirmed phase is younger than 15 days;
- the goal or target rate changed;
- no compatible prior recommendation exists.

Onboarding and profile-prior-only recommendations always use zero trajectory correction.

---

## 7. Persistence and Existing Users

Recommendations are versioned. When the algorithm version changes, an existing user receives one deterministic recalculation, including during the same due week. The estimator replays the stored pre-update prior so the same observation is not applied twice.

Generated recommendations never overwrite active calorie and macro goals by themselves. Existing active targets remain unchanged until the user explicitly applies the new recommendation, except in workflows where the user has already chosen a recalculate-and-apply action.

Legacy recommendation JSON remains readable. Missing controller fields decode as an inactive zero-calorie correction.

---

## 8. Confidence and Safety Interpretation

Confidence labels describe the strength of the recent data basis, not a clinical probability. Sparse observations increase variance and can prevent controller activation. The interface keeps estimated maintenance, its likely range, and the final recommended target visually distinct.

The estimator cannot distinguish all causes of weight change. Sodium, glycogen, hydration, creatine, gastrointestinal contents, menstrual-cycle effects, logging bias, and tissue composition can all affect short-term inference.

---

## 9. Scientific References & Sources

- Hall, K. D. (2008) — *The dynamics of human body weight change*. DOI: [10.1371/journal.pcbi.1000045](https://doi.org/10.1371/journal.pcbi.1000045)
- Hall et al. (2011) — *Quantification of the effect of energy imbalance on bodyweight*. DOI: [10.1016/S0140-6736(11)60812-X](https://doi.org/10.1016/S0140-6736(11)60812-X)
- Mifflin et al. (1990) — *A new predictive equation for resting energy expenditure in healthy individuals*. DOI: [10.1016/0002-8223(05)80008-1](https://doi.org/10.1016/0002-8223(05)80008-1)
- Müller & Bosy-Westphal (2013) — *Adaptive thermogenesis with weight loss in humans*. DOI: [10.1111/j.1467-789X.2012.01045.x](https://doi.org/10.1111/j.1467-789X.2012.01045.x)
- Frankenfield et al. (2005) — *Comparison of predictive equations for resting metabolic rate*. DOI: [10.1249/MSS.0b013e3181aff2ab](https://doi.org/10.1249/MSS.0b013e3181aff2ab)
- Hall & Chow (2011) — *Estimating changes in free-living energy intake and its confidence interval*. DOI: [10.3945/ajcn.111.014399](https://doi.org/10.3945/ajcn.111.014399)
- Westerterp (2004) — *Diet induced thermogenesis*. DOI: [10.1007/s00421-003-0988-y](https://doi.org/10.1007/s00421-003-0988-y)
