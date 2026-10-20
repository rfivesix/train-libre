# Developer Documentation

Train Libre is a Flutter application whose durable user data is held in a local Drift/SQLite database. Platform services, optional network features, and generated catalogs add capabilities around that local data. This section describes the implementation in this repository; product behavior is covered by [Feature Documentation](../features/overview.md), and user workflows by the [User Guide](../user_guide/overview.md).

## Start here

- [System architecture and database lifecycle](architecture.md): startup wiring, persistence, migrations, and backup boundaries.
- [Data flow and state lifecycle](data_flow_and_state.md): repository reads and writes, subscriptions, and asynchronous UI state.
- [Localization architecture](localization_architecture.md): app strings and localized catalog data.
- [Food search](food_search.md): indexed catalog search, ranking, and aliases.
- [Home-screen widgets](ios_home_screen_widgets.md): Dart snapshots and native iOS/Android rendering.

## Repository map

| Area | Location |
| --- | --- |
| App entry point and root providers | `lib/main.dart` |
| Feature modules (presentation, application/domain/data) | `lib/features/` |
| Drift tables, generated database code, migrations | `lib/data/` |
| Shared services and platform adapters | `lib/services/`, `lib/core/` |
| Localized app string catalogs | `lib/l10n/app_*.arb` |
| Native Android host and widgets | `android/app/src/main/` |
| Native iOS host and widget extension | `ios/Runner/`, `ios/LiveActivity/`, `ios/TrainLibreLiveActivity/` |
| Catalog/build tooling | `script/`, `tool/` |

The feature directory structure is a useful guide, not an absolute dependency rule. Trace a behavior through its callers and implementations before relying on a folder name or class name as an architectural contract.

## Contributor checks

Use the repository's declared Flutter/Dart toolchain and run focused checks for the code changed. The repository includes Dart tests under `test/`, native iOS tests under `ios/RunnerTests/`, and CI workflows under `.github/workflows/`; workflow triggers and commands are the source of truth for what CI enforces. For documentation changes, run `python3 tool/build_docs.py` and `python3 tool/verify_website.py`.

Database tests should use an injected executor or `DatabaseHelper.forTesting(...)` where applicable rather than opening a user's normal database. See [System architecture](architecture.md) for database ownership and migration details.
