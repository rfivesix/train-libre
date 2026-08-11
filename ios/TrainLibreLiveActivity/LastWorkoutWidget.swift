import SwiftUI
import WidgetKit

// MARK: - Timeline

@available(iOS 18.0, *)
struct LastWorkoutEntry: TimelineEntry {
  let date: Date
  let workout: HomeWidgetLastWorkout?
}

@available(iOS 18.0, *)
struct LastWorkoutProvider: TimelineProvider {
  func placeholder(in context: Context) -> LastWorkoutEntry {
    LastWorkoutEntry(date: .now, workout: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (LastWorkoutEntry) -> Void) {
    let stored = HomeWidgetSnapshot.load()?.lastWorkout
    completion(LastWorkoutEntry(date: .now, workout: stored ?? (context.isPreview ? .placeholder : nil)))
  }

  /// A finished workout does not change; only the way its date reads does.
  ///
  /// "Yesterday, 18:30" becomes a plain date once it is two days old, so the
  /// timeline is refreshed at the next midnight rather than on a fixed interval.
  func getTimeline(in context: Context, completion: @escaping (Timeline<LastWorkoutEntry>) -> Void) {
    let entry = LastWorkoutEntry(date: .now, workout: HomeWidgetSnapshot.load()?.lastWorkout)
    let midnight = Calendar.current.nextDate(
      after: .now,
      matching: DateComponents(hour: 0, minute: 1),
      matchingPolicy: .nextTime
    ) ?? Date.now.addingTimeInterval(24 * 60 * 60)
    completion(Timeline(entries: [entry], policy: .after(midnight)))
  }
}

// MARK: - Widget

@available(iOS 18.0, *)
struct LastWorkoutWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: TrainLibreHomeWidget.kindLastWorkout,
      provider: LastWorkoutProvider()
    ) { entry in
      LastWorkoutWidgetView(workout: entry.workout)
        .statsWidgetContainer()
        .widgetURL(entry.deepLink)
    }
    .configurationDisplayName(Text("widget.lastWorkout.name"))
    .description(Text("widget.lastWorkout.description"))
    // The large family exists for the heatmap: at medium the silhouettes get a
    // 130pt column, which is enough to recognise the shape but not to read
    // which head of a muscle was loaded.
    .supportedFamilies([.systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

@available(iOS 18.0, *)
extension LastWorkoutEntry {
  /// The detail screen of this very workout — or the workout tab when there is
  /// no workout to open yet.
  var deepLink: URL? {
    guard let workout else { return URL(string: "trainlibre://action/start_workout") }
    return URL(string: "trainlibre://workout/log/\(workout.id)")
  }
}

// MARK: - View

@available(iOS 18.0, *)
struct LastWorkoutWidgetView: View {
  let workout: HomeWidgetLastWorkout?

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode
  @Environment(\.widgetFamily) private var family

  private var palette: StatsPalette {
    StatsPalette(colorScheme: colorScheme, renderingMode: renderingMode)
  }

  /// The design document's 60 : 40 column split, for the medium family.
  private static let detailsWidthShare: CGFloat = 0.58

  var body: some View {
    if let workout {
      if family == .systemLarge {
        largeBody(workout)
      } else {
        // Split by measured width, not by layout priority: both columns are
        // flexible and the HStack gave the whole row to the details, leaving the
        // heatmap a sliver.
        GeometryReader { geo in
          HStack(alignment: .top, spacing: 12) {
            details(workout, titleSize: 20)
              .frame(width: max(geo.size.width * Self.detailsWidthShare, 0), alignment: .leading)

            LastWorkoutHeatmap(workout: workout, palette: palette)
          }
        }
      }
    } else {
      emptyBody
    }
  }

  /// Large: the same figures across the top, and the rest of the card given to
  /// the muscle map at roughly four times the area.
  private func largeBody(_ workout: HomeWidgetLastWorkout) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      details(workout, titleSize: 24)
        .fixedSize(horizontal: false, vertical: true)

      LastWorkoutHeatmap(workout: workout, palette: palette)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 12)
    }
  }

  private func details(
    _ workout: HomeWidgetLastWorkout,
    titleSize: CGFloat
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      StatsOverline(text: Text("widget.lastWorkout.name"), palette: palette)

      Text(workout.title)
        .font(.system(size: titleSize, weight: .bold))
        .kerning(-0.2)
        .foregroundStyle(palette.onSurface)
        // Two lines then an ellipsis — a long routine name must not be allowed
        // to push the metric tiles out of the card.
        .lineLimit(2)
        .minimumScaleFactor(0.75)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 5)

      Text(StatsFormat.relativeDateTime(workout.completedAt))
        .font(.system(size: 12))
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.top, 3)

      Spacer(minLength: 6)

      // Three equal thirds, computed rather than left to the HStack's own
      // flexible-space division: `.frame(maxWidth: .infinity)` on each tile
      // reads as "equal share" but the longest caption (Volume) was winning an
      // outsized one and truncating to "VOLUME…" instead of scaling down.
      GeometryReader { geo in
        let spacing: CGFloat = 6
        let tileWidth = max((geo.size.width - spacing * 2) / 3, 0)

        HStack(spacing: spacing) {
          LastWorkoutMetric(
            caption: Text("widget.lastWorkout.duration"),
            value: StatsFormat.duration(seconds: workout.durationSeconds),
            palette: palette
          )
          .frame(width: tileWidth)

          volumeOrReps(workout)
            .frame(width: tileWidth)

          LastWorkoutMetric(
            caption: Text("widget.lastWorkout.sets"),
            value: "\(workout.totalSets)",
            palette: palette
          )
          .frame(width: tileWidth)
        }
      }
      .frame(height: Self.metricRowHeight)
    }
  }

  /// The pill's natural height at its current padding and two-line caption —
  /// fixed because the `GeometryReader` above would otherwise claim all
  /// remaining vertical space instead of sizing to its content.
  private static let metricRowHeight: CGFloat = 44

  /// A calisthenics session has no volume worth printing, so its middle tile
  /// counts reps instead of showing a bold zero.
  private func volumeOrReps(_ workout: HomeWidgetLastWorkout) -> some View {
    if let volume = workout.totalVolume {
      return LastWorkoutMetric(
        caption: Text("widget.lastWorkout.volume \(workout.volumeUnit)"),
        value: StatsFormat.grouped(Int(volume.rounded())),
        palette: palette
      )
    }
    return LastWorkoutMetric(
      caption: Text("widget.lastWorkout.reps"),
      value: "\(workout.totalReps)",
      palette: palette
    )
  }

  /// Nothing logged yet. An invitation rather than an apology.
  private var emptyBody: some View {
    VStack(alignment: .leading, spacing: 0) {
      StatsOverline(text: Text("widget.lastWorkout.name"), palette: palette)

      Spacer(minLength: 8)

      HStack(spacing: 14) {
        Image(systemName: "dumbbell.fill")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(palette.accent)
          .frame(width: 52, height: 52)
          .background(palette.chipBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

        Text("widget.lastWorkout.empty.title")
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(palette.onSurface)
          .lineLimit(2)
          .minimumScaleFactor(0.8)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 8)

      StatsActionPill(
        label: Text("widget.startWorkout"),
        destination: URL(string: "trainlibre://action/start_workout")!,
        palette: palette
      )
    }
  }
}

/// One of the three key figures, in the app's secondary card surface.
@available(iOS 18.0, *)
struct LastWorkoutMetric: View {
  let caption: Text
  let value: String
  let palette: StatsPalette

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      caption
        .font(.system(size: 9, weight: .bold))
        .textCase(.uppercase)
        .kerning(0.6)
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
        // Generous on purpose: at 44pt of tile width even "Vol. (kg)" needs to
        // shrink noticeably, and a smaller-but-whole caption beats an ellipsis.
        .minimumScaleFactor(0.55)

      Text(value)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(palette.onSurface)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(.horizontal, 8)
    .padding(.vertical, 7)
    .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: StatsTheme.tileRadius, style: .continuous))
  }
}

/// The front-and-back muscle map the app rendered when the workout was
/// finished.
///
/// The image is produced in Flutter — `DualBodyHighlighter` and its SVG body
/// models are the app's, and reproducing them as SwiftUI paths would mean two
/// silhouettes that drift apart on the first anatomy fix. If it is missing (an
/// older workout, or a render that failed), the slot falls back to the app's
/// mark rather than leaving a hole.
@available(iOS 18.0, *)
struct LastWorkoutHeatmap: View {
  let workout: HomeWidgetLastWorkout
  let palette: StatsPalette

  private var image: UIImage? {
    guard let url = workout.heatmapURL else { return nil }
    return UIImage(contentsOfFile: url.path)
  }

  var body: some View {
    ZStack {
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .padding(6)
      } else {
        Image(systemName: "figure.strengthtraining.traditional")
          .font(.system(size: 30, weight: .regular))
          .foregroundStyle(palette.secondaryText.opacity(0.5))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(palette.secondarySurface, in: RoundedRectangle(cornerRadius: StatsTheme.tileRadius, style: .continuous))
  }
}

// MARK: - Gallery placeholder

@available(iOS 18.0, *)
extension HomeWidgetLastWorkout {
  static var placeholder: HomeWidgetLastWorkout {
    HomeWidgetLastWorkout(
      id: 0,
      title: String(localized: "widget.lastWorkout.placeholder.title"),
      completedAtEpochMs: Date.now.addingTimeInterval(-20 * 60 * 60).timeIntervalSince1970 * 1000,
      durationSeconds: 4440,
      totalVolume: 12450,
      volumeUnit: "kg",
      totalReps: 186,
      totalSets: 18,
      heatmapImageName: nil
    )
  }
}
