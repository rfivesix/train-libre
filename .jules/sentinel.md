## 2026-07-17 - Fix SQL injection in dynamic backup import
**Vulnerability:** The backup import function dynamically interpolated JSON map keys directly into SQL queries as table and column names without validation.
**Learning:** Table and column names cannot be parameterized in typical SQL bindings; if they are derived from external data (like JSON backups), they must be strictly sanitized to prevent SQL injection or malicious schema modifications.
**Prevention:** Always validate dynamically determined table and column names against a strict alphanumeric identifier regex (e.g., `^[a-zA-Z0-9_]+$`) before interpolating them into a raw SQL statement.

## 2026-07-17 - Fix SQL injection in _fetchTable during backup export
**Vulnerability:** The `_fetchTable` function dynamically interpolated the `tableName` parameter directly into a raw SQL query (`SELECT * FROM $tableName`) without validation.
**Learning:** Even internal functions used for exporting data can be vulnerable to SQL injection if they accept string parameters that are directly interpolated into SQL statements, especially for identifiers like table names which cannot be parameterized safely.
**Prevention:** Always sanitize dynamic table names using a strict regex (`^[a-zA-Z0-9_]+$`) before interpolating them into a SQL statement, even if the caller is expected to be safe.
## 2023-10-27 - SQL Injection in iCloud Sync via PRAGMA statements
**Vulnerability:** SQL Injection in iCloud Sync via unparameterized PRAGMA statements.
**Learning:** Table and schema names were read from a potentially untrusted source (an attached backup SQLite database) and directly interpolated into queries like `DELETE FROM main."$table"` and `PRAGMA $schema.table_info("$table")`. Since SQLite PRAGMA statements and object identifiers cannot be parameterized, this left the application vulnerable to injection if a malicious backup file was synced and restored.
**Prevention:** When dynamically constructing SQL statements using external or untrusted strings (such as JSON payload keys or table names during imports/syncs), always validate them using a strict allowlist regex (e.g., `RegExp(r'^[a-zA-Z0-9_]+$')`) before interpolation to prevent SQL injection. Keys/column/table names cannot be parameterized like standard values. Safely skip invalid entries rather than failing the entire process.
