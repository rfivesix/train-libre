## 2024-08-05 - Added Tooltips to IconButtons

**Learning:** When searching for missing properties (e.g., `tooltip`) on multi-line Flutter widgets like `IconButton`, standard single-line `grep` searches are unreliable. Furthermore, when writing custom Python parser scripts to evaluate these widgets, word boundary tokens (`\b`) should be used to avoid incorrectly matching custom wrapper methods like `_compactIconButton`.
**Action:** When acting as Palette in Flutter, ensure you are utilizing robust parenthesis-matching scripts and accounting for word boundaries when auditing widgets for accessibility attributes like `tooltip`.
