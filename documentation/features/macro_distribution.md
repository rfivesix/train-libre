# Fitness-Oriented Macronutrient Distribution

> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking performance and dietary habits. It is not intended for clinical use, diagnostics, or managing medical conditions (such as eating disorders or endocrine/metabolic diseases). All per-kilogram targets, floors, and fallback thresholds are sports-science-inspired abstractions and engineering design choices rather than prescriptive clinical thresholds or direct experimental derivations.

The [**Bayesian TDEE Estimator**](bayesian_tdee_estimator.md) answers one question: how many calories per day. This document covers what happens to that number afterwards — how a single calorie target becomes a protein, carbohydrate, and fat recommendation. The two stages are deliberately separate: the calorie target is the output of a recursive statistical filter over the user's own logged history, while the distribution below is a deterministic, stateless function of that target, the user's body weight, and the active goal. No part of it observes or adapts to logging history.

All of it runs on-device, in `AdaptiveNutritionRecommendationEngine._computeMacros`.

---

## 1. Inputs and Order of Resolution

The distribution takes three inputs:

*   **Recommended calories** (*C*): the estimator's maintenance figure plus the goal's rate adjustment, clamped to a floor of 1200 kcal.
*   **Body weight** (*w*): the most recent logged weight. If it is missing or non-positive, a neutral default of 75 kg is substituted so the recommendation degrades to something plausible rather than to zero.
*   **Goal**: lose weight, maintain weight, or gain weight.

The macronutrients are resolved in a fixed order, and that order encodes the priority: **protein first, then fat, and carbohydrates take what is left.** Protein and fat are both anchored to body weight because their requirements scale with lean tissue rather than with the size of the energy budget. Carbohydrates are the remainder because they are the macronutrient with both the widest tolerable range and the largest influence on training quality — which makes them the right place to absorb the variance of the calorie target.

---

## 2. Protein Target

$$P = \text{round}(w \cdot p_{\text{goal}}) \qquad p_{\text{goal}} = \begin{cases} 2.0 \text{ g/kg} & \text{lose weight} \\ 1.8 \text{ g/kg} & \text{maintain or gain} \end{cases}$$

The higher figure during a deficit is deliberate: protein requirements rise, not fall, when energy is scarce, because protein is doing the additional job of protecting lean mass against a catabolic energy state. Both values sit at or above the intake beyond which the literature reports no further resistance-training benefit, which is the intended conservatism — overshooting protein costs the user only carbohydrate headroom.

---

## 3. Fat Target and Floor

$$F_{\text{floor}} = \text{clamp}(\text{round}(w \cdot 0.60), \; 35 \text{ g}, \; 130 \text{ g})$$

$$F = \text{clamp}(\text{round}(w \cdot f_{\text{goal}}), \; F_{\text{floor}}, \; 250 \text{ g}) \qquad f_{\text{goal}} = \begin{cases} 0.9 \text{ g/kg} & \text{lose weight} \\ 1.0 \text{ g/kg} & \text{maintain or gain} \end{cases}$$

Both figures sit inside the commonly cited ranges — roughly 0.5–1.0 g/kg on a deficit and 0.8–1.2 g/kg at or above maintenance — rather than at their lower edge. A cut is held slightly below maintenance so that the deficit is paid for by carbohydrates last and by fat first, which is the ordering that preserves training quality: performance degrades from an empty carbohydrate budget long before it degrades from fat at 0.9 g/kg.

**The 0.60 g/kg floor** is the bottom of the cutting range and functions as a hard stop rather than a target. Below it, hormonal support and the absorption of fat-soluble vitamins are no longer a given, so the distribution will empty the carbohydrate budget and then cut protein before it goes lower. The absolute clamps of 35 g and 130 g bound the floor itself at the extremes of body weight, and 250 g caps the target for very heavy users.

> **Historical note**: Before algorithm version `tdee_adaptive_recommendation_1_1_bayesian_recursive`, fat was pinned *at* this floor for every goal and every calorie budget, with all remaining calories going to carbohydrates. For an 80 kg user at maintenance this produced 48 g of fat — below the evidence-based range rather than inside it. Fat is now targeted per kilogram like protein; the floor retained its role as the lower bound of the fallback path described in section 5.

---

## 4. Carbohydrate Remainder

$$C_{\text{carbs}} = \text{round}\left(\frac{C - 4P - 9F}{4}\right)$$

Using the Atwater factors of 4 kcal/g for protein and carbohydrate and 9 kcal/g for fat. In the ordinary case this is the end of the calculation, and the three macronutrients reconstruct the calorie target to within one gram of rounding.

---

## 5. Degradation Under a Constrained Budget

When the calorie target cannot carry both anchored targets, the remainder above goes negative. The distribution then gives ground in a defined order rather than failing.

### Stage 1 — Fat gives way towards its floor

If carbohydrates would be negative and fat is still above its floor, fat is reduced to whatever the budget affords, bounded below by the floor:

$$F' = \text{clamp}\left(\left\lfloor \frac{C - 4P}{9} \right\rfloor, \; F_{\text{floor}}, \; F\right)$$

Carbohydrates are then recomputed. In most constrained cases this is sufficient and the recommendation carries no warning: a 110 kg user cutting on 1500 kcal receives 220 g protein, 68 g fat (down from a 99 g target, still above the 66 g floor) and 2 g of carbohydrate.

### Stage 2 — Carbohydrates are emptied

If the budget is still insufficient, carbohydrates are set to zero and fat takes the entire non-protein remainder. Should that fall below an absolute minimum of 25 g, fat is held at 25 g and **protein** is reduced to fit the remaining calories. This is the only path on which protein is not honoured.

Any recommendation reaching stage 2 carries the warning reason `macro_distribution_constrained`, which surfaces in the recommendation card. It indicates that the calorie target is too low to support the user's body weight at any sensible distribution — typically a very heavy user against the 1200 kcal calorie floor — and that the target itself, not the distribution, is what deserves attention.

All three values are finally clamped to 0–999 g.

---

## 6. Worked Examples

Produced by the engine itself, not by hand:

| Scenario | Calories | Protein | Carbs | Fat | Warning |
|---|---|---|---|---|---|
| 80 kg, cutting at −0.5 kg/week | 2050 kcal | 160 g | 191 g | 72 g | — |
| 80 kg, maintaining | 2600 kcal | 144 g | 326 g | 80 g | — |
| 80 kg, bulking at +0.25 kg/week | 2875 kcal | 144 g | 395 g | 80 g | — |
| 60 kg, cutting at −0.5 kg/week | 1450 kcal | 120 g | 121 g | 54 g | — |
| 110 kg, cutting on a tight budget | 1500 kcal | 220 g | 2 g | 68 g | fat gave way (stage 1) |
| 160 kg, at the calorie floor | 1200 kcal | 243 g | 0 g | 25 g | `macro_distribution_constrained` |

---

## 7. Versioning and Invalidation

The distribution is covered by the same `algorithmVersion` constant as the calorie model (`AdaptiveNutritionRecommendationService.algorithmVersion`). A stored recommendation whose version does not match the current one is treated as stale by `AdaptiveRecommendationSnapshot.isFreshFor` and recomputed at the next due check, so a change to the macro model reaches existing users instead of leaving old and new distributions side by side in the history.

Any change to the per-kilogram targets, the floor, or the degradation order must bump that constant.

---

## 8. Non-Clinical Heuristic Disclaimer

The macronutrient distribution is a sports-science-inspired, non-clinical fitness heuristic. The per-kilogram targets are engineering choices made inside ranges reported for healthy, resistance-training populations; they are not individualised prescriptions and do not account for pregnancy, growth, clinical conditions, medication, or any dietary pattern with its own constraints. Users should consult a qualified healthcare professional before making changes to their intake.

---

## 9. Scientific References & Sources

*Consulted for the ranges the engineering values sit inside, not as direct derivations of them.*

- Helms et al. (2014) — *Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation*. DOI: [10.1186/1550-2783-11-20](https://doi.org/10.1186/1550-2783-11-20)
- Morton et al. (2018) — *A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains in muscle mass and strength in healthy adults*. DOI: [10.1136/bjsports-2017-097608](https://doi.org/10.1136/bjsports-2017-097608)
- Iraki et al. (2019) — *Nutrition recommendations for bodybuilders in the off-season: a narrative review*. DOI: [10.3390/sports7070154](https://doi.org/10.3390/sports7070154)
- Slater & Phillips (2011) — *Nutrition guidelines for strength sports: sprinting, weightlifting, throwing events, and bodybuilding*. DOI: [10.1080/02640414.2011.574722](https://doi.org/10.1080/02640414.2011.574722)
- Burke et al. (2011) — *Carbohydrates for training and competition*. DOI: [10.1080/02640414.2011.585473](https://doi.org/10.1080/02640414.2011.585473)
