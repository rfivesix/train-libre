# Train Libre Roadmap

## Mid-term
- **Comprehensive Analytics & Screen Accessibility Overhaul (New):** Rethink and redesign the core Statistics screen alongside the layout structures of the Workout and Nutrition tabs. The goal is to optimize data density and navigation, allowing users to view and reach their target progression metrics significantly faster and with fewer taps. (Exact UX wireframes and scope are fully open to iteration).
- Program library (“store”) of curated training plans (e.g. PPL, upper/lower, hypertrophy blocks) that can be copied into personal routines.
- Weekly training calendar to assign plans/routines to specific days (e.g. Mon Push, Wed Pull, Fri Legs) and see planned vs. completed sessions.
- More advanced training and nutrition goal logic (training/rest‑day profiles, simple refeed/high‑day patterns) on top of the adaptive TDEE estimator.
- Official Google Play Store release.
- F-Droid Release.

## Long-term
- Wearable-/watch‑first logging experiences for minimal‑friction set tracking.
- Strava and other privacy‑respecting FOSS ecosystem integrations where they make sense.
- Deeper AI‑assisted workflows (meal capture, planning) while keeping BYOK and strict on‑device validation.

## Ideas / Potential
_These are early ideas, not commitments. They will only happen if they make sense for users and for the project._

- **Optional low‑cost AI add‑on:** If there is enough demand, Train Libre might offer a privacy‑respecting subscription where the app manages the AI API key for you (no manual key setup, no per‑token billing hassle). The core app would stay open source, offline‑first, and fully usable without any subscription.
- **Optional private account & sync (self‑hostable first):** Long‑term, there could be an optional account layer for encrypted backup and multi‑device sync, designed to be self‑hostable (e.g. via a small Docker setup, possibly on top of something like Supabase or a similar backend). A public, centrally hosted instance might exist later, but would remain strictly optional because Train Libre should work fully without any account or external server.
- **On-Device Local AI Insights (BYOM - Bring Your Own Model):** Explore running ultra-lightweight, quantized LLMs directly on-device to provide intelligent, 100% private coaching adjustments and sleep/nutrition correlations without cloud leaks.
- **Evidenced-Based Fatigue & Periodization Tracking:** Advanced metrics for powerlifters (fatigue accumulation patterns, volume-load velocity tracking, and automated deload recommendations derived from historical RIR trends).