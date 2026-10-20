# Data flow and state lifecycle

Many database-backed screens use reactive repository streams for reads and repository methods for commands. This is a common pattern, not a rule that every feature must use streams: some operations intentionally read a one-time snapshot, call a platform API, or use local widget state. Follow the feature's repository and view model implementation.

```text
screen action → view model/use case → repository → data source / platform
      ↑                                      │
      └── state update ← watched query ← committed database change
```

## Reads and writes

Drift query watches rerun when relevant database tables change. Repository watch methods expose those results to consumers; view models map them into presentation state and notify listeners. For a concrete example, follow diary watch methods from their repository/data source to the screen's view model.

Writes are asynchronous commands through repository APIs. A command may return an identifier, status, or computed result, so do not assume every write is `void` or that all resulting UI state arrives via a stream. A database watch is useful when multiple screens or services can change the same records; a local form may instead retain draft state until save.

## Subscription and widget lifetimes

The owner of a `StreamSubscription` must cancel it when its inputs change or its owner is disposed. When replacing a date- or filter-scoped query, guard against late events from the previous query; cancellation is asynchronous for `StreamSubscription.cancel()`, so the exact sequence and any generation guards should match the implementation. On disposal, cancel owned subscriptions and dispose owned notifiers/controllers. Do not dispose dependencies merely borrowed from Provider.

Provider ownership matters: `ChangeNotifierProvider(create: ...)` owns and disposes the created notifier; `.value` exposes an existing object whose owner is elsewhere. `HomeWidgetSyncService`, for example, is created by the root provider and its registered provider disposer calls `dispose()`.

## Async UI work

Use explicit loading/error/result state for operations that outlive a synchronous frame. A boolean guard can prevent duplicate submissions when the UI disables a control while work is active, but it is not itself cancellation and does not prevent stale results from replacing newer input. Search screens should invalidate or identify requests when queries change; cancellation support depends on the underlying operation.

When implementing an async callback, consider: whether the widget/view model may have been disposed before completion; whether a newer request supersedes it; whether errors reach user-visible state; and whether platform calls can be interrupted. Check `mounted` before widget context/state updates after an await, and use a request generation/token when ordering matters.

## Where to trace behavior

- Feature-specific repositories and data sources: `lib/features/*/data/`.
- View models and screens: `lib/features/*/application/` and `presentation/` (some features use different names/layouts).
- Shared database/watch implementation: `lib/data/drift_database.dart` and `lib/core/infrastructure/`.
- Root dependency ownership: `lib/main.dart`.

The [Home-screen Widgets guide](ios_home_screen_widgets.md) describes the separate snapshot publication path. Product rules belong in [Feature Documentation](../features/overview.md).
