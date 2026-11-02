## 2024-11-02 - Ensure Tooltips on Custom IconButtons are Excluded from Semantics
**Learning:** When building custom `IconButton` components that rely on an outer `Semantics` widget for their accessible label, wrapping the inner interactive element in a `Tooltip` widget (to support mouse hover text) will cause screen readers to read the label twice unless handled properly.
**Action:** Always set `excludeFromSemantics: true` on the `Tooltip` widget when an encompassing `Semantics` widget already provides the accessible label for an interactive UI component.
