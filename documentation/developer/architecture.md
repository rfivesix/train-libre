# System architecture and database lifecycle

Train Libre is organized around Flutter feature modules. Presentation code calls application/domain logic and repositories; repository implementations and data sources perform persistence and platform work. The codebase uses these boundaries pragmatically: verify concrete call paths instead of assuming every feature follows an identical Clean Architecture template.

## Startup and dependency wiring

`main()` in `lib/main.dart` initializes Flutter bindings and startup services, opens the main `AppDatabase`, registers it with `DatabaseHelper`, constructs repositories and long-lived services, then provides them to the widget tree. The root `MultiProvider` makes these instances available to screens. Providers created with `.value` are preconstructed objects; providers with `create` own the object they create and should dispose it as configured.

The app root supplies `AppLocalizations.supportedLocales` and localization delegates to `MaterialApp`. Startup screens handle consent/legal-version routing before the initialized application. Background work does not share the main isolate's database object: its callback creates a database connection in that isolate and closes/ends with its own task lifecycle. Follow `callbackDispatcher` and its registered task in `lib/main.dart` when changing background work.

```text
main()
  ├─ initialize bindings and platform/startup services
  ├─ open AppDatabase → DatabaseHelper
  ├─ construct data sources → repositories → services
  └─ MultiProvider → MyApp / navigation / feature screens
```

## Persistence ownership

`AppDatabase` is declared in `lib/data/drift_database.dart`; its current Drift schema version is **40** (`schemaVersion`). Production connections use SQLite. Feature repositories and local data sources provide the access boundary used by presentation and application code. `DatabaseHelper` in `lib/data/database_helper.dart` supplies the registered database and a testing injection path.

Do not treat every piece of state as database state. Preferences such as selected display options use their owning services and storage; secrets use secure storage; transient screen state belongs to view models/widgets; platform health records remain owned by HealthKit or Health Connect. Backups are implemented separately by `BackupManager` and backup models. Trace the relevant feature before documenting a data owner's exact storage or retention.

## Migrations, repair, and indexes

`AppDatabase.migration` in `lib/data/drift_database.dart` runs `beforeOpen` setup, including foreign-key and recursive-trigger pragmas, `reconcileSchema()`, and creation/maintenance of selected derived structures. `MigrationStrategy.onUpgrade` contains versioned migrations; inspect its cases when adding a schema change and update the Drift schema version when required. The migration tests under `test/` are useful corroboration, but the migration implementation is authoritative.

`reconcileSchema()` is a limited additive repair pass: it creates missing declared tables and can add missing nullable or defaulted columns. It logs and skips a missing non-null/no-default column because existing rows cannot be populated safely. It is not a replacement for a data migration, renames, constraints, or destructive changes. Search-index and catalog-specific structures are maintained by their own SQL/setup logic and may not be represented as generated Drift tables.

## Backup and restore

`BackupManager` and the backup model under `lib/features/app/` define the export format and restore behavior. Restore may need to close and reopen the active database; use the existing helper reset path rather than retaining a stale connection. Read [Exporting and backing up data](../user_guide/exporting_and_backing_up.md) for user-facing workflows. Do not assume catalog files, preferences, secure-storage secrets, or platform health records are included in a database backup; confirm each payload in the backup implementation.

## Change checklist

For a schema change, update the Drift table and generated files using the repository's generator workflow, add an explicit migration for existing installations, check indexes/foreign keys and any raw SQL, and add focused migration coverage. For a new dependency, wire it in `main.dart` or the owning feature boundary and define its lifecycle. For platform behavior, document and verify each native implementation separately.
