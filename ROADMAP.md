# Train Libre Roadmap

## What's Next
* **Curated Training Plan Library ("Store"):** A program library of curated training plans (e.g., PPL, upper/lower, hypertrophy blocks) that can be copied directly into personal routines. This includes building a clean, rigid internal infrastructure to handle preset templates that users can easily duplicate and edit.
* **Fitness Recipe Book & Nutrition Infrastructure:** Integrate a comprehensive recipe section backed by an open fitness recipe dataset or API. Users can browse or search fitness-focused recipes and instantly import their macro profiles and ingredients directly into their daily nutrition protocol as cooked meals, eliminating manual single-ingredient tracking.
* **Advanced Training & Nutrition Goal Logic:** Introduce distinct training/rest‑day profiles and simple refeed/high‑day patterns on top of the adaptive TDEE estimator to dynamic adjust goals based on the active day type.

## Recently Delivered
* **Long-term nutrition goals and adaptive reviews (1.5.0):** Set a weight target from a recorded measurement, follow the trajectory, and review recommendations before choosing whether to apply them.
* **Manual workout plans (1.5.0):** Schedule saved routines as a fixed weekly plan or a flexible 1–14 day sequence, include rest days, and track planned sessions.
* **Training experience levels:** The app includes experience-level support for tailoring training guidance.

## Mid-term
* **Wearable-/watch‑first logging experiences:** Implement wear-focused tracking modules for minimal‑friction set tracking directly from a smartwatch during active workouts.
* Official Google Play Store release.

## Long-term
* **Optional private account & sync (self‑hostable first):** Long‑term, there could be an optional account layer for encrypted backup and multi‑device sync, designed to be self‑hostable (e.g. via a small Docker setup, possibly on top of something like Supabase or a similar backend). A public, centrally hosted instance might exist later, but would remain strictly optional because Train Libre should work fully without any account or external server.
* **Server-Backed Web Application & Profile Dashboard:** A clean, larger-scale web interface connecting to the personal self-hosted or cloud server instance, allowing users to analyze historical trends on a big screen and manage cross-device profile configurations.
* **Decentralized Social & Sharing Features:** Secure, opt-in mechanisms to share custom recipes and specialized training plans directly with friends or other users hosted on the same server instance.
* Strava and other privacy‑respecting FOSS ecosystem integrations where they make sense.
* Deeper AI‑assisted workflows (meal capture, planning) while keeping BYOK and strict on‑device validation.

## Ideas / Potential
*These are early ideas, not commitments. They will only happen if they make sense for users and for the project.*
* **Optional low‑cost AI add‑on:** If there is enough demand, Train Libre might offer a privacy‑respecting subscription where the app manages the AI API key for you (no manual key setup, no per‑token billing hassle). The core app would stay open source, offline‑first, and fully usable without any subscription.
* **On-Device Local AI Insights (BYOM - Bring Your Own Model):** Explore running ultra-lightweight, quantized LLMs directly on-device to provide intelligent, 100% private coaching adjustments and sleep/nutrition correlations without cloud leaks.
* **Evidenced-Based Fatigue & Periodization Tracking:** Advanced metrics for powerlifters (fatigue accumulation patterns, volume-load velocity tracking, and automated deload recommendations derived from historical RIR trends).
* **On-Device Adaptive Biometric Fine-Tuning:** Investigate a lightweight, purely mathematical on-device ML model (e.g., using Bayesian Regression) to correlate individual sleep scores, recovery metrics, and macro nutrition directly with lift-specific e1RM progression. By initializing the system with expert-vetted sports science principles (Priors), the model provides immediate value from day one and progressively fine-tunes itself entirely offline to map the user's unique biological fatigue signatures without needing central user datasets.
