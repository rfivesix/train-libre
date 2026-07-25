## 2026-07-06 - Add Tooltips for Accessibility
**Learning:** Adding tooltips to icon-only buttons improves accessibility for screen readers and provides helpful context for users. However, in localized applications, you must verify the existence of the translation key (e.g. `l10n.doneButtonLabel`) in the corresponding `.arb` files before adding it, otherwise it causes a compilation failure. Widespread auto-formatting to add a single tooltip line should be avoided to prevent massive PR noise.
**Action:** Always ensure that icon-only `IconButton` widgets have a `tooltip` property set using the appropriate localization keys, and make targeted edits to maintain a clean diff.

## 2024-05-19 - Adding Tooltips to IconButtons for Accessibility
**Learning:** Icon-only buttons (`IconButton`) require a `tooltip` property to provide a semantic label for screen readers and a visual hover hint, acting as an ARIA-equivalent in Flutter.
**Action:** Always add a `tooltip` property to `IconButton` widgets when they do not have an accompanying text label. When using standard navigation/system buttons, use `MaterialLocalizations.of(context)` properties like `previousPageTooltip` or `nextPageTooltip` to provide standard, automatically localized tooltips.

## 2024-05-19 - Adding Tooltips to IconButtons for Accessibility (Custom Features)
**Learning:** Found a missing tooltip on the primary AI Meal Capture action button. Icon-only buttons mapping to custom features should reuse existing localized strings (e.g., `l10n.aiMealCapture`) if an exact tooltip string isn't available, to ensure users understand the button's function without relying solely on the icon (which might not be universally recognizable).
**Action:** When adding tooltips to custom icon-only actions, scan the localization file for the closest matching feature name if a dedicated tooltip string does not exist.

## 2024-05-20 - Adding Localized Tooltips for Accessibility
**Learning:** Hardcoded tooltips (e.g., `tooltip: "Notizen bearbeiten"`) break localization and can be confusing or inaccessible for users relying on different languages. Using standard ARB keys ensures screen readers and hover states respect the user's locale.
**Action:** Always use localized strings (e.g., `l10n.exerciseNoteTitle`) for `tooltip` properties in `IconButton` widgets instead of hardcoding strings.

## 2026-07-25 - Accessibility Tooltips in Generic Utility Screens
**Learning:** Missing `tooltip` on `IconButton` widgets is a common pattern in generic utility screens like search and selection screens, impacting screen reader capability.
**Action:** Always add localized tooltips to generic IconButtons across the application, especially inside list tiles and search results.
