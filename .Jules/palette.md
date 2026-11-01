## 2026-11-01 - [Interactive Custom Action Icon Buttons missing Tooltip]
**Learning:** In `CloudChatTurnView`, custom action icons use `InkWell` wrapped in `Semantics(label: ...)` for screen readers. However, they lack a visual hover tooltip for desktop/web users.
**Action:** When creating custom icon buttons with `InkWell` and `Semantics`, wrap them in a `Tooltip` with `excludeFromSemantics: true` to provide visual hover text without duplicating screen reader announcements.
