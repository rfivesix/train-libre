# Train Libre

**Private workout and nutrition tracking for Android and iOS.**

<p align="center">
  <a href="https://github.com/rfivesix/train-libre/stargazers">
    <img src="https://img.shields.io/github/stars/rfivesix/train-libre?style=for-the-badge&color=F5B301" alt="Stars">
  </a>
  <a href="https://github.com/rfivesix/train-libre/network/members">
    <img src="https://img.shields.io/github/forks/rfivesix/train-libre?style=for-the-badge&color=4C9BE8" alt="Forks">
  </a>
  <a href="https://github.com/rfivesix/train-libre/issues">
    <img src="https://img.shields.io/github/issues/rfivesix/train-libre?style=for-the-badge&color=E05D44" alt="Open Issues">
  </a>
  <a href="https://github.com/rfivesix/train-libre/releases">
    <img src="https://img.shields.io/github/v/release/rfivesix/train-libre?style=for-the-badge&color=34C759" alt="Latest Release">
  </a>
  <a href="https://github.com/rfivesix/train-libre/watchers">
    <img src="https://img.shields.io/github/watchers/rfivesix/train-libre?style=for-the-badge&color=7A3EF0" alt="Watchers">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-App-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Drift-Local%20Database-0175C2?style=for-the-badge&logo=sqlite&logoColor=white" alt="Drift">
  <img src="https://img.shields.io/badge/Offline%20First-Architecture-2E8B57?style=for-the-badge" alt="Offline First">
  <img src="https://img.shields.io/badge/Android%20%26%20iOS-Supported-111827?style=for-the-badge" alt="Android and iOS">
</p>

<br />

Train Libre is an open-source, offline-first fitness app for logging workouts, calories, macros, bodyweight, and recovery — without ads, mandatory accounts, or commercial tracking.

Designed for people who want serious tracking without social feeds, gamification, or subscription pressure, Train Libre prioritizes **privacy**, **local data ownership**, and **transparent analytics**.

### Screenshots

<div align="center">
  <table>
    <tr>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_diary.png" alt="Diary Log" width="100%"><br>
        <sub><b>Diary</b></sub>
      </td>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_running_workout.png" alt="Workout Tracking" width="100%"><br>
        <sub><b>Workout</b></sub>
      </td>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_nutrition.png" alt="Nutrition Tracking" width="100%"><br>
        <sub><b>Nutrition</b></sub>
      </td>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_ai.png" alt="AI Meal Capture" width="100%"><br>
        <sub><b>AI Meal Capture</b></sub>
      </td>
    </tr>
    <tr>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_recovery.png" alt="Recovery Trends" width="100%"><br>
        <sub><b>Recovery</b></sub>
      </td>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_measurements.png" alt="Body Measurements" width="100%"><br>
        <sub><b>Measurements</b></sub>
      </td>
      <td width="24%" align="center">
        <img src="assets/screenshots/iOS/en-US/dark/iOS_dark_data.png" alt="Data Insights" width="100%"><br>
        <sub><b>Data Insights</b></sub>
      </td>
      <td width="24%"></td>
    </tr>
  </table>
</div>

## Download & Install

<table align="center">
  <tr>
    <td align="center" valign="middle" width="250">
      <a href="https://apps.apple.com/us/app/train-libre/id6767055511">
        <img
          src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
          alt="Get it on App Store"
          width="100%"
        />
      </a>
      <br><sub><b>App Store Release</b></sub>
    </td>
    <td width="30"></td>
    <td align="center" valign="middle" width="250">
      <a href="http://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/rfivesix/train-libre/releases">
        <img
          src="https://raw.githubusercontent.com/ImranR98/Obtainium/main/assets/graphics/badge_obtainium.png"
          alt="Get it on Obtainium"
          width="100%"
        />
      </a>
      <br><sub><b>Android (via Obtainium)</b></sub>
    </td>
    <td width="30"></td>
    <td align="center" valign="middle" width="250">
      <a href="https://rfivesix.github.io/train-libre/fdroid/repo?fingerprint=759124FF05FDCFA070EB2475D86D79614AE4F58779E391C8AE44C4EDC7A2CFB8">
        <img
          src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
          alt="Get it on F-Droid"
          width="100%"
        />
      </a>
      <br><sub><b>Android (via F-Droid)</b></sub>
    </td>
  </tr>
</table>

*Google Play release is currently not available.*

## Platform Support

Train Libre is built with Flutter and supports:
- **iOS** (Active)
- **Android** (Active)

## Key Features

- **Workout Tracker:** Log sets (warm-up, failure, dropsets), routines, and session history.
- **Calorie & Macro Tracker:** Track nutrition, hydration, and supplements with adaptive weekly guidance.
- **Bodyweight & Recovery Analytics:** Deep insights into muscle readiness, volume trends, and body measurements.
- **Sleep & Vitals:** Sleep Health Score across five domains, plus steps and heart-rate aggregates imported from Apple Health or Health Connect.
- **Next-Gen AI Meal Capture:** Capture meals from photos or text via BYOK (Bring Your Own Key) setup. Fully integrated with a holistic culinary anchor (`mealContext`) and a state-aware "Top-N Fuzzy Alternatives" SQLite matching system that prevents hallucinations. Always reviewable and self-repairing before saving.
- **Privacy & Local-First:** Data stays on device. Optional one-way health export to Apple Health and Google Health Connect.

## Privacy & Philosophy

- **No Ads. No Mandatory Account. No Commercial Tracking (Optional Pseudonymised Usage Statistics, off by default).**
- **Offline-First:** Your data stays local unless you explicitly choose otherwise.
- **Open-Source Transparency:** Trust through public code and understandable data flows.
- **User-Controlled AI:** Optional AI features require your own API key; no data is sent to providers without opt-in.

## Documentation

This project features a comprehensive, modular documentation suite split by target audience and component. Use the links below to access the technical resources:

### Developer Resources
*   [Developer Overview](documentation/developer/overview.md): Technical vision, key architectural pillars, technology stack, and testing philosophy.
*   [Architecture & SQLite Lifecycle](documentation/developer/architecture.md): Clean Architecture layering and database connection lifecycle pattern.
*   [Data Flow & State Lifecycle](documentation/developer/data_flow_and_state.md): Reactive reads, imperative writes, subscription cancellation, and UI concurrency guards.
*   [Localization Architecture](documentation/developer/localization_architecture.md): Offline-first relational localization and the guide for adding a new locale.

### Advanced Features & Algorithmic Transparency
*   [Smart Features Overview](documentation/features/overview.md): Overview of algorithmic features and architectural privacy invariants.
*   [Bayesian TDEE Estimator](documentation/features/bayesian_tdee_estimator.md): Comprehensive mathematical and statistical formulation of the Kalman filter-based adaptive energy expenditure engine.
*   [BYOK AI Meal Validation](documentation/features/byok_ai_validation.md): AI meal capture pipeline details, fuzzy validation scoring, and the 3-pass self-repair verification loop.
*   [**Native Health Sync & Export**](documentation/features/health_sync_export.md): Bidirectional vital synchronization (Steps, Sleep), outbound manual log export pipelines, SQLite-backed idempotency tracking, and fault-tolerance patterns.
*   [Sleep Health Score Engine](documentation/features/sleep_scoring_engine.md): The five scoring domains, their curve shapes, and the soft-cap penalty logic.
*   [Muscle Recovery & Fatigue Model](documentation/features/muscle_recovery_model.md): Volume-based recovery windows and intensity-driven fatigue extension per muscle.
*   [Estimated 1-Rep Max Heuristic](documentation/features/intelligent_workouts.md): The Epley-based submaximal strength model behind PRs and progression.
*   [Telemetry & Privacy Architecture](TELEMETRY.md): The complete opt-in telemetry event catalog and the anti-profiling safeguards around it.

For the full interlinked documentation map, see the main [Documentation Entry Point](documentation/README.md).

## Roadmap

The long-term vision, future modules, and planned features are maintained in the [ROADMAP.md](ROADMAP.md) file.

## Star history
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=rfivesix/train-libre&style=landscape1&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=rfivesix/train-libre&style=landscape1" />
  <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=rfivesix/train-libre&style=landscape1" />
</picture>

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=rfivesix/train-libre&type=date&theme=dark&legend=top-left" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=rfivesix/train-libre&type=date&legend=top-left" />
  <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=rfivesix/train-libre&type=date&legend=top-left" />
</picture>


## Credits

- **[Open Food Facts](https://openfoodfacts.org/)** for food database coverage.
- **[wger](https://github.com/wger-project/wger)** for the workout database foundation.

## License

[GPL-3.0](LICENSE)
