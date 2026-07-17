## 2024-05-19 - Adding Tooltips to IconButtons for Accessibility
**Learning:** Icon-only buttons (`IconButton`) require a `tooltip` property to provide a semantic label for screen readers and a visual hover hint, acting as an ARIA-equivalent in Flutter.
**Action:** Always add a `tooltip` property to `IconButton` widgets when they do not have an accompanying text label. When using standard navigation/system buttons, use `MaterialLocalizations.of(context)` properties like `previousPageTooltip` or `nextPageTooltip` to provide standard, automatically localized tooltips.
