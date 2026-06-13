# Clinical Muscle Recovery & Fatigue Modeling Heuristic

The **Muscle Recovery Model** in Train Libre is a piecewise linear decay heuristic designed to estimate readiness scores *R*(*t*) for individual muscle groups. It accounts for non-linear recovery curves, set-weighting based on primary vs. secondary involvement, and failure-induced baseline extensions.

---

## 1. Readiness Score Equation *R*(*t*)

The readiness of a muscle group at time *t* (hours since last load) is calculated using a 3-phase piecewise interpolation mapping, ensuring a non-linear recovery curve that accounts for acute fatigue, adaptation, and supercompensation.

### Phase 1: Acute Recovery ($t \leq T_{rec}$)
During the initial recovery window, readiness scales from 10% to 60%:
$$R(t) = 10.0 + (60.0 - 10.0) \cdot \frac{t}{T_{rec}}$$

### Phase 2: Adaptation Window ($T_{rec} < t \leq T_{ready}$)
As the muscle enters the adaptation phase, readiness scales from 60% to 85%:
$$R(t) = 60.0 + (85.0 - 60.0) \cdot \frac{t - T_{rec}}{T_{ready} - T_{rec}}$$

### Phase 3: Supercompensation ($t > T_{ready}$)
Beyond the primary recovery window, the muscle enters supercompensation, scaling from 85% toward 100% over a 48-hour rolling window:
$$R(t) = \text{clamp}\left( 85.0 + (100.0 - 85.0) \cdot \frac{t - T_{ready}}{48.0}, \; 85.0, \; 100.0 \right)$$

### Dynamic Recovery Windows
The time thresholds ($T_{rec}$ and $T_{ready}$) are determined by muscle-specific baselines modified by volume and intensity extensions.

- **Muscle Baselines**: Standard groups (e.g., Chest) default to $T_{rec}=48h$ and $T_{ready}=72h$, while smaller groups (e.g., Biceps) use shorter windows (36h/60h), and large posterior chain groups (e.g., Quads/Lower Back) use extended windows (up to 72h/120h).
- **Volume Extensions**: Training volume beyond metabolic clearing thresholds expands the windows:
    - 3–5 sets: +6 hours
    - 5–8 sets: +12 hours
    - 8–11 sets: +24 hours
    - 11+ sets: +36 hours
- **Intensity Extensions**: High-intensity efforts (Session $avgRIR \leq 0.5$ or $avgRPE \geq 8.5$) add a flat +24 hour penalty to both $T_{rec}$ and $T_{ready}$.

---

## 2. Equivalent Set Weighting

To accurately map compound movements to multiple muscle groups, Train Libre uses a weighted contribution ratio:

- **Primary Muscle**: 1.0 equivalent set. (e.g., Chest in a Bench Press).
- **Secondary Muscle**: 0.3 - 0.5 equivalent set. (e.g., Triceps in a Bench Press).

$$V_{total} = \sum (\text{Sets} \cdot \text{Weighting} \cdot \text{IntensityFactor})$$

---

## 3. Failure-Induced Fatigue Extensions

The proximity to failure (Reps-In-Reserve, *RIR*) is the strongest predictor of central and peripheral fatigue duration. Train Libre applies a discrete penalty to the recovery timeline:

| RIR Value | Timeline Adjustment |
| :--- | :--- |
| *RIR* ≥ 3 | 0 hours (Baseline) |
| *RIR* = 2 | +6 hours |
| *RIR* = 1 | +12 hours |
| *RIR* = 0 (Failure) | +24 hours |

This ensures that "training to failure" is mathematically represented as a significant physiological stressor requiring extended downtime.

---

## 4. Heuristic Categories

Readiness is categorized into three discrete states for user presentation:

1.  **Recovering** (*R* < 0.6): High residual fatigue. Performance is likely compromised.
2.  **Ready** (0.6 ≤ *R* < 0.9): Muscle is functional but may have slight remaining soreness or substrate depletion.
3.  **Fresh** (*R* ≥ 0.9): Optimal readiness for high-intensity loading.

---

## 5. Clinical Disclaimer
This model is a directional heuristic based on established sports science literature (NSCA, AASM) regarding muscle protein synthesis and nervous system recovery windows. It does not account for individual genetic variance, nutrition quality, or systemic stressors.
