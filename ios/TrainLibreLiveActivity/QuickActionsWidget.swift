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
public struct QuickActionsConfigIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource { "widget.quickActions.name" }
  public static var description: IntentDescription { "widget.quickActions.intentDescription" }

  /// Keep this an opaque result type. AppIntents reads the concrete builder
  /// structure while exporting `Metadata.appintents`; erasing it to the
  /// `ParameterSummary` protocol leaves the edit sheet able to display the
  /// fields but prevents their values from being restored for the provider.
  public static var parameterSummary: some ParameterSummary {
    Summary {
      \.$action1
      \.$action2
      \.$action3
      \.$action4
    }
  }

  @Parameter(title: "widget.quickActions.slot1", default: .scanBarcode)
  var action1: QuickActionSlot1

  @Parameter(title: "widget.quickActions.slot2", default: .startWorkout)
  var action2: QuickActionSlot2

  @Parameter(title: "widget.quickActions.slot3", default: .aiMealCapture)
  var action3: QuickActionSlot3

  @Parameter(title: "widget.quickActions.slot4", default: .addLiquid)
  var action4: QuickActionSlot4

  public init() {}

  /// What a freshly added widget shows before the user has configured anything.
  public static let defaultKinds: [QuickActionKind] = [
    .addLiquid, .scanBarcode, .startWorkout, .logSupplement,
  ]

  /// The four configured actions, in slot order.
  ///
  /// Must be called while the intent is live — see `QuickActionsEntry`.
  public func resolvedKinds() -> [QuickActionKind] {
    [action1.kind, action2.kind, action3.kind, action4.kind]
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
        .widgetURL(entry.kinds.first?.deepLink ?? URL(string: "trainlibre://diary"))
    }
    .configurationDisplayName(Text("widget.quickActions.name"))
    .description(Text("widget.quickActions.description"))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
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
    if family == .accessoryCircular {
      if let firstKind = entry.kinds.first {
        Link(destination: firstKind.deepLink ?? URL(string: "trainlibre://diary")!) {
          ZStack {
            AccessoryWidgetBackground()
            Image(systemName: firstKind.systemImage)
              .font(.system(size: 20, weight: .bold))
          }
        }
        .containerBackground(.clear, for: .widget)
      }
    } else if family == .systemSmall {
      VStack(spacing: TGTheme.gridSpacing) {
        ForEach(kinds, id: \.self) { kind in
          QuickActionTile(kind: kind, isAiEnabled: entry.isAiEnabled)
        }
      }
      .padding(12)
      .containerBackground(.fill.tertiary, for: .widget)
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
      .padding(12)
      .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

@available(iOS 18.0, *)
struct QuickActionTile: View {
  let kind: QuickActionKind
  let isAiEnabled: Bool

  @Environment(\.widgetRenderingMode) private var renderingMode

  /// An AI tile placed while AI was on, then switched off in the app.
  private var isDisabled: Bool {
    kind == .aiMealCapture && !isAiEnabled
  }

  var body: some View {
    Link(destination: kind.deepLink ?? URL(string: "trainlibre://diary")!) {
      tileContent
    }
  }

  private var tileContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image(systemName: kind.systemImage)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(renderingMode == .accented ? Color.primary : Color.white)

      Spacer(minLength: 4)

      Text(kind.titleKey)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(renderingMode == .accented ? Color.primary : Color.white)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background {
      if renderingMode == .accented {
        Color.primary.opacity(0.15)
      } else if let gradient = kind.gradient {
        gradient
      } else {
        kind.tint
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .opacity(isDisabled ? 0.4 : 1)
  }
}
