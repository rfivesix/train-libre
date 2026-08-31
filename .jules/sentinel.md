## 2026-07-17 - Fix SQL injection in dynamic backup import
**Vulnerability:** The backup import function dynamically interpolated JSON map keys directly into SQL queries as table and column names without validation.
**Learning:** Table and column names cannot be parameterized in typical SQL bindings; if they are derived from external data (like JSON backups), they must be strictly sanitized to prevent SQL injection or malicious schema modifications.
**Prevention:** Always validate dynamically determined table and column names against a strict alphanumeric identifier regex (e.g., `^[a-zA-Z0-9_]+$`) before interpolating them into a raw SQL statement.

## 2026-07-17 - Fix SQL injection in _fetchTable during backup export
**Vulnerability:** The `_fetchTable` function dynamically interpolated the `tableName` parameter directly into a raw SQL query (`SELECT * FROM $tableName`) without validation.
**Learning:** Even internal functions used for exporting data can be vulnerable to SQL injection if they accept string parameters that are directly interpolated into SQL statements, especially for identifiers like table names which cannot be parameterized safely.
**Prevention:** Always sanitize dynamic table names using a strict regex (`^[a-zA-Z0-9_]+$`) before interpolating them into a SQL statement, even if the caller is expected to be safe.

## 2026-08-28 - Fix SQL injection in the iCloud restore table copy
**Vulnerability:** `_copySnapshotIntoLiveDatabase` in `lib/core/infrastructure/icloud_sync_service.dart` read table names from the attached snapshot's `restore.sqlite_master` and interpolated them into `DELETE FROM main."$table"`, `INSERT INTO main."$table"` and `PRAGMA $schema.table_info("$table")`. The snapshot is a file from the iCloud container, so a tampered database could carry a crafted table name.
**Learning:** `sqlite_master` is only as trustworthy as the file it belongs to. At an import/restore boundary the attached database is external input, not internal state.
**Prevention:** Validate every dynamically resolved identifier against `^[A-Za-z0-9_]+$` before interpolation and skip the table otherwise; the app's own tables are all snake_case, so nothing legitimate is lost.

## 2026-08-28 - Fix SQL injection in drift_database schema utility functions
**Vulnerability:** The `_columnsOf` utility function dynamically interpolated the `table` parameter into `PRAGMA table_info($table);` without validation. `_columnsOf` is indirectly used by public utility functions like `_tableExists` and `_columnExists`.
**Learning:** Even internal utility functions used for schema migrations or validation can be vulnerable to SQL injection if they accept string parameters that are directly interpolated into raw SQL statements (`customSelect`, `customStatement`).
**Prevention:** Always sanitize dynamic table names using a strict regex (`^[a-zA-Z0-9_]+$`) before interpolating them into a raw query or PRAGMA statement, ensuring defense in depth even if callers are currently safe.
