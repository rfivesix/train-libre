import Foundation

/// Namespace for everything the Flutter app and the Home Screen widgets share.
///
/// Compiled into **both** the Runner and the widget extension — same arrangement
/// as `WorkoutActivityAttributes.swift`.
public enum TrainLibreHomeWidget {
  public static let appGroupId = "group.com.rfivesix.trainlibre"

  /// Key under which the App Group holds the JSON snapshot the app writes on
  /// every diary mutation.
  public static let snapshotKey = "home_widget_snapshot"

  public static let kindTodayGlance = "TrainLibreTodayGlance"
  public static let kindQuickActions = "TrainLibreQuickActions"
  public static let kindRecovery = "TrainLibreRecovery"
  public static let kindSteps = "TrainLibreSteps"
  public static let kindMeasurements = "TrainLibreMeasurements"
  public static let kindLastWorkout = "TrainLibreLastWorkout"

  /// Every timeline the app's snapshot feeds. The bridge reloads all of them on
  /// a write rather than guessing which section changed — a snapshot write is
  /// already debounced to one per user action.
  public static let allKinds = [
    kindTodayGlance,
    kindQuickActions,
    kindRecovery,
    kindSteps,
    kindMeasurements,
    kindLastWorkout,
  ]

  public static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  /// Shared container directory. The muscle heatmap is a file rather than a
  /// `UserDefaults` value because a PNG has no business in a plist.
  public static var containerURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
  }

  public static func sharedFileURL(named name: String) -> URL? {
    // Defends the container against a snapshot that tries to escape it. The app
    // is the only writer, but the widget is the one that would pay for a bug.
    guard !name.isEmpty, !name.contains("/"), name != "..", name != "." else { return nil }
    return containerURL?.appendingPathComponent(name)
  }
}

/// One progress bar in the "Heute im Blick" grid.
///
/// Everything localized or unit-dependent (`label`, `unit`, the already
/// converted `value`) is computed in Dart. The widget only formats the numbers,
/// and does so with the exact same `%.1f / %.0f` template `GlassProgressBar`
/// uses — see `HomeWidgetTile.valueText`.
public struct HomeWidgetTile: Codable, Hashable {
  public let slot: String
  public let label: String
  public let unit: String
  public let value: Double
  public let target: Double
  public let colorHex: String

  public init(
    slot: String,
    label: String,
    unit: String,
    value: Double,
    target: Double,
    colorHex: String
  ) {
    self.slot = slot
    self.label = label
    self.unit = unit
    self.value = value
    self.target = target
    self.colorHex = colorHex
  }

  public var hasTarget: Bool { target > 0 }

  /// Clamped 0...1, mirroring `GlassProgressBar`'s `rawProgress.clamp(0, 1)`.
  public var progress: Double {
    guard hasTarget else { return 0 }
    return min(max(value / target, 0), 1)
  }

  /// Byte-identical to the Dart side:
  /// `'${value.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} $unit'`.
  ///
  /// Deliberately *not* `NumberFormatter` — `toStringAsFixed` is locale
  /// independent, so a German user sees `1234.0`, not `1234,0`, in the app. The
  /// widget has to match that, not "improve" on it.
  public var valueText: String {
    let left = Self.dartFixed(value, 1)
    guard hasTarget else { return "\(left) \(unit)" }
    return "\(left) / \(Self.dartFixed(target, 0)) \(unit)"
  }

  /// `Double.toStringAsFixed` from Dart, reproduced exactly.
  ///
  /// `String(format: "%.1f")` is *almost* right — it rounds on the double's
  /// true value, as Dart does — but it breaks an exact tie to even where Dart
  /// breaks it away from zero, so 40.25 g of sugar renders as `40.2` in the
  /// widget and `40.3` in the diary.
  ///
  /// The tie cannot be found by scaling: `0.15 * 10` lands on exactly 1.5 even
  /// though the double is below the tie, which would round 0.15 up to 0.2 while
  /// the app shows 0.1. So the decision is made on the printed expansion of the
  /// double, which is its true value: round up when the first dropped digit is
  /// 5 or more. Digits beyond the expansion cannot change that verdict — they
  /// can only push a value further past a tie it already rounds up on.
  static func dartFixed(_ value: Double, _ digits: Int) -> String {
    guard value.isFinite else { return String(format: "%.\(digits)f", value) }

    let expanded = String(format: "%.\(digits + 25)f", abs(value))
    guard let dot = expanded.firstIndex(of: ".") else { return expanded }

    var intPart = Array(expanded[expanded.startIndex..<dot].utf8).map { Int($0) - 48 }
    let fracAll = Array(expanded[expanded.index(after: dot)...].utf8).map { Int($0) - 48 }
    var frac = Array(fracAll.prefix(digits))

    if fracAll.count > digits, fracAll[digits] >= 5 {
      var carry = true
      var i = frac.count - 1
      while carry, i >= 0 {
        if frac[i] == 9 { frac[i] = 0; i -= 1 } else { frac[i] += 1; carry = false }
      }
      var j = intPart.count - 1
      while carry, j >= 0 {
        if intPart[j] == 9 { intPart[j] = 0; j -= 1 } else { intPart[j] += 1; carry = false }
      }
      if carry { intPart.insert(1, at: 0) }
    }

    func text(_ digits: [Int]) -> String {
      String(digits.map { Character(UnicodeScalar(UInt8($0 + 48))) })
    }
    // "-0.0" is not something Dart produces here either.
    let isZero = intPart.allSatisfy { $0 == 0 } && frac.allSatisfy { $0 == 0 }
    let sign = (value < 0 && !isZero) ? "-" : ""

    return digits == 0
      ? sign + text(intPart)
      : sign + text(intPart) + "." + text(frac)
  }

  public func zeroed() -> HomeWidgetTile {
    HomeWidgetTile(
      slot: slot,
      label: label,
      unit: unit,
      value: 0,
      target: target,
      colorHex: colorHex
    )
  }
}

// MARK: - Statistics sections (schema v2)

/// One readiness pill of the Muscle Readiness widget.
///
/// Mirrors `RecoverySectionCard._buildReadinessPill`. The count, its share and
/// the colour all arrive precomputed — the widget only lays them out.
public struct HomeWidgetRecoveryState: Codable, Hashable {
  public let state: String
  public let label: String
  public let count: Int
  public let percent: Int
  public let colorHex: String

  public init(state: String, label: String, count: Int, percent: Int, colorHex: String) {
    self.state = state
    self.label = label
    self.count = count
    self.percent = percent
    self.colorHex = colorHex
  }
}

public struct HomeWidgetRecovery: Codable, Hashable {
  public let hasData: Bool
  public let headline: String

  /// Absent when the app would have used `colorScheme.outline` — the widget has
  /// its own scheme and resolves that itself rather than being handed a colour
  /// from the app's theme.
  public let headlineColorHex: String?
  public let states: [HomeWidgetRecoveryState]

  public init(
    hasData: Bool,
    headline: String,
    headlineColorHex: String?,
    states: [HomeWidgetRecoveryState]
  ) {
    self.hasData = hasData
    self.headline = headline
    self.headlineColorHex = headlineColorHex
    self.states = states
  }
}

public struct HomeWidgetStepsDay: Codable, Hashable {
  /// `yyyy-MM-dd` in the user's calendar, so "which bar is today" needs no
  /// timezone arithmetic in the widget.
  public let dayKey: String
  public let steps: Int

  public init(dayKey: String, steps: Int) {
    self.dayKey = dayKey
    self.steps = steps
  }
}

public struct HomeWidgetSteps: Codable, Hashable {
  public let isTrackingEnabled: Bool
  public let todaySteps: Int
  public let dailyGoal: Int

  /// Oldest first, seven entries, the last one being today.
  public let days: [HomeWidgetStepsDay]

  public init(isTrackingEnabled: Bool, todaySteps: Int, dailyGoal: Int, days: [HomeWidgetStepsDay]) {
    self.isTrackingEnabled = isTrackingEnabled
    self.todaySteps = todaySteps
    self.dailyGoal = dailyGoal
    self.days = days
  }

  /// `StatisticsStepsCard`'s scale: the taller of the goal and the best day, so
  /// no bar can leave the chart no matter how big a day was.
  public var chartMaximum: Int {
    max(days.map(\.steps).max() ?? 0, max(dailyGoal, 1))
  }
}

public struct HomeWidgetMeasurementPoint: Codable, Hashable {
  public let epochMs: Double
  public let value: Double

  public init(epochMs: Double, value: Double) {
    self.epochMs = epochMs
    self.value = value
  }

  public var date: Date { Date(timeIntervalSince1970: epochMs / 1000) }
}

/// One selectable metric of the configurable Measurements widget.
///
/// Carries the whole series rather than a pre-sliced timeframe: the timeframe is
/// a widget configuration the app never sees, so the widget has to be able to
/// answer for any of the five periods on its own.
public struct HomeWidgetMeasurementMetric: Codable, Hashable, Identifiable {
  public let id: String
  public let name: String
  public let unit: String

  /// Oldest first.
  public let points: [HomeWidgetMeasurementPoint]

  public init(id: String, name: String, unit: String, points: [HomeWidgetMeasurementPoint]) {
    self.id = id
    self.name = name
    self.unit = unit
    self.points = points
  }

  /// The points inside the last `days`, or all of them when `days` is nil (Max).
  public func points(withinDays days: Int?, now: Date = .now) -> [HomeWidgetMeasurementPoint] {
    guard let days else { return points }
    let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
    return points.filter { $0.date >= cutoff }
  }
}

public struct HomeWidgetLastWorkout: Codable, Hashable {
  public let id: Int
  public let title: String
  public let completedAtEpochMs: Double
  public let durationSeconds: Int

  /// Absent for a session without a single weighted set — the widget shows the
  /// rep count in that slot instead.
  public let totalVolume: Double?
  public let volumeUnit: String
  public let totalReps: Int
  public let totalSets: Int

  /// File name inside the App Group container, written by the app when the
  /// workout was finished.
  public let heatmapImageName: String?

  public init(
    id: Int,
    title: String,
    completedAtEpochMs: Double,
    durationSeconds: Int,
    totalVolume: Double?,
    volumeUnit: String,
    totalReps: Int,
    totalSets: Int,
    heatmapImageName: String?
  ) {
    self.id = id
    self.title = title
    self.completedAtEpochMs = completedAtEpochMs
    self.durationSeconds = durationSeconds
    self.totalVolume = totalVolume
    self.volumeUnit = volumeUnit
    self.totalReps = totalReps
    self.totalSets = totalSets
    self.heatmapImageName = heatmapImageName
  }

  public var completedAt: Date { Date(timeIntervalSince1970: completedAtEpochMs / 1000) }

  public var heatmapURL: URL? {
    guard let heatmapImageName else { return nil }
    return TrainLibreHomeWidget.sharedFileURL(named: heatmapImageName)
  }
}

/// The full payload the app publishes to the App Group.
///
/// Holds aggregate totals and targets only — no food names, no timestamps, no
/// entry level data ever reaches the shared container.
public struct HomeWidgetSnapshot: Codable, Hashable {
  /// v2 added the four statistics sections. All of them are optional and every
  /// reader treats a missing section as "nothing to show yet", so a v1 payload
  /// left over from an older build still decodes.
  public static let currentSchemaVersion = 2

  public let schemaVersion: Int
  public let generatedAtEpochMs: Double

  /// The diary day these totals belong to, as `yyyy-MM-dd` in the user's local
  /// calendar.
  public let logicalDayKey: String

  /// The hour at which the app rolls the diary over to the next day (3).
  /// Transmitted rather than hardcoded so the widget cannot drift from
  /// `resolveDiaryInitialDate`.
  public let rolloverHour: Int

  public let isAiEnabled: Bool
  public let tiles: [HomeWidgetTile]

  public let recovery: HomeWidgetRecovery?
  public let steps: HomeWidgetSteps?
  public let measurements: [HomeWidgetMeasurementMetric]
  public let lastWorkout: HomeWidgetLastWorkout?

  public init(
    schemaVersion: Int,
    generatedAtEpochMs: Double,
    logicalDayKey: String,
    rolloverHour: Int,
    isAiEnabled: Bool,
    tiles: [HomeWidgetTile],
    recovery: HomeWidgetRecovery? = nil,
    steps: HomeWidgetSteps? = nil,
    measurements: [HomeWidgetMeasurementMetric] = [],
    lastWorkout: HomeWidgetLastWorkout? = nil
  ) {
    self.schemaVersion = schemaVersion
    self.generatedAtEpochMs = generatedAtEpochMs
    self.logicalDayKey = logicalDayKey
    self.rolloverHour = rolloverHour
    self.isAiEnabled = isAiEnabled
    self.tiles = tiles
    self.recovery = recovery
    self.steps = steps
    self.measurements = measurements
    self.lastWorkout = lastWorkout
  }

  /// A v1 payload has no `measurements` key at all, and `[T].self` is not
  /// optional-by-default the way `T?` is — without this the whole snapshot
  /// would fail to decode on the first launch after an app update.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
    generatedAtEpochMs = try c.decode(Double.self, forKey: .generatedAtEpochMs)
    logicalDayKey = try c.decode(String.self, forKey: .logicalDayKey)
    rolloverHour = try c.decode(Int.self, forKey: .rolloverHour)
    isAiEnabled = try c.decode(Bool.self, forKey: .isAiEnabled)
    tiles = try c.decode([HomeWidgetTile].self, forKey: .tiles)
    recovery = try c.decodeIfPresent(HomeWidgetRecovery.self, forKey: .recovery)
    steps = try c.decodeIfPresent(HomeWidgetSteps.self, forKey: .steps)
    measurements =
      try c.decodeIfPresent([HomeWidgetMeasurementMetric].self, forKey: .measurements) ?? []
    lastWorkout = try c.decodeIfPresent(HomeWidgetLastWorkout.self, forKey: .lastWorkout)
  }

  /// Same totals reset to zero but the targets kept, for a day the app has not
  /// written a snapshot for yet. This is what makes the 03:00 rollover work
  /// while the app is closed: nothing can have been logged for the new day
  /// without the app running, so zero is not a guess — it is the answer.
  public func zeroed(forDayKey dayKey: String) -> HomeWidgetSnapshot {
    HomeWidgetSnapshot(
      schemaVersion: schemaVersion,
      generatedAtEpochMs: generatedAtEpochMs,
      logicalDayKey: dayKey,
      rolloverHour: rolloverHour,
      isAiEnabled: isAiEnabled,
      tiles: tiles.map { $0.zeroed() },
      // Only the diary rolls over at 03:00. Recovery, steps, measurements and
      // the last workout are not "today's totals" — they carry across the
      // boundary unchanged, and blanking them would be a lie, not a reset.
      recovery: recovery,
      steps: steps,
      measurements: measurements,
      lastWorkout: lastWorkout
    )
  }

  public static func load(
    from defaults: UserDefaults? = TrainLibreHomeWidget.defaults
  ) -> HomeWidgetSnapshot? {
    guard
      let json = defaults?.string(forKey: TrainLibreHomeWidget.snapshotKey),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(HomeWidgetSnapshot.self, from: data)
  }
}

// MARK: - Day resolution

/// Resolves which diary day a point in time belongs to.
///
/// The rule lives in Dart (`resolveDiaryInitialDate`): before 03:00 the diary
/// still shows the previous day. `rolloverHour` carries it across, so this stays
/// a single rule with one owner.
public enum HomeWidgetDay {
  public static func dayKey(
    for date: Date,
    rolloverHour: Int,
    calendar: Calendar = .current
  ) -> String {
    let shifted = calendar.date(byAdding: .hour, value: -rolloverHour, to: date) ?? date
    let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
    return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
  }

  /// The next instant at which `dayKey(for:rolloverHour:)` changes its answer.
  public static func nextRollover(
    after date: Date,
    rolloverHour: Int,
    calendar: Calendar = .current
  ) -> Date {
    // Today's boundary if it is still ahead of us, tomorrow's otherwise.
    let todayBoundary = calendar.date(
      bySettingHour: rolloverHour % 24,
      minute: 0,
      second: 0,
      of: date
    )
    if let todayBoundary, todayBoundary > date {
      return todayBoundary
    }
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date
    return calendar.date(
      bySettingHour: rolloverHour % 24,
      minute: 0,
      second: 0,
      of: tomorrow
    ) ?? date.addingTimeInterval(3600)
  }
}
