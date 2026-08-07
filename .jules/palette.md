## 2024-05-24 - Missing tooltips on onboarding navigation buttons
**Learning:** Found that custom navigation buttons (like `IconButton.filledTonal`) on the onboarding screen were missing tooltips. This is a common accessibility issue for icon-only buttons. We can easily leverage Flutter's `MaterialLocalizations` to provide native, localized tooltips.
**Action:** When adding custom icon-only navigation buttons, always use `MaterialLocalizations.of(context)` to add standard tooltips (e.g., `previousPageTooltip`, `nextPageTooltip`) without requiring new localization keys.
