## 2026-07-17 - Fix SQL injection in dynamic backup import
**Vulnerability:** The backup import function dynamically interpolated JSON map keys directly into SQL queries as table and column names without validation.
**Learning:** Table and column names cannot be parameterized in typical SQL bindings; if they are derived from external data (like JSON backups), they must be strictly sanitized to prevent SQL injection or malicious schema modifications.
**Prevention:** Always validate dynamically determined table and column names against a strict alphanumeric identifier regex (e.g., `^[a-zA-Z0-9_]+$`) before interpolating them into a raw SQL statement.

## 2026-07-17 - Fix SQL injection in _fetchTable during backup export
**Vulnerability:** The `_fetchTable` function dynamically interpolated the `tableName` parameter directly into a raw SQL query (`SELECT * FROM $tableName`) without validation.
**Learning:** Even internal functions used for exporting data can be vulnerable to SQL injection if they accept string parameters that are directly interpolated into SQL statements, especially for identifiers like table names which cannot be parameterized safely.
**Prevention:** Always sanitize dynamic table names using a strict regex (`^[a-zA-Z0-9_]+$`) before interpolating them into a SQL statement, even if the caller is expected to be safe.
