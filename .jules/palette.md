## $(date +%Y-%m-%d) - Add Tooltips to Icon-Only Buttons for Better Accessibility
**Learning:** In Flutter, `IconButton` widgets that only display an icon do not inherently provide semantic labels to screen readers or visual hover hints for desktop/web users. This severely limits accessibility and discoverability.
**Action:** When adding or reviewing icon-only buttons, consistently utilize the `tooltip` property (often populated via existing ARB localization strings like `l10n.edit` or `l10n.selectDateTitle`) to ensure elements are semantically identifiable and have visual hover hints.
