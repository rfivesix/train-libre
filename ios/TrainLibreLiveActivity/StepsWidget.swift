import SwiftUI
import WidgetKit

// MARK: - Timeline

@available(iOS 18.0, *)
struct StepsEntry: TimelineEntry {
  let date: Date
  let steps: HomeWidgetSteps?
}

@available(iOS 18.0, *)
struct StepsProvider: TimelineProvider {
  func placeholder(in context: Context) -> StepsEntry {
    StepsEntry(date: .now, steps: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
    let stored = HomeWidgetSnapshot.load()?.steps
    completion(StepsEntry(date: .now, steps: stored ?? (context.isPreview ? .placeholder : nil)))
  }

  /// Refreshed every couple of hours, and immediately whenever the app syncs.
  ///
  /// Steps are the one section that genuinely moves while the app is closed:
  /// they are read from HealthKit, which keeps counting. The extension cannot
  /// query HealthKit itself here — the app owns that permission and the
  /// provider filtering — so the best it can do is re-read whatever the app
  /// last published, and let the app's own sync drive the real updates.
  func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
    let entry = StepsEntry(date: .now, steps: HomeWidgetSnapshot.load()?.steps)
    completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(2 * 60 * 60))))
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct StepsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: TrainLibreHomeWidget.kindSteps, provider: StepsProvider()) { entry in
      StepsWidgetView(steps: entry.steps)
        .statsWidgetContainer()
        .widgetURL(URL(string: "trainlibre://steps"))
    }
    .configurationDisplayName(Text("widget.steps.name"))
    .description(Text("widget.steps.description"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - View

@available(iOS 18.0, *)
struct StepsWidgetView: View {
  let steps: HomeWidgetSteps?

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  private var palette: StatsPalette {
    StatsPalette(colorScheme: colorScheme, renderingMode: renderingMode)
  }

  private var hasAccess: Bool { steps?.isTrackingEnabled ?? false }

  /// The card's 2/5 : 3/5 column split, from the design document. The count is
  /// the headline of this widget and gets its share before the chart does.
  private static let totalsWidthShare: CGFloat = 0.38

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      StatsHeader(
        title: Text("widget.steps.name"),
        chip: hasAccess ? Text("widget.steps.chip") : nil,
        palette: palette
      )

      Spacer(minLength: 8)

      if let steps, hasAccess {
        // Split by measured width rather than by layout priority. Both columns
        // are flexible — the chart has no intrinsic width at all — and letting
        // the HStack arbitrate collapsed the count to nothing in the first cut.
        GeometryReader { geo in
          HStack(alignment: .bottom, spacing: StatsTheme.rowSpacing) {
            totals(for: steps)
              .frame(width: max(geo.size.width * Self.totalsWidthShare, 0), alignment: .leading)

            StepsBarChart(steps: steps, palette: palette)
          }
          .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 92)
      } else {
        permissionBody
      }
    }
  }

  private func totals(for steps: HomeWidgetSteps) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(StatsFormat.grouped(steps.todaySteps))
        .font(StatsTheme.bigNumberFont)
        .kerning(-0.5)
        .foregroundStyle(palette.accent)
        .lineLimit(1)
        .minimumScaleFactor(0.6)

      subtitle(for: steps)
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(palette.accent)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
  }

  /// The share of the goal when there is one, and a plain "Today" otherwise —
  /// a percentage of nothing would be a worse label than no percentage.
  private func subtitle(for steps: HomeWidgetSteps) -> Text {
    guard steps.dailyGoal > 0 else { return Text("widget.steps.today") }
    let percent = Int((Double(steps.todaySteps) / Double(steps.dailyGoal) * 100).rounded())
    return Text("widget.steps.percentOfGoal \(percent)")
  }

  /// Step tracking is off, or HealthKit access was never granted. The widget
  /// cannot ask for it — only the app can — so it says where to.
  private var permissionBody: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 12) {
        Image(systemName: "lock.fill")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(palette.accent)
          .frame(width: 44, height: 44)
          .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

        VStack(alignment: .leading, spacing: 3) {
          Text("widget.steps.noAccess.title")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(palette.onSurface)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
          Text("widget.steps.noAccess.body")
            .font(.system(size: 12))
            .foregroundStyle(palette.secondaryText)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Text("widget.steps.noAccess.cta")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(palette.accent)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(palette.chipBackground, in: Capsule())
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// The seven-day chart, a direct port of `StatisticsStepsCard._buildBarChart`
/// in its seven-day configuration.
@available(iOS 18.0, *)
struct StepsBarChart: View {
  let steps: HomeWidgetSteps
  let palette: StatsPalette

  /// Room above the bars for the goal-met badge.
  private let badgeHeight: CGFloat = 12
  /// Room below for the weekday initial.
  private let labelHeight: CGFloat = 14
  /// The gutter the goal's axis label sits in.
  private let axisInset: CGFloat = 34
  private let barWidth: CGFloat = 14

  private var maximum: Int { steps.chartMaximum }
  private var todayKey: String? { steps.days.last?.dayKey }

  var body: some View {
    GeometryReader { geo in
      let plotHeight = max(geo.size.height - badgeHeight - labelHeight, 1)
      let goalRatio = min(max(Double(steps.dailyGoal) / Double(maximum), 0), 1)
      let goalY = badgeHeight + plotHeight * (1 - goalRatio)

      ZStack(alignment: .topLeading) {
        if steps.dailyGoal > 0 {
          DashedLine()
            .stroke(palette.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
            .padding(.leading, axisInset)
            .offset(y: goalY)

          Text(StatsFormat.compactAxis(steps.dailyGoal))
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(palette.secondaryText)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(palette.secondarySurface.opacity(0.85), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .offset(y: max(goalY - 7, 0))
        }

        HStack(spacing: 0) {
          ForEach(steps.days, id: \.dayKey) { day in
            bar(day, plotHeight: plotHeight)
          }
        }
        .padding(.leading, axisInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }

  private func bar(_ day: HomeWidgetStepsDay, plotHeight: CGFloat) -> some View {
    let ratio = min(max(Double(day.steps) / Double(maximum), 0), 1)
    let metGoal = steps.dailyGoal > 0 && day.steps >= steps.dailyGoal
    let isToday = day.dayKey == todayKey

    return VStack(spacing: 0) {
      ZStack {
        if metGoal {
          RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(palette.accent)
            .frame(width: 12, height: 12)
            .overlay(
              Image(systemName: "checkmark")
                .font(.system(size: 7, weight: .heavy))
                .foregroundStyle(palette.onAccent)
            )
        }
      }
      .frame(height: badgeHeight)

      VStack {
        Spacer(minLength: 0)
        if day.steps <= 0 {
          // A day the phone spent in a drawer is not the same as a day with no
          // data at all: the app draws a flat 4pt marker rather than dropping
          // the bar, so the week keeps its seven slots.
          Capsule()
            .fill(Color.secondary.opacity(0.35))
            .frame(width: 10, height: 4)
        } else {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(palette.accent)
            .frame(width: barWidth, height: max(plotHeight * ratio, 4))
        }
      }
      .frame(height: plotHeight)

      Text(StatsFormat.weekdayInitial(StatsFormat.day(fromKey: day.dayKey) ?? .now))
        .font(.system(size: 10, weight: isToday ? .bold : .medium))
        .foregroundStyle(isToday ? palette.onSurface : palette.secondaryText)
        .frame(height: labelHeight, alignment: .top)
    }
    .frame(maxWidth: .infinity)
  }
}

/// A one-pixel horizontal rule, so `StrokeStyle`'s dash pattern can draw it.
struct DashedLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}

// MARK: - Gallery placeholder

@available(iOS 18.0, *)
extension HomeWidgetSteps {
  static var placeholder: HomeWidgetSteps {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let counts = [9100, 10400, 7800, 11200, 6500, 12300, 8432]
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"

    return HomeWidgetSteps(
      isTrackingEnabled: true,
      todaySteps: 8432,
      dailyGoal: 10000,
      days: counts.enumerated().map { index, steps in
        let date = calendar.date(byAdding: .day, value: index - 6, to: today) ?? today
        return HomeWidgetStepsDay(dayKey: formatter.string(from: date), steps: steps)
      }
    )
  }
}
