# Fitness-Oriented Double Progression & Set-Structure Heuristic

> **Non-Medical and Non-Coaching Disclaimer**: This feature is a fitness-oriented decision aid for healthy adults performing resistance training. It is not an injury-screening tool, a rehabilitation protocol, or an individualized training plan. Its repetition ranges, history window, load steps, and safety rules are deliberate product heuristics informed by resistance-training literature; they are not clinical thresholds or a validated prediction of adaptation for a specific person.

Train Libre's workout progression model turns a recent, logged resistance-training session into a **suggested load and repetition target for each working-set position** in the next session. It uses double progression: performance first advances within a prescribed repetition range; only after the range has been completed across the relevant work does external load advance.

The model is intentionally conservative. It preserves a user's existing set structure, does not infer a load reduction from one weak session, and keeps the user in control of any generated value.

---

## 1. Purpose, Scope, and Output

For a resistance exercise, the model answers two narrow questions:

1. What load should be attempted for this particular working set today?
2. What repetition target is the most appropriate next step at that load?

It returns a **suggestion**, not a command. An authored routine load takes precedence, and editing either generated value means the user has chosen a different prescription.

The model is designed to preserve common structures such as:

- a heavy first working set followed by lighter back-off sets;
- ascending work sets;
- the same load across several work sets;
- an extra working set added during an ongoing workout.

It does **not** estimate 1RM, diagnose fatigue, prescribe weekly volume, decide exercise order, or determine whether a person should train through pain, illness, or injury.

---

## 2. The Training Units That Matter

### 2.1 Set roles

The system separates three independent set lanes:

| Set role | Primary purpose | Counts as a working set for progression? | Position sequence |
|---|---|---:|---|
| Warm-up | Preparation and load acclimation | No | Warm-up lane |
| Normal work set | Planned productive training | Yes | Working lane |
| Failure set | Working set terminated at momentary technical failure | Yes | Working lane |
| Drop set | Additional fatigue/volume after a work set | No | Drop-set lane |

Normal and failure sets share one **working-set sequence**. A warm-up added, removed, or reordered therefore cannot turn the historical second work set into today's third work set. Likewise, a drop set cannot become evidence for a heavier normal set.

This separation matters physiologically and practically: warm-up loads are not intended to measure the target work stimulus, while drop sets are a deliberately altered loading strategy. Neither is a clean reference for the main prescription.

### 2.2 Set position rather than exercise maximum

Let the ordered working sets of a completed session be

$$W_t = \{(w_{t,1}, r_{t,1}), (w_{t,2}, r_{t,2}), \ldots, (w_{t,n}, r_{t,n})\}$$

where $w$ is load and $r$ is completed repetitions. The model compares position $j$ with position $j$ in the most recent comparable session; it does **not** use the heaviest load from the exercise as the suggestion for every set.

That preserves relative structure. For example, a 70 kg top set followed by a 60 kg back-off is retained as a 10 kg relationship instead of being flattened into two 70 kg suggestions.

---

## 3. Evidence Window and When a First Suggestion Exists

### 3.1 Recent-history window

An initial suggestion is available only when the most recent completed working session for the exercise is no more than **21 days** old. The 21-day boundary is a product safety rule: after a longer interruption, a historical load may be a poor proxy for current readiness, technical practice, injury status, or detraining.

This is not a claim that strength disappears after exactly 21 days. It is a deliberate rule against presenting stale history as a confident starting prescription.

### 3.2 Minimum evidence

For a historical position to receive a load suggestion, the preceding comparable position must have a recorded load. No completed working history, no load value, or a non-load-tracked exercise yields no initial load suggestion.

If a routine has an explicit authored target load, that prescription is respected rather than overridden by history.

### 3.3 No automatic load reduction

When a trainee misses the lower end of a rep range, the model does not lower the load automatically. It recommends returning to the bottom of the range at the held load. This avoids treating one session's performance—which can vary with sleep, nutrition, technique, exercise order, and measurement noise—as proof that a reduction is necessary.

Reducing load remains a user or coach decision.

---

## 4. Double Progression Rule

For working-set position $j$, let the prescribed repetition range be

$$R_j = [L_j, U_j]$$

with lower bound $L_j$ and upper bound $U_j$.

### 4.1 Shared progression gate

Load progression is an exercise-level decision, not a reward for one isolated set. A load increase is allowed only if **every comparable working-set position** in the preceding session:

1. has a valid repetition range;
2. reached at least its own upper bound $U_j$; and
3. was actually performed rather than merely auto-filled.

Formally, for a comparable prior session with $n$ working positions:

$$\text{readyToRaise} = \bigwedge_{j=1}^{n}\left( r_{t,j} \ge U_j \;\wedge\; \neg\text{autoFilled}_{t,j}\right)$$

The gate protects the relationship between top and back-off sets. It prevents a lighter set from progressing independently while a harder companion set has not yet demonstrated the same completion criterion.

### 4.2 Load decision

For ordinary external load:

$$w_{t+1,j} =
\begin{cases}
w_{t,j} + \Delta & \text{if readyToRaise}\\
w_{t,j} & \text{otherwise}
\end{cases}$$

For an assisted exercise, less assistance represents progress:

$$w_{t+1,j} = \max(0, w_{t,j} - \Delta)$$

when the shared gate is met.

$\Delta$ is the smallest practical loading step for the equipment, rather than an arbitrary percentage of the load:

| Equipment | Metric step | Imperial step |
|---|---:|---:|
| Barbell | 2.5 kg | 5 lb |
| Dumbbell | 2.0 kg | 5 lb |
| Cable | 2.5 kg | 5 lb |
| Machine | 5.0 kg | 10 lb |
| Assisted exercise | 2.5 kg less assistance | 5 lb less assistance |
| Unclassified/default | 2.5 kg | 5 lb |

These increments are practical defaults, not evidence that one increment is optimal for every exercise or athlete.

### 4.3 Repetition decision

When a valid range exists, the next repetition target follows:

$$r^*_{t+1,j} =
\begin{cases}
L_j & \text{if load is raised}\\
L_j & \text{if } r_{t,j} < L_j \text{ or repetitions are unavailable}\\
\min(r_{t,j} + 1, U_j) & \text{if load is held and } L_j \le r_{t,j} < U_j\\
U_j & \text{if load is held and } r_{t,j} \ge U_j
\end{cases}$$

In plain language:

- Below range: hold load and return to the range minimum.
- Within range: hold load and seek one additional repetition next time.
- At the top while another work set is not ready: hold load and repeat the upper bound.
- All comparable work sets at their tops: advance load and restart at the range minimum.

If no machine-readable repetition range exists, the model repeats the matching load and completed repetitions. It does not invent a progression target or a load increase.

### 4.4 Examples

| Previous session, all sets 8–12 | Next suggestion | Reason |
|---|---|---|
| 60 kg × 10, 60 kg × 9 | 60 kg × 11, 60 kg × 10 | Both are inside range; load stays fixed and repetitions advance one step. |
| 60 kg × 12, 60 kg × 10 | 60 kg × 12, 60 kg × 11 | The first set is held at its ceiling until the second catches up. |
| 60 kg × 12, 60 kg × 12 | 62.5 kg × 8, 62.5 kg × 8 | Every comparable work set reached its ceiling; both positions progress by the smallest barbell step. |
| 60 kg × 6, 60 kg × 9 | 60 kg × 8, 60 kg × 10 | The first set is below range; the model does not reduce load automatically. |
| 70 kg × 8, 60 kg × 10 | 70 kg × 9, 60 kg × 11 | Position-specific matching preserves the top-set/back-off structure. |

---

## 5. Within-Workout Autoregulation of Later Sets

Historical suggestions answer how to begin a workout. Once a real working set is completed today, current performance becomes more relevant for later open work sets.

### 5.1 Current-session anchor

For a later working set $k$, the model uses the latest completed earlier working set $a$ with a recorded load as the anchor.

If the prior session contains both positions, it carries forward the historical load relationship:

$$w_{today,k}^{*} = w_{today,a} + (w_{previous,k} - w_{previous,a})$$

Thus, if the first work set is performed 2.5 kg lighter than history, a historically 10 kg lighter back-off remains 10 kg below today's actual top set.

This is **structure preservation**, not a new progression event. It cannot create a load increase by itself.

### 5.2 Missing historical position

If a later working set has no historical counterpart—for example, the user added a work set today—the completed current anchor is used directly:

$$w_{today,k}^{*} = w_{today,a}$$

The repetition target is derived from the anchor's completed repetitions and the new set's range. Warm-ups and drop sets are never eligible anchors.

When a user adds a normal work set, it inherits the preceding **working** set's repetition range so that the new set has an intelligible target. It does not inherit raw load or repetitions as a pre-filled fact.

### 5.3 Long history gaps

After a history gap beyond 21 days, no initial suggestion is shown. However, after a working set is genuinely completed in the current workout, the model may still shape later sets from that current anchor. This is intentionally based on today's demonstrated performance, not on stale progression evidence.

---

## 6. Data Integrity and User-Control Safeguards

### 6.1 Auto-filled values are not performance evidence

A generated value may be useful as a starting point, but it is not proof that the trainee achieved the target. Auto-filled sets can be retained as session structure, yet they cannot satisfy the shared upper-range gate for a load increase.

### 6.2 User changes take precedence

Weight and repetitions form one combined suggestion. Once either is deliberately edited, the user-selected values take precedence for that set. The model does not fight manual judgement or silently restore its own target.

### 6.3 Failure is logged, not rewarded with an extra jump

Failure sets count as working sets because they represent an actual productive set at that position. They are not given a special automatic increase merely for being labelled failure. Their load and repetitions are evaluated by the same range and shared-gate rules as normal working sets.

### 6.4 Repetitions in reserve

RIR can be recorded for context, but it is not currently a mathematical condition for changing the suggested load. This is deliberate: self-reported RIR is useful but uncertain, and the current model keeps its advancement criterion observable and simple—completed repetitions relative to the prescribed range.

---

## 7. Scientific Interpretation

### 7.1 What is well aligned with the literature

The model is consistent with several broad, evidence-supported resistance-training principles:

- **Progressive overload**: Training adaptation requires an evolving stimulus; increasing load after demonstrated capacity is a conventional way to apply overload.
- **High-effort resistance training can use different loads and repetition ranges**: A repetition range is a practical autoregulation tool, not a claim that one exact number of repetitions is uniquely effective.
- **Volume and set quality matter**: Protecting the entire working-set structure avoids interpreting one successful set as sufficient evidence that all planned work is ready to progress.
- **Proximity to failure is meaningful but not binary**: Failure is a real effort endpoint, but current evidence does not justify assuming that failure automatically produces superior adaptations or that it should automatically trigger a heavier prescription.

The model's conservative all-sets gate is most defensible as a **coaching heuristic for stable execution and interpretable training records**. It is not a direct reproduction of a randomized trial or a universal requirement for strength and hypertrophy progression.

### 7.2 What is a product choice rather than settled science

The following are intentionally transparent engineering choices:

- the 21-day history boundary;
- advancing by one repetition at a time within a range;
- requiring all comparable work sets to hit their upper bounds before any load is raised;
- the equipment-specific absolute load increments;
- no automatic deload after a below-range session;
- using the latest completed set to reshape later sets in the same workout.

These rules favor conservative, explainable behavior. A coach may reasonably choose different criteria for novice practice, peaking, powerlifting, rehabilitation, high-volume hypertrophy work, autoregulated RIR programming, or exercises with coarse machine stacks.

---

## 8. Known Limits and Appropriate Use

The model has no direct knowledge of technique quality, pain, range of motion, tempo, spotter assistance, sleep, acute illness, nutrition, exercise substitution, menstrual-cycle effects, medication, or injury status. A completed repetition count alone cannot fully characterize training stimulus or readiness.

Accordingly:

- A suggestion is appropriate to accept only when it matches the trainee's technique, confidence, and current condition.
- Pain, dizziness, new neurological symptoms, or suspected injury should override progression logic and be assessed appropriately.
- Repetition targets should not be treated as a requirement to train to failure.
- Long-term program quality still depends on exercise selection, weekly volume, frequency, recovery, and individual goals—variables outside this per-exercise, per-set rule.

---

## 9. Scientific References & Sources

- American College of Sports Medicine. (2009). *Progression Models in Resistance Training for Healthy Adults*. **Medicine & Science in Sports & Exercise, 41**(3), 687–708. [DOI: 10.1249/MSS.0b013e3181915670](https://doi.org/10.1249/MSS.0b013e3181915670)
- Currier, B. S., et al. (2026). *Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults: An Overview of Reviews*. **Medicine & Science in Sports & Exercise, 58**(4), 851–872. [DOI: 10.1249/MSS.0000000000003897](https://doi.org/10.1249/MSS.0000000000003897)
- Schoenfeld, B. J., Ogborn, D., & Krieger, J. W. (2017). *Dose-response relationship between weekly resistance training volume and increases in muscle mass: A systematic review and meta-analysis*. **Journal of Sports Sciences, 35**(11), 1073–1082. [DOI: 10.1080/02640414.2016.1210197](https://doi.org/10.1080/02640414.2016.1210197)
- Grgic, J., et al. (2021). *Effects of resistance training performed to repetition failure or non-failure on muscular strength and hypertrophy: A systematic review and meta-analysis*. **Journal of Sport and Health Science, 11**(2), 202–211. [DOI: 10.1016/j.jshs.2021.01.007](https://doi.org/10.1016/j.jshs.2021.01.007)
- Refalo, M. C., et al. (2023). *Influence of Resistance Training Proximity-to-Failure on Skeletal Muscle Hypertrophy: A Systematic Review with Meta-analysis*. **Sports Medicine, 53**, 649–665. [DOI: 10.1007/s40279-022-01784-y](https://doi.org/10.1007/s40279-022-01784-y)
- Zourdos, M. C., et al. (2016). *Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training*. **Strength and Conditioning Journal, 38**(4), 42–49. [DOI: 10.1519/SSC.0000000000000218](https://doi.org/10.1519/SSC.0000000000000218)
