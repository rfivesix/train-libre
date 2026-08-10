import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Single Quick Action Intent & Widget (Lock Screen Circular 1x1)

@available(iOS 18.0, *)
public struct SingleQuickActionConfigIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource { "widget.quickActions.name" }
  public static var description: IntentDescription { "widget.quickActions.intentDescription" }

  public static var parameterSummary: some ParameterSummary {
    Summary {
      \.$action1
    }
  }

  @Parameter(title: "widget.quickActions.slotSingle", default: .scanBarcode)
  var action1: QuickActionSlot1

  public init() {}

  public func resolvedKinds() -> [QuickActionKind] {
    [action1.kind]
  }
}

@available(iOS 18.0, *)
struct SingleQuickActionsProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickActionsEntry {
    QuickActionsEntry(date: .now, kinds: [.scanBarcode], isAiEnabled: true)
  }

  func snapshot(for configuration: SingleQuickActionConfigIntent, in context: Context) async -> QuickActionsEntry {
    entry(for: configuration)
  }

  func timeline(for configuration: SingleQuickActionConfigIntent, in context: Context) async -> Timeline<QuickActionsEntry> {
    Timeline(entries: [entry(for: configuration)], policy: .after(.now.addingTimeInterval(24 * 60 * 60)))
  }

  private func entry(for configuration: SingleQuickActionConfigIntent) -> QuickActionsEntry {
    QuickActionsEntry(
      date: .now,
      kinds: configuration.resolvedKinds(),
      isAiEnabled: HomeWidgetSnapshot.load()?.isAiEnabled ?? false
    )
  }
}

@available(iOS 18.0, *)
struct SingleQuickActionWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: TrainLibreHomeWidget.kindQuickActionsSingle,
      intent: SingleQuickActionConfigIntent.self,
      provider: SingleQuickActionsProvider()
    ) { entry in
      QuickActionsView(entry: entry)
        .widgetURL(entry.kinds.first?.deepLink ?? URL(string: "trainlibre://diary"))
    }
    .configurationDisplayName(Text("widget.quickActions.name"))
    .description(Text("widget.quickActions.description"))
    .supportedFamilies([.accessoryCircular])
    .contentMarginsDisabled()
  }
}

// MARK: - Small Quick Actions Intent & Widget (Home Screen Small 2x2)

@available(iOS 18.0, *)
public struct SmallQuickActionsConfigIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource { "widget.quickActions.name" }
  public static var description: IntentDescription { "widget.quickActions.intentDescription" }

  public static var parameterSummary: some ParameterSummary {
    Summary {
      \.$action1
      \.$action2
    }
  }

  @Parameter(title: "widget.quickActions.slot1", default: .scanBarcode)
  var action1: QuickActionSlot1

  @Parameter(title: "widget.quickActions.slot2", default: .startWorkout)
  var action2: QuickActionSlot2

  public init() {}

  public func resolvedKinds() -> [QuickActionKind] {
    [action1.kind, action2.kind]
  }
}

@available(iOS 18.0, *)
struct SmallQuickActionsProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> QuickActionsEntry {
    QuickActionsEntry(date: .now, kinds: [.scanBarcode, .startWorkout], isAiEnabled: true)
  }

  func snapshot(for configuration: SmallQuickActionsConfigIntent, in context: Context) async -> QuickActionsEntry {
    entry(for: configuration)
  }

  func timeline(for configuration: SmallQuickActionsConfigIntent, in context: Context) async -> Timeline<QuickActionsEntry> {
    Timeline(entries: [entry(for: configuration)], policy: .after(.now.addingTimeInterval(24 * 60 * 60)))
  }

  private func entry(for configuration: SmallQuickActionsConfigIntent) -> QuickActionsEntry {
    QuickActionsEntry(
      date: .now,
      kinds: configuration.resolvedKinds(),
      isAiEnabled: HomeWidgetSnapshot.load()?.isAiEnabled ?? false
    )
  }
}

@available(iOS 18.0, *)
struct SmallQuickActionsWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: TrainLibreHomeWidget.kindQuickActionsSmall,
      intent: SmallQuickActionsConfigIntent.self,
      provider: SmallQuickActionsProvider()
    ) { entry in
      QuickActionsView(entry: entry)
        .widgetURL(entry.kinds.first?.deepLink ?? URL(string: "trainlibre://diary"))
    }
    .configurationDisplayName(Text("widget.quickActions.name"))
    .description(Text("widget.quickActions.description"))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

// MARK: - Medium Quick Actions Intent & Widget (Home Screen Medium 4x2)

@available(iOS 18.0, *)
public struct QuickActionsConfigIntent: WidgetConfigurationIntent {
  public static var title: LocalizedStringResource { "widget.quickActions.name" }
  public static var description: IntentDescription { "widget.quickActions.intentDescription" }

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

  public static let defaultKinds: [QuickActionKind] = [
    .scanBarcode, .startWorkout, .aiMealCapture, .addLiquid,
  ]

  public func resolvedKinds() -> [QuickActionKind] {
    [action1.kind, action2.kind, action3.kind, action4.kind]
  }
}

@available(iOS 18.0, *)
struct QuickActionsEntry: TimelineEntry {
  let date: Date
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

@available(iOS 18.0, *)
struct MediumQuickActionsWidget: Widget {
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
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - Views

@available(iOS 18.0, *)
struct QuickActionsView: View {
  let entry: QuickActionsEntry

  @Environment(\.widgetFamily) private var family

  private var slotCount: Int { family == .systemSmall ? 2 : (family == .accessoryCircular ? 1 : 4) }

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
