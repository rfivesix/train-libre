# Fitness-Oriented Sleep Health Score (SHS v3.5) Heuristic

> **Non-Medical Disclaimer**: This feature is a fitness-oriented, non-clinical heuristic designed for healthy individuals tracking recovery, performance, and general well-being. It is not a diagnostic tool and does not apply to clinical sleep disorders (such as insomnia, sleep apnea, or other sleep pathologies). All scoring weights, optimal targets (e.g. 90 minutes deep sleep), and threshold boundaries are sports-science-inspired abstractions and engineering design choices rather than prescriptive clinical thresholds or diagnostic criteria.

This document defines the mathematical architecture of the fitness-oriented **Sleep Health Score v3.5 (SHS v3.5)** engine. Moving away from rigid, binary hard-cap cutoffs (SHS v3), version 3.5 implements a continuous, multi-domain soft-cap multiplier system that dynamically degrades the composite sleep score based on the single worst-performing biological bottleneck.

---

## 1. Engine Overview

The Sleep Health Score (*SHS*) is constructed in two sequential phases:
1. **Weighted Base Aggregation**: A top-level normalized weighted average of 5 primary clinical domains.
2. **Dynamic Soft-Cap Penalty**: Multiplicative scaling using the single most severe biological penalty (bottleneck).

### Top-Level Weighted Aggregation

The base score *SHS_base* ∈ [0, 100] aggregates 5 dimensions according to specific fitness-oriented weight allocations. These relative weights and mathematical curves are engineering design choices tuned for sports recovery and performance tracking, using consensus guidelines and sleep quality indicators as qualitative anchors rather than prescriptive clinical thresholds:

*   **Sleep Duration (*D*)** - **30%**: Evaluates overall sleep volume against homeostatic sleep need.
*   **Sleep Continuity (*C*)** - **20%**: Assesses fragmentation, divided equally (50/50) between Sleep Efficiency (*C_SE*) and Wake After Sleep Onset (*C_WASO*).
*   **Sleep Stage Depth / Architecture (*A*)** - **25%**: Sleep architecture quality, evaluating absolute minutes of Deep (N3) and REM sleep, with Light-stage (N1+N2) percentage penalties.
*   **Circadian Timing (*T_circ*)** - **15%**: Synchronization of sleep onset/mid-point with the natural light-dark cycle.
*   **Sleep Regularity (*R*)** - **10%**: Day-to-day stability of the sleep schedule using a rolling mid-sleep standard deviation.

The base aggregation is dynamically renormalized to handle missing or incomplete data streams, ensuring the score remains reliable:

$$SHS_{base} = \left( \frac{\sum_{i \in \mathcal{A}} w_i \cdot S_i}{\sum_{i \in \mathcal{A}} w_i} \right) \cdot 100$$

Where:
*   *A* is the set of actively available dimensions.
*   *w_i* is the weight coefficient for domain *i* (e.g., *w_D* = 0.30, *w_C* = 0.20, ...).
*   *S_i* ∈ [0, 1] is the continuous normalized score of domain *i*.

### Final Score Degradation

The final Sleep Health Score (*SHS_final*) applies the continuous `dynamicMultiplier` to the base score:

$$SHS_{final} = \text{clamp}\Big( SHS_{base} \cdot \text{dynamicMultiplier}, \; 0.0, \; 100.0 \Big)$$

---

## 2. Dimension Specifications

### 2.1 Sleep Duration (*D*)
Calculated from total sleep time in hours (*h* = durationMinutes / 60). It utilizes a Gaussian distribution centered around the 7.0–9.0 hours anabolic plateau. Severe short sleep has no hard limit, letting the Gaussian decay smoothly toward zero, while extreme hypersomnia (*h* > 10.5h) results in a score of 0.0.

*   *S_D(h)* = 1.0 if *7.0 ≤ h ≤ 9.0*
*   *S_D(h)* = 0.0 if *h > 10.5*
*   For short sleep (*h < 7.0*):
    $$S_D(h) = \exp\left( -\frac{(h - 7.0)^2}{2 \cdot 1.0^2} \right)$$
*   For long sleep (*9.0 < h ≤ 10.5*):
    $$S_D(h) = \exp\left( -\frac{(h - 9.0)^2}{2 \cdot 1.0^2} \right)$$

### 2.2 Sleep Continuity (*C*)
Composed of two complementary sub-metrics, combined as *S_C* = 0.5 · *S_SE* + 0.5 · *S_WASO* (renormalized if only one sub-metric is active).

#### Sleep Efficiency (*S_SE*)
Uses a steep logistic sigmoid curve centered at a critical threshold of 90% efficiency.

$$S_{SE}(SE) = \frac{1}{1 + \exp\Big( -50.0 \cdot (SE - 0.90) \Big)}$$

Where *SE* = sleepEfficiencyPct / 100.0.

#### Wake After Sleep Onset (*S_WASO*)
Calculated using a quadratic rational penalty decay function starting after a grace period of 20 minutes.

$$S_{WASO}(W) = \frac{1}{1 + \left( \frac{W_{pen}}{30} \right)^2}$$

Where *W_pen* = max(*W* - 20.0, 0.0) and *W* is the WASO duration in minutes.

#### On-Device Fallback for Missing Metrics
If a connected smartwatch does not supply explicit Time-In-Bed or Awake-Minutes (rendering Efficiency and WASO unobservable), the engine automatically evaluates a robust fallback using sleep stage distribution and duration:

$$S_{C, fallback} = 0.9 \cdot (1.0 - \text{lightSleepPenalty}) + 0.1 \cdot \text{durationPenalty}$$

Where:
*   *lightSleepPenalty* = 1.0 - *P_light*(*p_light*) (based on the Light-stage (N1+N2) percentage penalty).
*   *durationPenalty* = *S_D*(*h*) (the Sleep Duration subscore).

This ensures commercial smartwatch summaries still generate a highly reliable continuity score.

### 2.3 Sleep Stage Depth / Architecture (*A*)
Evaluates the physiological structure of sleep stages based on absolute minutes of restorative stages, penalized by excessive light sleep.

#### Deep Sleep / N3 (*A_N3*)
A joint linear growth and Gaussian decay curve peaking at 90 minutes:

$$A_{N3}(t_{N3}) = \min\left( 1.0, \; \frac{t_{N3}}{90.0} \right) \cdot \exp\left( -\frac{(t_{N3} - 90.0)^2}{2 \cdot 40.0^2} \right)$$

#### REM Sleep (*A_REM*)
Similar joint linear-Gaussian curve optimized for a peak at 100 minutes:

$$A_{REM}(t_{REM}) = \min\left( 1.0, \; \frac{t_{REM}}{100.0} \right) \cdot \exp\left( -\frac{(t_{REM} - 100.0)^2}{2 \cdot 40.0^2} \right)$$

#### Light-stage (N1+N2) Percentage Penalty (*P_light*)
Triggers an exponential penalty decay when light sleep (which represents clinical stages N1 and N2 combined on consumer wearables) exceeds 65% of total sleep time.

*   *P_light*(*p_light*) = 1.0 if *p_light ≤ 65.0*
*   For high light sleep percentage (*p_light > 65.0*):
    $$P_{light}(p_{light}) = \exp\left( -\frac{(p_{light} - 65.0)^2}{2 \cdot 7.0^2} \right)$$

Where *p_light* is the percentage of light sleep.

#### Combined Architecture Score
$$S_A = \text{clamp}\Big( (0.45 \cdot A_{N3} + 0.45 \cdot A_{REM}) \cdot P_{light} + 0.10, \; 0.0, \; 1.0 \Big)$$

### 2.4 Circadian Timing (*T_circ*)
Assesses circadian alignment using the mid-sleep clock hour (*MS*), computed to handle midnight crossings cleanly. The base score is a Gaussian curve centered at 03:30 (*MS* = 3.5). An exponential late-phase penalty applies if mid-sleep occurs past 05:30 (*MS* > 5.5).

$$S_{circ, base}(MS) = \exp\left( -\frac{(MS - 3.5)^2}{2 \cdot 1.0^2} \right)$$

*   *S_circ*(*MS*) = *S_circ,base*(*MS*) if *MS ≤ 5.5*
*   For late phase delay (*MS > 5.5*):
    $$S_{circ}(MS) = S_{circ, base}(MS) \cdot \exp\left( -\frac{(MS - 5.5)^2}{2 \cdot 0.5^2} \right)$$

### 2.5 Sleep Regularity (*R*)
Evaluates schedule stability using the standard deviation of mid-sleep clock hours (*SD_mid*) over a 7-14 day rolling window. Uses an inverse-quadratic decay function.

$$S_R(SD_{mid}) = \frac{1}{1 + (SD_{mid} / 1.0)^2}$$

---

## 3. Smartwatch Data Mapping Spec

Scientific sleep studies (Polysomnography or PSG) differentiate between four distinct sleep stages: Wake, N1 (lightest), N2 (moderate light), and N3 (deep slow-wave sleep). However, commercial smartwatches and fitness trackers (Apple Watch, Garmin, Fitbit, Oura) compress these categories into a unified, consumer-friendly taxonomy. 

To bridge the gap between academic sports science and commercial API constraints, the Sleep Health Scoring Engine maps wearable data streams to the mathematical models as follows:

### 3.1 Parameter Translation Matrix

| Wearable Stage Category | Engine Metric Symbol | Scientific PSG Translation | Description & Mapping Formula |
| :--- | :--- | :--- | :--- |
| **Deep Sleep** | *t_N3* | Stage N3 (Slow-Wave Sleep) | Absolute minutes spent in slow-wave sleep. Fed directly into deep sleep quality score (*A_N3*) and Deep Sleep Multiplier (*M_N3*). |
| **REM Sleep** | *t_REM* | Stage REM (Rapid Eye Movement) | Absolute minutes spent in dream sleep. Fed directly into REM sleep quality score (*A_REM*) and REM Sleep Multiplier (*M_REM*). |
| **Light Sleep** | *p_light* | Stage N1 + Stage N2 | Expressed as a percentage of Total Sleep Time (TST): <br> $$p_{light} = 100 \cdot \left( \frac{\text{Vendor Light Sleep Minutes}}{\text{Total Sleep Time Minutes}} \right)$$ <br> Fed into the Light-stage Percentage Penalty (*P_light*) curve. |

### 3.2 Sports-Science Rationale for Smartwatch Mapping

1. **Light Sleep Compression (*p_light*)**: Smartwatches are highly accurate at separating overall light sleep from deep/REM, but lack the EEG resolution to reliably differentiate PSG Stage N1 from Stage N2. In healthy PSG, N1 constitutes ~5% and N2 constitutes ~50% of sleep (totaling ~55%). To account for this wearable limitation, our engine establishes an optimal threshold for Light-stage sleep at ≤ 65%. This grants a generous 10% non-clinical buffer to prevent false penalties from tracking noise while strictly penalizing highly fragmented sleep (where light sleep exceeds 65% due to stage-regression).
2. **Missing SE/WASO Continuity Fallback**: Classic sleep continuity metrics require explicit and highly accurate recognition of micro-arousals (WASO) and total sleep opportunity (Sleep Efficiency). Cheap trackers or restrictive API integrations often do not export total awake minutes or time-in-bed. When WASO/SE are missing:
   - The engine falls back to an architecture-continuity proxy (*S_C, fallback*).
   - The fallback is weighted 90% towards 1.0 - *lightSleepPenalty* and 10% towards the *S_D*(*h*) duration score.
   - This prevents double-counting sleep duration in the final score while using excessive light sleep as an accurate physiological proxy for sleep fragmentation and light sleep regression caused by nocturnal awakenings.

---

## 4. The Soft-Cap Multiplier Mechanics

To prevent high scores when a critical physiological sleep domain is dangerously compromised, SHS v3.5 implements a dynamic, continuous soft-cap multiplier. 

The engine computes 4 individual potential multiplier penalties and selects the single lowest (the bottleneck):

$$\text{dynamicMultiplier} = \min\Big( M_{REM}, \; M_{N3}, \; M_{TST}, \; M_{circ} \Big)$$

### Linear Mapping Function

Each multiplier is mapped continuously using the bounded linear interpolation helper function:

$$\_linear(v, x_{min}, x_{max}, y_{min}, y_{max}) = y_{min} + \left( \frac{\text{clamp}(v, x_{min}, x_{max}) - x_{min}}{x_{max} - x_{min}} \right) \cdot (y_{max} - y_{min})$$

Where clamp(*v*, *x_min*, *x_max*) constrains the input parameter *v* to the range defined by [*x_min*, *x_max*].

*Note: The function natively supports decreasing mappings where *x_min* > *x_max*, allowing higher input values to output lower multipliers.*

### Multiplier Threshold Formulations

#### 1. REM Sleep Multiplier (*M_REM*)

Degrades score if REM duration (*t_REM*) falls below 60 minutes:

$$M_{REM} = \_linear(t_{REM}, \; 40.0, \; 60.0, \; 0.65, \; 1.0)$$

#### 2. Deep Sleep (N3) Multiplier (*M_N3*)

Degrades score if N3 duration (*t_N3*) falls below 70 minutes:

$$M_{N3} = \_linear(t_{N3}, \; 40.0, \; 70.0, \; 0.60, \; 1.0)$$

#### 3. Total Sleep Time (TST) Multiplier (*M_TST*)

Degrades score if sleep volume (*h* hours) falls below 6.5 hours:

$$M_{TST} = \_linear(h, \; 5.0, \; 6.5, \; 0.50, \; 1.0)$$

#### 4. Circadian Timing Multiplier (*M_circ*)

Degrades score if the mid-sleep clock hour (*MS*) shifts later than 05:30 (5.5):

$$M_{circ} = \_linear(MS, \; 7.5, \; 5.5, \; 0.55, \; 1.0)$$

---

## 5. The Boundary Table

The following table summarizes the boundary conditions of the continuous soft-cap multiplier system:

| Affected Domain | Input Metric (*v*) | Optimal Zone (*M* = 1.0) | Pathological / Max Penalty Zone | Multiplier Range | Clinical biological rationale |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **REM Sleep (*M_REM*)** | REM Minutes (*t_REM*) | ≥ 60.0 min | ≤ 40.0 min | 1.0 → 0.65 | REM deficiency impairs emotional regulation, memory consolidation, and neuronal repair. |
| **Deep Sleep (*M_N3*)** | N3 Minutes (*t_N3*) | ≥ 70.0 min | ≤ 40.0 min | 1.0 → 0.60 | Deep N3 slow-wave sleep is the primary driver of physical recovery, growth hormone release, and tissue repair. |
| **Sleep Duration (*M_TST*)** | TST Hours (*h*) | ≥ 6.5 hours | ≤ 5.0 hours | 1.0 → 0.50 | Insufficient sleep duration restricts core metabolic recovery and disrupts homeostatic anabolic processes. |
| **Circadian Timing (*M_circ*)** | Mid-Sleep Clock (*MS*) | ≤ 05:30 (5.5) | ≥ 07:30 (7.5) | 1.0 → 0.55 | Late phase delay (sleep against the circadian clock) severely reduces insulin sensitivity and sleep architecture quality. |

---

## 6. Non-Clinical Heuristic Disclaimer
The Sleep Health Score (SHS) is a fitness-oriented, non-clinical directional heuristic designed for sleep recovery tracking and educational purposes. It is not a diagnostic tool and does not identify or manage clinical sleep disorders (such as insomnia, sleep apnea, or other sleep pathologies). The accuracy of the score is dependent on the data quality and sampling frequency of the underlying wearable hardware. The mathematical curves and optimal targets are modeling choices designed for athletic recovery tracking in healthy individuals rather than medical thresholds.

---

## 7. Scientific References & Sources
- Ohayon et al. (2017) — *National Sleep Foundation's sleep quality recommendations: first report*. DOI: [10.1016/j.sleh.2016.11.002](https://doi.org/10.1016/j.sleh.2016.11.002)
- Watson et al. (2015) — *Recommended Amount of Sleep for a Healthy Adult: A Joint Consensus Statement of the American Academy of Sleep Medicine and Sleep Research Society*. DOI: [10.5664/jcsm.9538](https://doi.org/10.5664/jcsm.9538)
- AASM (2020) — *Consensus Statement on Sleep Duration for Healthy Adults*. DOI: [10.3389/fneur.2020.00762](https://doi.org/10.3389/fneur.2020.00762)
- Buysse (2014) — *Sleep Health: Can We Define It? Does It Matter?*. DOI: [10.1093/sleep/zsu056](https://doi.org/10.1093/sleep/zsu056)
- Ruhr-Universität Bochum (RU-SATED) — *Multi-domain continuous sleep tracking validation*. DOI: [10.1093/sleep/zsab134](https://doi.org/10.1093/sleep/zsab134)
- SATED Index — *Quantifying Sleep Health Beyond Subjective Inventories*. DOI: [10.1016/j.physbeh.2018.11.032](https://doi.org/10.1016/j.physbeh.2018.11.032)

