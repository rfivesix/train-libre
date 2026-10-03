# AI meal scan benchmark

The synthetic regression set lives in `test/ai_meal_scan_runner_test.dart`. It compares ingredient identity, raw gram amounts, catalog barcode, validation result, and repair count against the prior single-request orchestration. The catalog test also compares the cached search order with the original SQL search.

The cloud latency target requires a real device, a fixed network, and the user's own API keys. For each of `gpt-5.4-mini` and `gemini-2.5-flash`, run at least 30 text and 30 one-photo scans with the same fixed inputs in both the baseline build and this build. Alternate build order to reduce network drift. Keep the camera, input images, model, device, and connection identical. Record tap-to-visible-review time from `ai_meal_scan_completed.duration_seconds`; use the random request ID to join `ai_meal_scan_usage` and `ai_meal_review_finished`.

For each model and input mode, both conditions must hold: the new median is at least 30% lower than baseline, and the new median is below 10 seconds. Also report P90, three-photo scans, `primary_first_pass_accepted`, `repair_rounds_count`, `validation_runs_total_count`, review outcome, and total tokens. The speed mode can add a second billable call after four seconds, so include provider call count and cost in the comparison.

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
