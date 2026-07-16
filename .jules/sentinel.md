## 2024-05-24 - [SQL Injection in JSON Backup Import]
**Vulnerability:** SQL Injection via untrusted JSON keys used as dynamic SQL column and table names in backup import.
**Learning:** Even internal import routines (like backups) can be an attack vector if they use untrusted external JSON data keys directly in string interpolation for SQL queries, because column and table names cannot be parameterized.
**Prevention:** Always validate external JSON keys against a strict regex (e.g., `RegExp(r'^[a-zA-Z0-9_]+$')`) before interpolating them as table or column names in raw SQL statements.
