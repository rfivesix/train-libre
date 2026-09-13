# Fitness-Oriented Estimated 1-Rep Max (1RM) Heuristic

> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking strength performance and training progress. It does not constitute medical, diagnostic, or clinical assessment of physical capacity. All strength estimates, predicted maximums, and record progression metrics are sports-science-inspired abstractions and design choices rather than prescriptive clinical thresholds or absolute measures of structural capacity.

The **Estimated 1-Rep Max (1RM)** model in Train Libre is a submaximal strength estimation heuristic based on the Brzycki equation. It allows users to track their strength capacities and progression over time in a safe manner, avoiding the musculoskeletal stress, joint strain, and safety risks associated with testing true physical failure at absolute maximum loads.

---

## 1. The Brzycki Equation

To estimate 1-rep maximum lift capacity from submaximal training sets, Train Libre evaluates the Brzycki formula:

$$1\text{RM} \approx w_{\text{eff}} \cdot \frac{36}{37 - r}$$

Where:
- $w_{\text{eff}}$ is the **effective load placed on the muscle** in kilograms (derived via `effectiveSetLoadKg`).
- $r$ is the number of completed repetitions.

---

## 2. Effective Set Load Resolution (`effectiveSetLoadKg`)

The nominal weight recorded in the UI cannot always be plugged directly into a strength formula. Train Libre dynamically resolves the true load based on the exercise's tracking type and load mode:

### Standard Loaded Exercises
For free weights, barbells, dumbbells, and cable stacks where the logged number represents the external load:
$$w_{\text{eff}} = w_{\text{logged}} \quad (\text{if } w_{\text{logged}} > 0)$$

### Assisted Resistance Exercises (e.g., Assisted Pull-Up / Dip)
On assistance machines, the logged number represents the counterweight reducing the user's effort. The actual load lifted by the user is the remaining body mass:
$$w_{\text{eff}} = w_{\text{body}} - w_{\text{logged}}$$

*   **Integrity Gate**: If the user has never recorded a body weight measurement, $w_{\text{eff}}$ returns `null`. The heuristic strictly refuses to use $w_{\text{logged}}$ directly as the load, because doing so would invert the progression curve (a user needing less assistance as they grow stronger would appear to be lifting less weight).

### Bodyweight & Weighted Bodyweight Exercises (e.g., Pull-Ups, Dips, Push-Ups)
When moving one's own body, the load combines body mass and any additional ballast:
$$w_{\text{eff}} = w_{\text{body}} + w_{\text{added}}$$

*   **Missing Measurement Fallback**: If no bodyweight reading exists, only the entered ballast ($w_{\text{added}} > 0$) is counted, rather than silently guessing a generic default.

---

## 3. Historical Bodyweight Dating (`BodyweightHistory`)

To ensure progression statistics remain accurate over long training cycles, **historical sets are evaluated at the user's recorded body weight on the day the set was performed, not today's weight**:

*   **Progression Decoupling**: If a user loses 10 kg during a cutting phase, their past pull-ups did not retroactively become easier. Recomputing historical sessions at today's weight would artificially deflate past tonnage and 1RM records.
*   **Search Mechanism**: `BodyweightHistory.at(date)` performs a binary search over chronological weight measurements to identify the most recent reading at or before the workout date.
*   **No Backward Extrapolation**: If a set was performed before the user's first recorded weight measurement, the system does not extrapolate backwards. It treats bodyweight as unknown to avoid invisible, speculative adjustments to older data.

---

## 4. Repetition Range Constraints

The mathematical linearity of muscle fatigue and rep-to-failure ratios breaks down at higher repetitions due to cardiovascular demands, localized muscular endurance, and shifts in motor unit recruitment.

Train Libre enforces a strict validity boundary:
*   **Calculation Window**: $1 \leq r \leq 12$.
*   **Behavior**: If a set exceeds 12 repetitions ($r > 12$), or if $r \leq 0$ or $w_{\text{eff}} \leq 0$, the estimated 1RM calculation returns `null`. This keeps personal records and progression suggestions grounded in the load-dominant resistance training domain.

---

## 5. Safe Progression Tracking & Non-Clinical Scope

Testing true 1-Rep Maxes requires maximal physical exertion, which poses elevated risks of connective tissue injury and systemic fatigue. Submaximal estimation offers a safe alternative:
*   **Injury Mitigation**: Enables training in safe, submaximal load ranges (e.g., 70%–85% of 1RM) while maintaining visibility into strength progression.
*   **Fatigue Management**: Avoids central nervous system (CNS) exhaustion from frequent true-max testing.
*   **Non-Clinical Heuristic**: This model is a performance tracking tool and does not account for acute factors such as sleep deprivation, dehydration, or joint soreness. It should be interpreted as an indicative trend rather than an absolute measure of physical capacity.

---

## 6. Scientific References & Sources
- Brzycki, M. (1993). *Strength Testing—Predicting a One-Rep Max from Reps-to-Fatigue*. Journal of Physical Education, Recreation & Dance, 64(1), 88–90.
- Wood, T. M., Maddalozzo, G. F., & Harter, R. A. (2002). *Accuracy of Seven Equations for Predicting 1-RM Performance of Apparently Healthy, Sedentary Older Adults*. Measurement in Physical Education and Exercise Science, 6(2), 67-94. DOI: [10.1207/S15327841MPEE0602_1](https://doi.org/10.1207/S15327841MPEE0602_1)
