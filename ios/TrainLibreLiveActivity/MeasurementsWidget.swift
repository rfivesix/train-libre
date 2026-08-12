import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Configuration

/// The five timeframes `MeasurementsScreen` offers, in its order.
///
/// Raw values are the keys the deep link carries — kept in lockstep with
/// `HomeWidgetMeasurementPeriod` in `lib/features/home_widgets/home_widget_deep_link.dart`.
@available(iOS 18.0, *)
enum MeasurementPeriod: String, AppEnum {
  case sevenDays = "7d"
  case oneMonth = "1m"
  case threeMonths = "3m"
  case sixMonths = "6m"
  case max = "max"

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "widget.measurements.period.title")
  }

  static var caseDisplayRepresentations: [MeasurementPeriod: DisplayRepresentation] {
    [
      .sevenDays: DisplayRepresentation(title: "widget.measurements.period.7d"),
      .oneMonth: DisplayRepresentation(title: "widget.measurements.period.1m"),
      .threeMonths: DisplayRepresentation(title: "widget.measurements.period.3m"),
      .sixMonths: DisplayRepresentation(title: "widget.measurements.period.6m"),
      .max: DisplayRepresentation(title: "widget.measurements.period.max"),
    ]
  }

  /// Nil for `.max`, which is "everything there is".
  var days: Int? {
    switch self {
    case .sevenDays: return 7
    case .oneMonth: return 30
    case .threeMonths: return 90
    case .sixMonths: return 180
    case .max: return nil
    }
  }

  var chipText: LocalizedStringKey {
    switch self {
    case .sevenDays: return "widget.measurements.period.7d"
    case .oneMonth: return "widget.measurements.period.1m"
    case .threeMonths: return "widget.measurements.period.3m"
    case .sixMonths: return "widget.measurements.period.6m"
    case .max: return "widget.measurements.period.max"
    }
  }
}

/// A metric the user can pick in the widget's edit sheet.
///
/// An `AppEntity` rather than an `AppEnum` because the list is whatever the user
/// has actually measured — the app publishes it with the snapshot, and a fixed
/// enum would either miss metrics or offer ones nobody records.
@available(iOS 18.0, *)
struct MeasurementMetricEntity: AppEntity {
  let id: String
  let name: String

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "widget.measurements.metric.title")
  }

  static var defaultQuery = MeasurementMetricQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  /// What the sheet offers before the app has ever written a snapshot, so a
  /// freshly installed app still has something to configure.
  static let fallback = MeasurementMetricEntity(
    id: "weight",
    name: String(localized: "widget.measurements.metric.weight")
  )
}

@available(iOS 18.0, *)
struct MeasurementMetricQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [MeasurementMetricEntity] {
    let available = Self.available()
    return identifiers.compactMap { id in
      available.first { $0.id == id }
        // A metric the user configured and has since stopped recording keeps
        // its slot rather than silently snapping back to weight — the empty
        // state explains itself better than a different metric would.
        ?? (id == MeasurementMetricEntity.fallback.id ? .fallback : nil)
    }
  }

  func suggestedEntities() async throws -> [MeasurementMetricEntity] {
    let available = Self.available()
    return available.isEmpty ? [.fallback] : available
  }

  func defaultResult() async -> MeasurementMetricEntity? {
    try? await suggestedEntities().first
  }

  static func available() -> [MeasurementMetricEntity] {
    (HomeWidgetSnapshot.load()?.measurements ?? []).map {
      MeasurementMetricEntity(id: $0.id, name: $0.name)
    }
  }
}

@available(iOS 18.0, *)
struct MeasurementsConfigIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "widget.measurements.name" }
  static var description: IntentDescription { "widget.measurements.description" }

  /// Opaque on purpose — see the note in `QuickActionsConfigIntent`: erasing it
  /// to `ParameterSummary` leaves the sheet able to show the fields but stops
  /// their values from reaching the provider.
  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$metric
      \.$period
    }
  }

  @Parameter(title: "widget.measurements.metric.title")
  var metric: MeasurementMetricEntity?

  @Parameter(title: "widget.measurements.period.title", default: .oneMonth)
  var period: MeasurementPeriod

  init() {}
}

// MARK: - Timeline

@available(iOS 18.0, *)
struct MeasurementsEntry: TimelineEntry {
  let date: Date
  /// Nil when the configured metric no longer exists in the snapshot.
  let metric: HomeWidgetMeasurementMetric?
  /// Kept even when `metric` is nil, so the empty state can name what is missing.
  let metricName: String
  let period: MeasurementPeriod
}

@available(iOS 18.0, *)
struct MeasurementsProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> MeasurementsEntry {
    MeasurementsEntry(
      date: .now,
      metric: .placeholder,
      metricName: HomeWidgetMeasurementMetric.placeholder.name,
      period: .oneMonth
    )
  }

  func snapshot(
    for configuration: MeasurementsConfigIntent,
    in context: Context
  ) async -> MeasurementsEntry {
    entry(for: configuration, allowPlaceholder: context.isPreview)
  }

  /// Measurements only ever change through app UI, so like the diary grid this
  /// needs no polling — the daily tick is there so a configuration change can
  /// never leave the widget stranded on the previous metric.
  func timeline(
    for configuration: MeasurementsConfigIntent,
    in context: Context
  ) async -> Timeline<MeasurementsEntry> {
    Timeline(
      entries: [entry(for: configuration, allowPlaceholder: false)],
      policy: .after(.now.addingTimeInterval(24 * 60 * 60))
    )
  }

  private func entry(
    for configuration: MeasurementsConfigIntent,
    allowPlaceholder: Bool
  ) -> MeasurementsEntry {
    let all = HomeWidgetSnapshot.load()?.measurements ?? []
    // No configuration yet means a freshly dropped widget: show the first
    // metric the app published rather than an empty card.
    let requestedId = configuration.metric?.id ?? all.first?.id
    let metric = all.first { $0.id == requestedId }

    if metric == nil, all.isEmpty, allowPlaceholder {
      return MeasurementsEntry(
        date: .now,
        metric: .placeholder,
        metricName: HomeWidgetMeasurementMetric.placeholder.name,
        period: configuration.period
      )
    }

    return MeasurementsEntry(
      date: .now,
      metric: metric,
      metricName: metric?.name
        ?? configuration.metric?.name
        ?? MeasurementMetricEntity.fallback.name,
      period: configuration.period
    )
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct MeasurementsWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: TrainLibreHomeWidget.kindMeasurements,
      intent: MeasurementsConfigIntent.self,
      provider: MeasurementsProvider()
    ) { entry in
      MeasurementsWidgetView(entry: entry)
        .statsWidgetContainer()
        .widgetURL(entry.deepLink)
    }
    .configurationDisplayName(Text("widget.measurements.name"))
    .description(Text("widget.measurements.description"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

@available(iOS 18.0, *)
extension MeasurementsEntry {
  /// Opens the screen on the very metric and timeframe the widget shows.
  var deepLink: URL? {
    var components = URLComponents()
    components.scheme = "trainlibre"
    components.host = "measurements"
    components.queryItems = [
      URLQueryItem(name: "metric", value: metric?.id),
      URLQueryItem(name: "period", value: period.rawValue),
    ].filter { $0.value != nil }
    return components.url
  }
}

// MARK: - View

@available(iOS 18.0, *)
struct MeasurementsWidgetView: View {
  let entry: MeasurementsEntry

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  private var palette: StatsPalette {
    StatsPalette(colorScheme: colorScheme, renderingMode: renderingMode)
  }

  private var points: [HomeWidgetMeasurementPoint] {
    entry.metric?.points(withinDays: entry.period.days) ?? []
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      StatsHeader(
        title: Text(entry.metricName),
        chip: Text(entry.period.chipText),
        palette: palette
      )

      Spacer(minLength: 8)

      if points.isEmpty {
        emptyBody
      } else {
        HStack(alignment: .bottom, spacing: 10) {
          stats
            .frame(width: 128, alignment: .leading)

          MeasurementSparkline(points: points, palette: palette)
            .frame(height: 78)
            .frame(maxWidth: .infinity)
        }
      }
    }
  }

  private var latest: HomeWidgetMeasurementPoint? { points.last }
  private var first: HomeWidgetMeasurementPoint? { points.first }

  /// Nil for a single data point — there is no change to state, and the design
  /// document shows an em dash rather than a `0.0` that would read as "held
  /// perfectly steady".
  private var delta: Double? {
    guard points.count > 1, let latest, let first else { return nil }
    return latest.value - first.value
  }

  private var stats: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Text(StatsFormat.decimal1(latest?.value ?? 0))
          .font(StatsTheme.bigNumberFont)
          .kerning(-0.6)
          .foregroundStyle(palette.onSurface)
        if let unit = entry.metric?.unit, !unit.isEmpty {
          Text(" \(unit)")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(palette.onSurface.opacity(0.6))
        }
      }
      .lineLimit(1)
      .minimumScaleFactor(0.6)

      deltaChip
        .padding(.top, 8)

      Text(reference)
        .font(StatsTheme.captionFont)
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
        .padding(.top, 6)
    }
  }

  @ViewBuilder
  private var deltaChip: some View {
    if let delta {
      // Direction, not judgement: the widget has no idea whether the user is
      // cutting or bulking, so it colours the movement and lets them read it.
      let isDown = delta < 0
      let tint = palette.isMonochrome
        ? Color.primary
        : (isDown ? Color(hex: 0x4CAF50) : Color(hex: 0xFF9800))

      HStack(spacing: 5) {
        Image(systemName: isDown ? "arrow.down" : "arrow.up")
          .font(.system(size: 9, weight: .heavy))
        Text("\(StatsFormat.decimal1(abs(delta))) \(entry.metric?.unit ?? "")")
          .font(.system(size: 12, weight: .bold))
      }
      .foregroundStyle(tint)
      .lineLimit(1)
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(
        palette.isMonochrome ? Color.primary.opacity(0.16) : tint.opacity(0.14),
        in: Capsule()
      )
    } else {
      Text(verbatim: "—")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(palette.secondaryText)
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .background(palette.secondarySurface, in: Capsule())
    }
  }

  private var reference: String {
    guard points.count > 1, let first else {
      return String(localized: "widget.measurements.singleEntry")
    }
    return String(
      format: String(localized: "widget.measurements.since %@"),
      StatsFormat.shortDate(first.date)
    )
  }

  /// Nothing recorded in the configured window — which is a normal thing to
  /// happen on a 7-day view, so the card offers the way out rather than sulking.
  private var emptyBody: some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("widget.measurements.empty.body")
        .font(.system(size: 12))
        .foregroundStyle(palette.secondaryText)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)

      StatsActionPill(
        label: Text("widget.measurements.empty.cta"),
        destination: URL(string: "trainlibre://action/add_measurement")!,
        palette: palette
      )
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: StatsTheme.pillRadius, style: .continuous))
  }
}

/// The series as a line with a fading fill beneath it.
@available(iOS 18.0, *)
struct MeasurementSparkline: View {
  let points: [HomeWidgetMeasurementPoint]
  let palette: StatsPalette

  var body: some View {
    GeometryReader { geo in
      let positions = positions(in: geo.size)

      ZStack {
        if positions.count == 1, let only = positions.first {
          // A single reading has no line to draw. The design document puts it on
          // a dashed baseline so the point still reads as "a value in a range"
          // rather than as a stray dot.
          DashedLine()
            .stroke(Color.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)

          Circle()
            .fill(palette.accent)
            .frame(width: 9, height: 9)
            .position(only)
        } else if positions.count > 1 {
          fill(positions, in: geo.size)
            .fill(
              LinearGradient(
                colors: [palette.accent.opacity(0.38), palette.accent.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
              )
            )

          line(positions)
            .stroke(
              palette.accent,
              style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

          if let last = positions.last {
            Circle()
              .fill(palette.accent)
              .frame(width: 6, height: 6)
              .position(last)
          }
        }
      }
    }
  }

  /// Maps the series into the box, with a little vertical breathing room so the
  /// extremes are not clipped by the stroke width.
  private func positions(in size: CGSize) -> [CGPoint] {
    guard !points.isEmpty else { return [] }
    let inset: CGFloat = 4
    let height = max(size.height - inset * 2, 1)

    let values = points.map(\.value)
    let minValue = values.min() ?? 0
    let maxValue = values.max() ?? 0
    let span = maxValue - minValue

    if points.count == 1 {
      return [CGPoint(x: size.width / 2, y: size.height / 2)]
    }

    return points.enumerated().map { index, point in
      let x = size.width * CGFloat(index) / CGFloat(points.count - 1)
      // A perfectly flat series has no span to scale against; centring it beats
      // dividing by zero or pinning it to the floor.
      let ratio = span > 0 ? (point.value - minValue) / span : 0.5
      return CGPoint(x: x, y: inset + height * (1 - ratio))
    }
  }

  private func line(_ positions: [CGPoint]) -> Path {
    var path = Path()
    guard let start = positions.first else { return path }
    path.move(to: start)
    for point in positions.dropFirst() { path.addLine(to: point) }
    return path
  }

  private func fill(_ positions: [CGPoint], in size: CGSize) -> Path {
    var path = line(positions)
    guard let first = positions.first, let last = positions.last else { return path }
    path.addLine(to: CGPoint(x: last.x, y: size.height))
    path.addLine(to: CGPoint(x: first.x, y: size.height))
    path.closeSubpath()
    return path
  }
}

// MARK: - Gallery placeholder

@available(iOS 18.0, *)
extension HomeWidgetMeasurementMetric {
  static var placeholder: HomeWidgetMeasurementMetric {
    let now = Date.now.timeIntervalSince1970 * 1000
    let day = 86_400_000.0
    let values: [Double] = [82.2, 82.0, 82.3, 81.9, 82.1, 81.7, 81.8, 81.5, 81.6, 81.4]

    return HomeWidgetMeasurementMetric(
      id: "weight",
      name: String(localized: "widget.measurements.metric.weight"),
      unit: "kg",
      points: values.enumerated().map { index, value in
        HomeWidgetMeasurementPoint(
          epochMs: now - Double(values.count - 1 - index) * 3 * day,
          value: value
        )
      }
    )
  }
}
