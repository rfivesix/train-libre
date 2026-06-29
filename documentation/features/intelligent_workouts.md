# Fitness-Oriented Estimated 1-Rep Max (1RM) Heuristic

> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking strength performance and training progress. It does not constitute medical, diagnostic, or clinical assessment of physical capacity. All strength estimates, predicted maximums, and record progression metrics are sports-science-inspired abstractions and design choices rather than prescriptive clinical thresholds or absolute measures of structural capacity.

The **Estimated 1-Rep Max (1RM)** model in Train Libre is a submaximal strength estimation heuristic based on the Epley equation. It allows users to track their strength capacities and progression over time in a safe manner, avoiding the musculoskeletal stress, joint strain, and safety risks associated with testing true physical failure at absolute maximum loads.

---

## 1. The Epley Equation

To estimate 1-rep maximum lift capacity from submaximal training sets, Train Libre evaluates the Epley formula:

$$1\text{RM} \approx w \cdot \left(1 + \frac{r}{30}\right)$$

Which simplifies computationally to:

$$1\text{RM} \approx w \cdot \frac{36}{37 - r}$$

Where:
- $w$ is the submaximal weight lifted (e.g. in kilograms or pounds).
- $r$ is the number of repetitions completed in the set.

---

## 2. Repetition Range Constraints

The mathematical linearity of muscle fatigue and rep-to-failure ratios begins to break down as repetition counts increase due to shifts in muscular endurance, cardiovascular limits, and fiber recruitment patterns. 

To maintain validity and prevent skewed progression tracking, Train Libre enforces a strict repetition boundary:
- **Calculation Window**: $1 \leq r \leq 10$.
- **Behavior**: If a set exceeds 10 repetitions, the estimated 1-Rep Max calculation is disabled for that set. This restriction ensures the Epley linear approximation remains highly correlated with true maximum capacity.

---

## 3. Safe Progression Tracking

Testing true 1-Rep Maxes requires absolute physical exertion, which poses high risks of acute injury, connective tissue strain, and neuromuscular fatigue. Submaximal estimation offers a safe alternative:
- **Injury Mitigation**: Allows training in safer load ranges (e.g., 70%–85% of 1RM) while still mapping strength increases.
- **Fatigue Management**: Prevents systemic CNS exhaustion, keeping training volume more consistent over weekly cycles.

---

## 4. Non-Clinical Heuristic Disclaimer
This model is a performance-oriented heuristic grounded in resistance training literature. It does not account for daily fluctuation factors such as sleep quality, hydration, nutritional state, or joint health. It should be used as a directional trend indicator rather than an absolute rule of physical capacity.

---

## 5. Scientific References & Sources
- Epley, B. (1985). *Poundage Chart*. Boyd Epley Workout. URL: [Wikipedia (Epley Formula)](https://en.wikipedia.org/wiki/One-repetition_maximum#Epley_formula)
- Wood, T. M., Maddalozzo, G. F., & Harter, R. A. (2002). *Accuracy of Seven Equations for Predicting 1-RM Performance of Apparently Healthy, Sedentary Older Adults*. Measurement in Physical Education and Exercise Science, 6(2), 67-94. DOI: [10.1207/S15327841MPEE0602_1](https://doi.org/10.1207/S15327841MPEE0602_1)
