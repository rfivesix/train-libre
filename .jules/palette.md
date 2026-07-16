## 2026-07-06 - Add Tooltips for Accessibility
**Learning:** Adding tooltips to icon-only buttons improves accessibility for screen readers and provides helpful context for users. However, in localized applications, you must verify the existence of the translation key (e.g. `l10n.doneButtonLabel`) in the corresponding `.arb` files before adding it, otherwise it causes a compilation failure. Widespread auto-formatting to add a single tooltip line should be avoided to prevent massive PR noise.
**Action:** Always ensure that icon-only `IconButton` widgets have a `tooltip` property set using the appropriate localization keys, and make targeted edits to maintain a clean diff.

## 2025-02-12 - App-wide Missing Icon Tooltips
**Learning:** Across the Flutter app, many generic navigational or action icon-only buttons (like `IconButton(icon: Icon(LucideIcons.arrow_left))`) are missing tooltips, leading to poor screen reader experiences.
**Action:** Always provide tooltips for icon-only buttons in Flutter. Use built-in system translations via `MaterialLocalizations.of(context)` (e.g., `closeButtonTooltip`, `backButtonTooltip`, `previousPageTooltip`, `nextPageTooltip`) to avoid cluttering local ARB files for common actions.
