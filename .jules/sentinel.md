## 2024-05-18 - Prevent SQL Injection in Dynamic Import Queries
**Vulnerability:** SQL Injection in Backup Manager import via untrusted column/table names.
**Learning:** In Dart/Drift, column names and table names cannot be parameterized. When importing data dynamically (e.g. from JSON payloads where keys map to columns), injecting these keys directly into raw SQL strings allows attackers to craft payloads that execute arbitrary SQL commands.
**Prevention:** Always validate dynamically injected identifiers (like table names or JSON keys intended to be columns) against a strict whitelist regular expression, such as `RegExp(r'^[a-zA-Z0-9_]+$')`, before string interpolation into SQL commands.
