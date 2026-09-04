# Train Libre Engineering Documentation

This directory contains the technical documentation for the Train Libre architecture, modules, and processes.

## Website and F-Droid publishing

The public website is hosted at `https://trainlibre.com/`. GitHub Pages serves
the root of `gh-pages`; `docs/CNAME` preserves the custom domain when the website
is deployed. The F-Droid repository is at `https://trainlibre.com/fdroid/repo`.

- `deploy-docs.yml` publishes changes to `docs/` on `main`, changes to that
  workflow itself, or a manual dispatch.
- `fdroid-repo.yml` runs once on release publication, or on manual dispatch.
  A manual dispatch resolves the latest release once and uses its tag for APKs,
  version information, store metadata, screenshots, and release notes. The
  workflow and F-Droid configuration still come from the selected workflow ref.
- F-Droid uses the App Store marketing screenshots from
  `ios/fastlane/screenshots` at that release tag, not the raw iOS screenshots.
  Only the `1320x2868` set is copied, in numbered order, for `en-US` and `de-DE`.
  Other resolutions and the duplicate `en-GB` set are excluded. English is
  required; if German is absent, only the English default is published. Old
  phone screenshots are removed from the generated metadata before copying.
- Both workflows share the `gh-pages-publish` concurrency group to prevent
  competing pushes. Keep the group identical and do not cancel active publishes.
  `queue: max` lets multiple pending publishes wait without replacing each other.
- Keep the existing F-Droid signing secrets and repository fingerprint unchanged.
  Regenerate indexes with `fdroid update`; never edit the published JSON by hand,
  because the signed entry contains the index hash and size.

For a repository/domain hotfix, first put the workflow changes on `main`, then
manually dispatch **Update F-Droid Repository** with `main` selected. Rerunning an
old release job uses its old workflow, not the corrected one. Confirm that both
the docs and F-Droid publishes finish successfully, then check the live repository
address, signed indexes, APK downloads, and adding/updating the repo in F-Droid.

Offline regression checks (requires Python, PyYAML, bash, and jq):

```sh
python3 .github/scripts/test_fdroid_workflows.py
```

These tests use fixtures and do not validate live TLS, real signatures, or Android
client behavior. The F-Droid workflow also runs them before generating the index.

## Architecture & System
- **[System Architecture](../documentation/architecture.md)**
  Details the high-level layering, clean architecture boundaries, and execution flows within the app. Consult this when extending or adding a new feature module.
- **[Project Overview](../documentation/overview.md)**
  Provides a bird's-eye view of app capabilities, shell navigation, and module responsibilities. Read this for a general introduction to the repository.
- **[Data Models & Storage](../documentation/data_models_and_storage.md)**
  Explains the local persistence strategy, database schema rules, and Drift ORM implementations. Reference this when migrating tables or modifying core storage mechanisms.
- **[UI & Widgets](../documentation/ui_and_widgets.md)**
  Covers the app's design system, custom surface extensions, widget catalog, and interaction patterns. Consult this when building new interfaces to ensure visual consistency.

## Modules & Features
- **[Statistics Module](../documentation/statistics_module.md)**
  Outlines the data sources, range policies, and recovery heuristics driving the analytics views. Consult this when modifying chart logic or metric calculations.
- **[Sleep Module Current State](../documentation/sleep/sleep_current_state.md)**
  Describes the pipeline, platform ingestion, and aggregation mechanics of the sleep tracking module.
- **[Sleep Health Score V2](../documentation/sleep/sleep_health_score_v2.md)**
  Details the mathematical modeling behind the sleep scoring algorithm and pipeline phases.
- **[Adaptive Nutrition Recommendation](../documentation/adaptive_nutrition_recommendation_current_state.md)**
  Explains the Bayesian logic, adaptive estimation constraints, and recommendation flow for nutrition goals.
- **[AI Meal Features Architecture](../documentation/ai_meal_features_architecture.md)**
  Maps out the opt-in meal processing AI systems and their integration layers.
- **[Health Steps Integration](../documentation/health_steps.md)**
  Documents how health steps are aggregated, synchronized, and stored within the application.

## Synchronization & Integrations
- **[Wger Catalog Refresh & Distribution](../documentation/wger_catalog_refresh_system.md)**
  Describes the synchronization patterns for the exercise catalog derived from Wger base data.
- **[OFF Catalog Refresh System](../documentation/off_catalog_refresh_system.md)**
  Explains the background fetch and local merge processes for Open Food Facts catalogs.
- **[Health Export One-Way](../documentation/health_export_one_way.md)**
  Outlines the one-way background synchronization rules for external health metric platforms.
