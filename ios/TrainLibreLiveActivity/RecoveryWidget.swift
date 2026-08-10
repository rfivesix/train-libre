import SwiftUI
import WidgetKit

// MARK: - Timeline

@available(iOS 18.0, *)
struct RecoveryEntry: TimelineEntry {
  let date: Date
  let recovery: HomeWidgetRecovery?
}

@available(iOS 18.0, *)
struct RecoveryProvider: TimelineProvider {
  func placeholder(in context: Context) -> RecoveryEntry {
    RecoveryEntry(date: .now, recovery: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (RecoveryEntry) -> Void) {
    let stored = HomeWidgetSnapshot.load()?.recovery
    completion(RecoveryEntry(date: .now, recovery: stored ?? (context.isPreview ? .placeholder : nil)))
  }

  /// One entry, refreshed daily.
  ///
  /// Recovery does change while the app is closed — muscles keep recovering on
  /// the clock — but the state boundaries are 36 to 72 hours out, so a widget
  /// that re-renders once a day cannot be more than a few hours behind, and the
  /// app reloads this timeline whenever a workout is finished. Polling for the
  /// exact hour a muscle crosses from "recovering" to "ready" would spend the
  /// whole daily reload budget on a distinction nobody trains by.
  func getTimeline(in context: Context, completion: @escaping (Timeline<RecoveryEntry>) -> Void) {
    let entry = RecoveryEntry(date: .now, recovery: HomeWidgetSnapshot.load()?.recovery)
    completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(6 * 60 * 60))))
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct RecoveryWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: TrainLibreHomeWidget.kindRecovery,
      provider: RecoveryProvider()
    ) { entry in
      RecoveryWidgetView(recovery: entry.recovery)
        .statsWidgetContainer()
        .widgetURL(URL(string: "trainlibre://analytics/recovery"))
    }
    .configurationDisplayName(Text("widget.recovery.name"))
    .description(Text("widget.recovery.description"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - View

@available(iOS 18.0, *)
struct RecoveryWidgetView: View {
  let recovery: HomeWidgetRecovery?

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  private var palette: StatsPalette {
    StatsPalette(colorScheme: colorScheme, renderingMode: renderingMode)
  }

  private var hasData: Bool {
    guard let recovery else { return false }
    return recovery.hasData && !recovery.states.isEmpty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      StatsHeader(
        title: Text("widget.recovery.name"),
        chip: hasData ? Text("widget.recovery.chip") : nil,
        palette: palette
      )

      Text(headline)
        .font(StatsTheme.headlineFont)
        .foregroundStyle(headlineColor)
        .lineLimit(2)
        .minimumScaleFactor(0.85)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 4)

      Spacer(minLength: 8)

      if hasData, let states = recovery?.states {
        HStack(spacing: StatsTheme.rowSpacing) {
          ForEach(Array(states.enumerated()), id: \.offset) { index, state in
            RecoveryPill(
              state: state,
              palette: palette,
              // Recovering is the state that wants attention, fresh the one
              // that does not. In tinted mode this ordering is the only thing
              // left to tell them apart.
              emphasis: emphasis(forIndex: index, of: states.count)
            )
          }
        }
      } else {
        emptyBody
      }
    }
  }

  private var headline: String {
    guard let recovery, !recovery.headline.isEmpty else { return "" }
    return recovery.headline
  }

  private var headlineColor: Color {
    guard hasData else { return palette.secondaryText }
    return palette.stateColor(recovery?.headlineColorHex)
  }

  private func emphasis(forIndex index: Int, of count: Int) -> Double {
    guard count > 1 else { return 1 }
    return 1 - Double(index) / Double(count - 1)
  }

  /// No workout has been logged yet, so there is nothing to recover from.
  private var emptyBody: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("widget.recovery.empty.body")
        .font(.system(size: 12))
        .foregroundStyle(palette.secondaryText)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      StatsActionPill(
        label: Text("widget.startWorkout"),
        destination: URL(string: "trainlibre://action/start_workout")!,
        palette: palette
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: StatsTheme.pillRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: StatsTheme.pillRadius, style: .continuous)
        .stroke(Color.primary.opacity(0.07), lineWidth: 1)
    )
  }
}

/// One of the three readiness counts — count, label, share.
@available(iOS 18.0, *)
struct RecoveryPill: View {
  let state: HomeWidgetRecoveryState
  let palette: StatsPalette
  let emphasis: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text("\(state.count)")
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(palette.stateColor(state.colorHex))
        .lineLimit(1)

      Text(state.label)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(palette.onSurface)
        .lineLimit(1)
        .minimumScaleFactor(0.7)

      Text("\(state.percent)%")
        .font(.system(size: 12))
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: StatsTheme.pillRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: StatsTheme.pillRadius, style: .continuous)
        .stroke(
          palette.stateBorder(state.colorHex, emphasis: emphasis),
          lineWidth: palette.stateBorderWidth(emphasis: emphasis)
        )
    )
  }
}

// MARK: - Gallery placeholder

@available(iOS 18.0, *)
extension HomeWidgetRecovery {
  /// What the widget gallery shows, and what a widget added before the app has
  /// ever written a snapshot falls back to. A plausible mid-week distribution
  /// rather than an error state.
  static var placeholder: HomeWidgetRecovery {
    HomeWidgetRecovery(
      hasData: true,
      headline: String(localized: "widget.recovery.placeholder.headline"),
      headlineColorHex: "#FF9800",
      states: [
        HomeWidgetRecoveryState(
          state: "recovering",
          label: String(localized: "widget.recovery.state.recovering"),
          count: 6, percent: 46, colorHex: "#FF9800"
        ),
        HomeWidgetRecoveryState(
          state: "ready",
          label: String(localized: "widget.recovery.state.ready"),
          count: 2, percent: 15, colorHex: "#2196F3"
        ),
        HomeWidgetRecoveryState(
          state: "fresh",
          label: String(localized: "widget.recovery.state.fresh"),
          count: 5, percent: 38, colorHex: "#4CAF50"
        ),
      ]
    )
  }
}
