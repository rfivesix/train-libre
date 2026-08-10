import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

/// Which day the widget shows before the diary's 03:00 rollover.
@available(iOS 18.0, *)
enum WidgetDayMode: String, AppEnum {
  case followApp
  case calendarDay

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "widget.todayGlance.dayMode.title")
  }

  static var caseDisplayRepresentations: [WidgetDayMode: DisplayRepresentation] {
    [
      .followApp: DisplayRepresentation(
        title: "widget.todayGlance.dayMode.followApp",
        subtitle: "widget.todayGlance.dayMode.followApp.subtitle"
      ),
      .calendarDay: DisplayRepresentation(
        title: "widget.todayGlance.dayMode.calendarDay",
        subtitle: "widget.todayGlance.dayMode.calendarDay.subtitle"
      ),
    ]
  }
}

@available(iOS 18.0, *)
struct TodayGlanceConfigIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "widget.todayGlance.name" }
  static var description: IntentDescription { "widget.todayGlance.description" }

  @Parameter(title: "widget.todayGlance.dayMode.title", default: .followApp)
  var dayMode: WidgetDayMode

  /// The effective rollover hour for the configured mode.
  ///
  /// `followApp` uses whatever the app reports rather than a hardcoded 3, so
  /// the two cannot drift apart if the diary rule ever changes.
  func rolloverHour(from snapshot: HomeWidgetSnapshot?) -> Int {
    switch dayMode {
    case .followApp:
      return snapshot?.rolloverHour ?? 3
    case .calendarDay:
      return 0
    }
  }
}

// MARK: - Timeline

@available(iOS 18.0, *)
struct TodayGlanceEntry: TimelineEntry {
  let date: Date
  let snapshot: HomeWidgetSnapshot?
}

@available(iOS 18.0, *)
struct TodayGlanceProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> TodayGlanceEntry {
    TodayGlanceEntry(date: .now, snapshot: HomeWidgetSnapshot.placeholder)
  }

  func snapshot(
    for configuration: TodayGlanceConfigIntent,
    in context: Context
  ) async -> TodayGlanceEntry {
    let stored = HomeWidgetSnapshot.load()
    return TodayGlanceEntry(
      date: .now,
      snapshot: stored ?? (context.isPreview ? .placeholder : nil)
    )
  }

  /// Two entries and nothing more.
  ///
  /// Nutrition data cannot change while the app is closed — it only ever enters
  /// through app UI, and the app reloads these timelines on every write. The one
  /// change that happens unattended is the day rolling over, so that is the one
  /// scheduled entry. Polling would spend the widget's daily reload budget on
  /// data that provably did not change.
  func timeline(
    for configuration: TodayGlanceConfigIntent,
    in context: Context
  ) async -> Timeline<TodayGlanceEntry> {
    let stored = HomeWidgetSnapshot.load()
    let rolloverHour = configuration.rolloverHour(from: stored)
    let now = Date.now

    let currentDayKey = HomeWidgetDay.dayKey(for: now, rolloverHour: rolloverHour)
    let nextChange = HomeWidgetDay.nextRollover(after: now, rolloverHour: rolloverHour)
    let nextDayKey = HomeWidgetDay.dayKey(
      for: nextChange.addingTimeInterval(60),
      rolloverHour: rolloverHour
    )

    let entries = [
      TodayGlanceEntry(date: now, snapshot: resolve(stored, for: currentDayKey)),
      TodayGlanceEntry(date: nextChange, snapshot: resolve(stored, for: nextDayKey)),
    ]

    return Timeline(
      entries: entries,
      policy: .after(nextChange.addingTimeInterval(60))
    )
  }

  /// A snapshot written for a different day is not stale data to be shown — it
  /// is a day that has ended. Nothing can have been logged for the new day
  /// without the app running, so zero against the last known targets is the
  /// correct answer, not a guess.
  private func resolve(
    _ stored: HomeWidgetSnapshot?,
    for dayKey: String
  ) -> HomeWidgetSnapshot? {
    guard let stored else { return nil }
    return stored.logicalDayKey == dayKey ? stored : stored.zeroed(forDayKey: dayKey)
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct TodayGlanceWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: TrainLibreHomeWidget.kindTodayGlance,
      intent: TodayGlanceConfigIntent.self,
      provider: TodayGlanceProvider()
    ) { entry in
      TodayGlanceGrid(snapshot: entry.snapshot)
        // Own padding rather than the system content margins: the default
        // inset is tuned for a single headline, and eats roughly a third of the
        // height a three-row grid needs.
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "trainlibre://diary"))
    }
    .configurationDisplayName(Text("widget.todayGlance.name"))
    .description(Text("widget.todayGlance.description"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - Gallery placeholder

@available(iOS 18.0, *)
extension HomeWidgetSnapshot {
  /// Shown in the widget gallery and while the app has never written a
  /// snapshot. Uses the app's default goals so the preview reads as a real,
  /// half-finished day rather than as an error state.
  static var placeholder: HomeWidgetSnapshot {
    HomeWidgetSnapshot(
      schemaVersion: HomeWidgetSnapshot.currentSchemaVersion,
      generatedAtEpochMs: Date.now.timeIntervalSince1970 * 1000,
      logicalDayKey: HomeWidgetDay.dayKey(for: .now, rolloverHour: 3),
      rolloverHour: 3,
      isAiEnabled: true,
      tiles: [
        HomeWidgetTile(slot: "calories", label: "Kalorien", unit: "kcal",
                       value: 1234, target: 2000, colorHex: "#FF9800"),
        HomeWidgetTile(slot: "water", label: "Wasser", unit: "ml",
                       value: 1500, target: 2500, colorHex: "#2196F3"),
        HomeWidgetTile(slot: "extra", label: "Ballaststoffe", unit: "g",
                       value: 12, target: 30, colorHex: "#8D6E63"),
        HomeWidgetTile(slot: "protein", label: "Protein", unit: "g",
                       value: 98, target: 150, colorHex: "#E5253A"),
        HomeWidgetTile(slot: "carbs", label: "Kohlenhydrate", unit: "g",
                       value: 180, target: 250, colorHex: "#66BB6A"),
        HomeWidgetTile(slot: "fat", label: "Fett", unit: "g",
                       value: 55, target: 80, colorHex: "#BA68C8"),
      ]
    )
  }
}
