## 2024-11-03 - Dynamic Tooltips for Stateful IconButtons
**Learning:** Hardcoding static tooltips (like "Edit") on `IconButton`s that toggle state and icons (e.g., between "Edit" and "Cancel") creates accessibility confusion for screen readers, as the announced action no longer matches the button's actual function.
**Action:** When implementing an `IconButton` that changes its icon based on state, always ensure the `tooltip` property uses a ternary operator to dynamically match the current action (e.g., `isEditing ? l10n.cancel : l10n.edit`).
