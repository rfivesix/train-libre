# AI meal scan benchmark

The synthetic regression set lives in `test/ai_meal_scan_runner_test.dart`. It compares ingredient identity, raw gram amounts, catalog barcode, validation result, and repair count against the prior single-request orchestration. The catalog test also compares the cached search order with the original SQL search.

The cloud latency target requires a real device, a fixed network, and the user's own API keys. For each of `gpt-5.4-mini` and `gemini-2.5-flash`, run at least 30 text and 30 one-photo scans with the same fixed inputs in both the baseline build and this build. Alternate build order to reduce network drift. Keep the camera, input images, model, device, and connection identical. Record tap-to-visible-review time from `ai_meal_scan_completed.review_visible_seconds`, first displayed nutrition from `preliminary_nutrition_seconds`, and completed automatic processing from `duration_seconds`; use the random request ID to join `ai_meal_scan_usage` and `ai_meal_review_finished`.

For each model and input mode, both conditions must hold: the new median is at least 30% lower than baseline, and the new median is below 10 seconds. Also report P90, three-photo scans, `primary_first_pass_accepted`, `repair_rounds_count`, `validation_runs_total_count`, review outcome, and total tokens. The earlier speed mode could add a second billable call after four seconds; keep provider call count and cost in the comparison to quantify its removal.

Do not shorten or remove local validation based on first-pass acceptance alone. Check validation time and the proportion of initially accepted meals saved unchanged before proposing that separately.

## First exploratory recording — 2026-10-03

An iPhone 17 Pro Simulator recording with `gpt-6-luna` and two photos shows the scan button tapped at approximately 12.2 seconds and the review first visible at approximately 48.8 seconds: **about 36–37 seconds**. The review displays **11,812 tokens**. The old “Matching the ingredients” label lasts about 17 seconds; in that build it is set when an automatic AI repair begins, so it does not represent local catalog search alone. The recording establishes at least one repair attempt, but does not reveal the exact repair count, parallel-request count, or provider and validation durations. This is an exploratory two-photo run with a different model, not one of the required text or one-photo reference-model benchmarks.

## Second exploratory log — 2026-10-03

A later two-photo `gpt-6-luna` scan took **40.15 s** from tap to visible review and was saved unchanged. Preparation took 0.03 s. The primary AI response arrived at 15.60 s and failed local validation at 17.06 s (1.46 s validation). The parallel request started at 4.03 s, returned at 21.85 s and failed validation at 22.22 s (0.36 s validation). The selected candidate was repaired in one AI request from 22.22 s to 40.06 s (17.84 s); its subsequent local validation passed in 0.01 s. All three provider calls used 6,624 input and 5,128 output tokens, 11,752 total.

The critical path is dominated by the first provider response and the repair. Waiting for the parallel candidate after the first validation added 5.16 s in this run. Without knowing which candidate was selected or why both first validations failed, it is not safe to conclude that the parallel call or repair could be removed. Even eliminating that wait would leave this run around 35 s if the same primary candidate and repair succeeded. A sub-10-second goal cannot be reached on this particular run merely by removing local validation (1.83 s across the two initial candidates and the repair). The local log now records closed failure categories, scores, selected candidate source and token usage per provider call for subsequent runs; the earlier log cannot be reconstructed retroactively.

## Third exploratory log — 2026-10-03

Another two-photo scan with `gpt-5.4-nano` took **16.30 s** and was saved unchanged. This is much faster than the `gpt-6-luna` example, but the input photos and model changed, so it is not a controlled benchmark or a one-photo target-model result.

| Request | Wall time | Input / output / total tokens | Local result |
| --- | ---: | ---: | --- |
| Primary | 7.17 s | 3,032 / 886 / 3,918 | Failed, score 0: nutrition anchor, catalog ambiguity, low confidence |
| Parallel | 5.65 s, started at 4.03 s | 3,032 / 793 / 3,825 | Failed, score 20: catalog ambiguity, low confidence |
| Repair of parallel candidate | 5.46 s | 4,845 / 866 / 5,711 | Passed, score 76; low-confidence warning remained |

The primary validation finished at 9.43 s; selecting the parallel candidate finished at 10.76 s, a 1.33 s critical-path wait. Local validation across all candidates used 3.30 s. The repair accounts for 42% of the 13,454 tokens and 5.46 s on the critical path. The parallel candidate had a better validation score than the primary, so removing the parallel request cannot be assumed accuracy-neutral.

The selected candidate's only logged issue categories were catalog ambiguity and low confidence. In the current `repairMealCaptureCandidate` routing, *any* low-confidence warning prevents the short catalog-only path. The repair therefore resends both photos and all candidate items; this contributes to its 4,845 input tokens versus 3,032 for each initial request. The closed categories do not reveal issue counts or affected items, and the log does not prove that a text-only catalog repair would preserve food identity. A conservative experiment would allow catalog-only selection when all low-confidence warnings concern the same ambiguous items, preserve the original food identity and gram amounts, then run the full local validator. Compare the resulting corrections and saved-unchanged rate on a fixed meal set before adopting it.

## Fourth exploratory log & Optimization Resolution — 2026-10-03

Subsequent scans and iterative improvements revealed four key structural optimizations:

1. **Retirement of Speculative Parallel Hedging ("Speed mode"):**
   Telemetry proved that speculative parallel requests ("Speed mode") launched after 4 seconds consistently inflated token usage by 1.8–2.0x (accumulating up to 13,454 tokens) and frequently prolonged scans by 1.3–5.2 s while waiting for the secondary candidate. Hedging was deactivated by default (`enableHedge = false`) and the setting removed from AI Settings, eliminating token waste and provider API contention.

2. **Reasoning Budget Configuration:**
   Exploratory scans with `'reasoning_effort': 'low'` for OpenAI reasoning models (`gpt-6-luna`, `o1`, `o3`, etc.) and `thinkingBudget: 0` for Gemini lowered first-pass inference time from ~16–20 s down to:
   - `gemini-flash-latest`: **4.78 s**
   - `gpt-4o`: **4.84 s**
   - `gpt-5.4-mini`: **5.69 s**
   - `gpt-5.6-luna`: **9.08 s**

3. **Validation Rule Calibration & Text-Only Repair:**
   - In `RulesLogic`, `ambiguous_nutrition_match` was restricted to genuinely competing candidates within $\le 0.08$ score delta of the top match (rather than comparing the top match against the entire 20-item SQLite search set). This eliminated false-positive repair triggers on normal produce variations.
   - Demoted `tiny_quantity` ($\le 5\,\text{g}$) and `low_ai_confidence` to `info` severity so they no longer penalize validation scores.
   - The exploratory text-only repair omitted photos and took 3.2–4.2 s. Catalog-only repairs still omit them; visual and quantity repairs now retain the photos so the model can check the original evidence.
   - A subsequent `gpt-5.6-luna` scan achieved **13.07 s total duration**, **First pass: true**, **Score: 100**, **0 repairs**, and used only **2,548 total tokens** (down from 11,812).

4. **Progressive Review Screen Reveal with Skeleton Loading:**
   Instead of holding the user on a blocking full-screen waiting orb until local validation and candidate repair complete, the capture flow now immediately navigates to `AiMealReviewScreen` as soon as Call 1 completes (`onCandidateReady`). The recognized food items and photos appear immediately, while local database matching completes in the background. The macro header, ingredient cards, and diary save button use elegant `Skeletonizer` shimmer loading until background matching finishes, reducing perceived latency to ~4.8–11.0 s.

Current requests only send `thinkingBudget: 0` to explicit Gemini 2.5 Flash variants. Other Gemini models keep their supported defaults. The exploratory times above are not a controlled accuracy or latency comparison.
