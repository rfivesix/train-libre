# Train Libre

Privacy-first, offline-first Flutter fitness & nutrition tracking app. No cloud dependency, local SQLite (via `drift` + `sqflite`).

## Commands

- Tests: `flutter test`
- Static analysis: `flutter analyze`
- Format: `dart format .`
- Codegen (after touching `*.g.dart`-generating sources, e.g. drift/json_serializable): `flutter pub run build_runner build --delete-conflicting-outputs`

## Structure

- `lib/features/<feature>/` — feature-first modules (diary, workout, nutrition_recommendation, statistics, steps, sleep, etc.)
- `lib/core/` — shared infrastructure and performance utilities
- `lib/services/` — cross-cutting services (ai, health, storage, telemetry)
- `lib/data/` — data layer / persistence
- `lib/widgets/common/` — shared widgets
- `lib/generated/`, `lib/l10n/`, `build/`, `.dart_tool/`, `coverage/` — generated/build output, do not hand-edit

## Conventions

- Don't manually edit generated files (`*.g.dart`, `*.freezed.dart`, anything in `lib/generated/`) — regenerate via build_runner instead.
- Keep new code inside the relevant `lib/features/<feature>/` module; avoid dumping logic into `lib/widgets/` or top-level `lib/`.
- This is an offline-first, privacy-first app — avoid introducing network/cloud dependencies without discussing it first.
- Prefer running `flutter analyze` and relevant `flutter test` files after non-trivial changes.
