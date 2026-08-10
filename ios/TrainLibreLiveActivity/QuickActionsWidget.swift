import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

/// Four slots regardless of family.
///
/// A widget cannot vary its parameter list by `WidgetFamily` — there is no API
/// to condition a `ParameterSummary` on the size the user picked — so the small
/// widget shows all four slots in its configuration sheet and renders the first
/// two. The alternative, two separate widgets, would put "Schnellzugriff (2)"
/// and "Schnellzugriff (4)" next to each other in the gallery, which is worse.
/// The parameter titles say so instead.
@available(iOS 18.0, *)
struct QuickActionsConfigIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "widget.quickActions.name" }
  static var description: IntentDescription { "widget.quickActions.intentDescription" }

  @Parameter(title: "widget.quickActions.slot1", default: .addLiquid)
  var action1: QuickActionKind

  @Parameter(title: "widget.quickActions.slot2", default: .scanBarcode)
  var action2: QuickActionKind

  @Parameter(title: "widget.quickActions.slot3", default: .startWorkout)
  var action3: QuickActionKind

  @Parameter(title: "widget.quickActions.slot4", default: .logSupplement)
  var action4: QuickActionKind

  /// What a freshly added widget shows before the user has configured anything.
  static let defaultKinds: [QuickActionKind] = [
    .addLiquid, .scanBarcode, .startWorkout, .logSupplement,
  ]

  /// The four configured actions, in slot order.
  ///
  /// Must be called while the intent is live — see `QuickActionsEntry`.
  func resolvedKinds() -> [QuickActionKind] {
    [action1, action2, action3, action4]
  }
}

// MARK: - Timeline

/// Holds the **resolved** actions, not the configuration intent.
///
/// Storing the intent here and reading its `@Parameter`s from the view does not
/// work: WidgetKit archives timeline entries and replays them later, and the
/// property wrappers do not survive that round trip — every tile silently fell
/// back to its default no matter what the user picked. The configuration is
/// therefore read once, while the intent is still live, and only plain values
/// travel into the entry.
@available(iOS 18.0, *)
struct QuickActionsEntry: TimelineEntry {
  let date: Date
  /// Always four, in slot order. The small family renders the first two.
  let kinds: [QuickActionKind]
  let isAiEnabled: Bool
}

@available(iOS 18.0, *)
struct QuickActionsProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickActionsEntry {
    QuickActionsEntry(
      date: .now,
      kinds: QuickActionsConfigIntent.defaultKinds,
      isAiEnabled: true
    )
  }

  func snapshot(
    for configuration: QuickActionsConfigIntent,
    in context: Context
  ) async -> QuickActionsEntry {
    entry(for: configuration)
  }

  /// Nothing here changes on a schedule — the content depends only on the
  /// configuration and on whether AI is enabled.
  ///
  /// The policy is still time-based rather than `.never`, because `.never`
  /// means "the app must tell WidgetKit when to reload" and a configuration
  /// change is not such a signal: a widget whose actions had been re-picked
  /// kept rendering the previous ones indefinitely. A daily tick costs one
  /// reload out of the ~40–70 daily budget and guarantees the widget cannot
  /// stay stranded on a stale configuration.
  func timeline(
    for configuration: QuickActionsConfigIntent,
    in context: Context
  ) async -> Timeline<QuickActionsEntry> {
    Timeline(
      entries: [entry(for: configuration)],
      policy: .after(.now.addingTimeInterval(24 * 60 * 60))
    )
  }

  private func entry(for configuration: QuickActionsConfigIntent) -> QuickActionsEntry {
    let kinds = configuration.resolvedKinds()
    return QuickActionsEntry(
      date: .now,
      kinds: kinds,
      isAiEnabled: HomeWidgetSnapshot.load()?.isAiEnabled ?? false
    )
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct QuickActionsWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: TrainLibreHomeWidget.kindQuickActions,
      intent: QuickActionsConfigIntent.self,
      provider: QuickActionsProvider()
    ) { entry in
      QuickActionsView(entry: entry)
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName(Text("widget.quickActions.name"))
    .description(Text("widget.quickActions.description"))
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - Views

@available(iOS 18.0, *)
struct QuickActionsView: View {
  let entry: QuickActionsEntry

  @Environment(\.widgetFamily) private var family

  private var slotCount: Int { family == .systemSmall ? 2 : 4 }

  /// The entry always carries four; the small family shows the first two.
  private var kinds: [QuickActionKind] {
    Array(entry.kinds.prefix(slotCount))
  }

  var body: some View {
    if family == .systemSmall {
      VStack(spacing: TGTheme.gridSpacing) {
        ForEach(Array(kinds.enumerated()), id: \.offset) { _, kind in
          QuickActionTile(kind: kind, isAiEnabled: entry.isAiEnabled)
        }
      }
    } else {
      VStack(spacing: TGTheme.gridSpacing) {
        HStack(spacing: TGTheme.gridSpacing) {
          QuickActionTile(kind: kinds[0], isAiEnabled: entry.isAiEnabled)
          QuickActionTile(kind: kinds[1], isAiEnabled: entry.isAiEnabled)
        }
        HStack(spacing: TGTheme.gridSpacing) {
          QuickActionTile(kind: kinds[2], isAiEnabled: entry.isAiEnabled)
          QuickActionTile(kind: kinds[3], isAiEnabled: entry.isAiEnabled)
        }
      }
    }
  }
}

@available(iOS 18.0, *)
struct QuickActionTile: View {
  let kind: QuickActionKind
  let isAiEnabled: Bool

  /// An AI tile placed while AI was on, then switched off in the app.
  private var isDisabled: Bool {
    kind == .aiMealCapture && !isAiEnabled
  }

  var body: some View {
    // `Link`, not `Button(intent:)`. A widget button never fired here — the tap
    // is consumed without the intent's `perform()` ever running, so the app was
    // never launched. `Link` is handled by SpringBoard itself and works, and on
    // the iOS 18 floor it works in `systemSmall` too, despite the long-standing
    // "small widgets only support widgetURL" rule. Verified on both sizes.
    Link(destination: kind.deepLink ?? URL(string: "trainlibre://diary")!) {
      tileContent
    }
  }

  private var tileContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: kind.systemImage)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.white)

      Spacer(minLength: 4)

      Text(kind.titleKey)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.white)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background {
      if let gradient = kind.gradient {
        gradient
      } else {
        kind.tint
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .opacity(isDisabled ? 0.4 : 1)
  }
}
