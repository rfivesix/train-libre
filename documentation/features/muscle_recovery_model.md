# Fitness-Oriented Muscle Recovery & Fatigue Heuristic

> [!IMPORTANT]
> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking performance and workout recovery. It does not apply to clinical conditions, injury diagnosis, or medical rehabilitation. All recovery timelines, baseline windows (e.g. 24–120 hours), set extensions, and readiness categories are sports-science-inspired abstractions and engineering design choices rather than prescriptive clinical thresholds or direct experimental derivations.

The **Muscle Recovery Model** in Train Libre is a fitness-oriented, non-clinical piecewise linear decay heuristic designed to estimate readiness scores *R*(*t*) for individual muscle groups. It accounts for non-linear recovery curves, set-weighting based on primary vs. secondary involvement, and sports-science-inspired baseline extensions.

---

## 1. Readiness Score Equation *R*(*t*)

The readiness of a muscle group at time *t* (hours since last load) is calculated using a 3-phase piecewise interpolation mapping, ensuring a non-linear recovery curve that accounts for acute fatigue, adaptation, and supercompensation.

### Phase 1: Acute Recovery (\(t \leq T_{rec}\))
During the initial recovery window, readiness scales from 10% to 60%:
$$R(t) = 10.0 + (60.0 - 10.0) \cdot \frac{t}{T_{rec}}$$

### Phase 2: Adaptation Window (\(T_{rec} < t \leq T_{ready}\))
As the muscle enters the adaptation phase, readiness scales from 60% to 85%:
$$R(t) = 60.0 + (85.0 - 60.0) \cdot \frac{t - T_{rec}}{T_{ready} - T_{rec}}$$

### Phase 3: Supercompensation (\(t > T_{ready}\))
Beyond the primary recovery window, the muscle enters supercompensation, scaling from 85% toward 100% over a 48-hour rolling window:
$$R(t) = \text{clamp}\left( 85.0 + (100.0 - 85.0) \cdot \frac{t - T_{ready}}{48.0}, \; 85.0, \; 100.0 \right)$$

### Dynamic Recovery Windows
The time thresholds (\(T_{rec}\) and \(T_{ready}\)) are sports-science-inspired heuristic approximations representing dynamic recovery kinetics. These values and extensions are engineering design choices calibrated against typical literature ranges rather than prescriptive clinical thresholds or direct experimental derivations:

- **Muscle Baselines**: Standard groups (e.g., Chest) default to \(T_{rec}=48h\) and \(T_{ready}=72h\), while smaller groups (e.g., Biceps) use shorter windows (36h/60h), and large posterior chain groups (e.g., Quads/Lower Back) use extended windows (up to 72h/120h). These are designed to align with typical training frequencies.
- **Volume Extensions**: Training volume beyond baseline thresholds expands the recovery windows (representing the increased fatigue accumulation observed with higher training volumes):
    - 3–5 sets: +6 hours
    - 5–8 sets: +12 hours
    - 8–11 sets: +24 hours
    - 11+ sets: +36 hours
- **Intensity Extensions**: High-intensity efforts (Session \(avgRIR \leq 0.5\) or \(avgRPE \geq 8.5\)) add a flat +24 hour penalty to both \(T_{rec}\) and \(T_{ready}\), serving as a heuristic representation of failure-induced neuromuscular fatigue.

---

## 2. Equivalent Set Weighting

To accurately map compound movements to multiple muscle groups, Train Libre uses a weighted contribution ratio:

- **Primary Muscle**: 1.0 equivalent set. (e.g., Chest in a Bench Press).
- **Secondary Muscle**: 0.3 - 0.5 equivalent set. (e.g., Triceps in a Bench Press).

$$V_{total} = \sum (\text{Sets} \cdot \text{Weighting} \cdot \text{IntensityFactor})$$

---

## 3. Failure-Induced Fatigue Extensions

The proximity to failure (Reps-In-Reserve, *RIR*) is a strong indicator of exercise-induced fatigue duration. Train Libre applies a discrete penalty to the recovery timeline:

| RIR Value | Timeline Adjustment |
| :--- | :--- |
| *RIR* ≥ 3 | 0 hours (Baseline) |
| *RIR* = 2 | +6 hours |
| *RIR* = 1 | +12 hours |
| *RIR* = 0 (Failure) | +24 hours |

This ensures that "training to failure" is mathematically represented as a significant exercise stressor requiring extended rest, which is an ordinal design choice rather than a direct replication of any single experimental protocol.

---

## 4. Heuristic Categories

Readiness is categorized into three discrete states for user presentation. These are simple interpretative feedback labels for the continuous heuristic score and do not represent medical diagnoses, clinical assessments, or injury risk predictions:

1.  **Recovering** (*R* < 0.6): High residual fatigue. Performance is likely compromised.
2.  **Ready** (0.6 ≤ *R* < 0.9): Muscle is functional but may have slight remaining soreness or substrate depletion.
3.  **Fresh** (*R* ≥ 0.9): Optimal readiness for high-intensity training.

---

## 5. Non-Clinical Heuristic Disclaimer
This model is a fitness-oriented, non-clinical heuristic based on established sports science literature (NSCA, ACSM, Damas) regarding muscle protein synthesis and post-exercise recovery windows. It is designed for healthy training populations and does not account for individual genetic variance, clinical pathology, nutrition quality, or systemic medical conditions.

---

## 6. Scientific References & Sources
- Morán-Navarro et al. (2017) — *Time course of recovery following resistance training leading or not to failure*. DOI: [10.1007/s00421-017-3704-9](https://doi.org/10.1007/s00421-017-3704-9)
- Schoenfeld et al. (2017) — *Dose-response relationship between weekly resistance training volume and increases in muscle mass*. DOI: [10.1080/02640414.2016.1243800](https://doi.org/10.1080/02640414.2016.1243800)
- Sánchez-Medina & González-Badillo (2011) — *Velocity loss as an indicator of neuromuscular fatigue*. DOI: [10.1249/MSS.0b013e318213f880](https://doi.org/10.1249/MSS.0b013e318213f880)
- Ratamess et al. (2009) — *NSCA Position Stand: Progression Models in Resistance Training*. DOI: [10.1519/JSC.0b013e3181e382ec](https://doi.org/10.1519/JSC.0b013e3181e382ec)
- Vieira et al. (2016) — *Effects of resistance training to failure on recovery kinetics*. DOI: [10.1007/s40279-016-0543-8](https://doi.org/10.1007/s40279-016-0543-8)
- Watson et al. (2015) — *AASM Recommended Amount of Sleep for a Healthy Adult*. DOI: [10.5664/jcsm.9538](https://doi.org/10.5664/jcsm.9538)
- Damas et al. (2019) — *Resistance training‐induced changes in integrated myofibrillar protein synthesis*. DOI: [10.1249/MSS.0000000000002473](https://doi.org/10.1249/MSS.0000000000002473)
