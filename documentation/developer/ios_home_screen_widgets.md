# Home-screen widgets (iOS and Android)

The Flutter app builds a `HomeWidgetSnapshot` in `lib/features/home_widgets/` and sends it over `trainlibre.widgets/home_screen`. Native code stores and renders that snapshot; widgets do not query the Drift database directly.

```text
repositories / health aggregation
       ↓
HomeWidgetSyncService → snapshot builder → HomeWidgetChannel
       ↓                                      ↓
 iOS App Group bridge                  Android SharedPreferences bridge
       ↓                                      ↓
 WidgetKit timelines                  Glance / AppWidget refresh
```

## Snapshot and refresh

`HomeWidgetSnapshot.currentSchemaVersion` is **2**. The JSON contains the logical diary day and rollover hour, configured nutrition tiles, and optional recovery, steps, measurement, and last-workout sections. The model comments specify that nutrition payloads contain aggregate totals and targets rather than food names or entry-level records. The Dart model and native Swift/Kotlin readers must evolve together; preserve decoding of older payloads when changing the format.

`HomeWidgetSyncService` coalesces refresh requests with a 500 ms debounce and prevents overlapping refreshes by scheduling a rerun. It reads current diary values through repository watches, builds a snapshot, and writes it through `HomeWidgetChannel`. Statistics sections are cached for up to 15 minutes and can be invalidated when affected. The app/native bridge requests platform widget refreshes after writes. OS scheduling still controls when a widget is actually rendered; do not promise an exact refresh time.

The diary logical-day rollover is 03:00 and is included in the snapshot so native code can apply the same boundary. Each widget provider defines its own timeline policy; inspect the relevant provider before asserting a shared polling interval or reload budget.

## Platform bridge and storage

| Platform | Bridge and storage | Rendering code |
| --- | --- | --- |
| iOS | `ios/LiveActivity/HomeWidgetBridge.swift`; shared container access and decoding in `HomeWidgetShared.swift` | WidgetKit extension in `ios/TrainLibreLiveActivity/` |
| Android | `android/app/src/main/kotlin/com/rfivesix/trainlibre/widgets/HomeWidgetBridge.kt`; snapshot store in `widgets/snapshot/` | Glance/AppWidget providers, renderers, configuration activities, and `tiles/` in that package |

The channel implementation also handles shared image files used by the last-workout presentation. Check `HomeWidgetChannel` and both native bridges for supported method names, error handling, and storage keys. Android's Quick Settings tile is a separate native surface and should not be described as an iOS feature.

## Deep links and configuration

Widget actions are parsed in `lib/features/home_widgets/home_widget_deep_link.dart` and routed by app navigation. Native widget configuration is platform-specific: iOS uses WidgetKit configuration intents, while Android uses configuration activities and widget preferences. When changing an action or configuration value, update the Dart parser, native producer/consumer, and focused routing tests together.

## Change checklist

1. Update the Dart snapshot model/builder and serialization tests.
2. Update Swift and Kotlin decoding/rendering for the same field, with a safe default for older snapshots where appropriate.
3. Check the method-channel method and file payload on both native bridges.
4. Verify refresh invalidation paths, deep links, and each provider's timeline policy.
5. Update platform localization resources if gallery/configuration text changes.

Useful coverage includes tests under `test/features/home_widgets/` and `ios/RunnerTests/`. These tests corroborate the implementation; the source and native project configuration remain authoritative.
