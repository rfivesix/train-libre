# Fitness-Oriented Macronutrient Distribution

> Fitness, nutrition, recovery, sleep, and pulse features are non-clinical heuristics for healthy individuals tracking performance, not medical advice. They do not apply to medical conditions, including eating or sleep disorders.

The adaptive nutrition flow estimates maintenance calories and then builds a calorie target from maintenance, the selected goal rate, and a bounded trajectory correction. This page describes the separate, deterministic step that allocates that calorie target to protein, fat, and carbohydrates. The macro allocator does not use intake history to adapt its per-kilogram targets.

## Inputs and weight resolution

The allocator receives a positive body weight, a calorie target, and one of three goals: lose, maintain, or gain weight. The recommendation input adapter uses the latest weight in its 14-day input window. If that window contains no weight, it uses the latest weight before the window ends, then the active goal's baseline weight. If none is available, or the resolved weight is non-positive, generation fails; the allocator does not substitute a 75 kg default.

The calorie target is the estimated maintenance calories plus the selected weekly-rate adjustment and any trajectory correction, with a 1,200 kcal minimum. The calorie floor can add a warning. The maintenance estimate and trajectory correction come from the separate estimation/control stages; they are not calculated by the macro allocator.

## Protein target

The engine sets protein to the rounded body weight multiplied by a goal-specific factor:

| Goal | Factor |
|---|---:|
| Lose weight | 2.0 g/kg |
| Maintain or gain weight | 1.8 g/kg |

These are fixed software parameters. The code does not personalize the factors from body composition, training history, or dietary preferences, and the values should not be read as individual prescriptions.

## Fat target and floor

The engine first calculates a floor as `round(weight × 0.60)`, clamped to 35–130 g. Its initial fat target is `round(weight × factor)`, clamped between that floor and 250 g:

| Goal | Initial fat factor |
|---|---:|
| Lose weight | 0.9 g/kg |
| Maintain or gain weight | 1.0 g/kg |

The 0.60 g/kg value and the 35 g, 130 g, and 250 g bounds are implementation constants. They describe allocator behavior; the code does not establish that these are safe or sufficient for an individual.

## Carbohydrates and constrained budgets

The allocator calculates carbohydrates as the rounded remaining calories after protein and fat, using 4 kcal/g for protein and carbohydrate and 9 kcal/g for fat:

`carbohydrates = round((calorie target − 4 × protein − 9 × fat) / 4)`

If this result is negative while fat is above its floor, the engine first reduces fat to the amount the remaining budget affords, bounded by the floor and the initial fat target, then recalculates carbohydrates. If the result remains negative, the engine sets carbohydrates to zero and assigns the remaining calories to fat. If that fat amount is under 25 g, it sets fat to 25 g and lowers protein as needed to fit the remaining calories. This 25 g value is a fallback in the algorithm, not nutrition guidance.

The second path adds the warning reason `macro_distribution_constrained`. Each macro output is finally clamped to 0–999 g. Other warning reasons may also be added by the calorie-estimation stage, such as when its calorie floor is applied.

## Versioning and application

The macro allocator is part of the recommendation algorithm identified by `AdaptiveNutritionRecommendationService.algorithmVersion`. The service compares a stored snapshot's version with the current version and regenerates when they differ. It does not check freshness through an `isFreshFor` method. Algorithm updates retain the recursive maintenance estimate and reset observation-calibration histories; the macro outputs are generated again under the new version.

Generation saves a recommendation snapshot. It does not change active nutrition targets automatically: applying the recommendation is a separate explicit action that writes its calorie and macro values to the user's active targets.

The displayed values are software-generated estimates. Users can edit their active goals, and the app does not account for medical conditions or provide clinical dietary advice.
