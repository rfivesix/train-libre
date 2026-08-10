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

  public static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
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

/// The full payload the app publishes to the App Group.
///
/// Holds aggregate totals and targets only — no food names, no timestamps, no
/// entry level data ever reaches the shared container.
public struct HomeWidgetSnapshot: Codable, Hashable {
  public static let currentSchemaVersion = 1

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

  public init(
    schemaVersion: Int,
    generatedAtEpochMs: Double,
    logicalDayKey: String,
    rolloverHour: Int,
    isAiEnabled: Bool,
    tiles: [HomeWidgetTile]
  ) {
    self.schemaVersion = schemaVersion
    self.generatedAtEpochMs = generatedAtEpochMs
    self.logicalDayKey = logicalDayKey
    self.rolloverHour = rolloverHour
    self.isAiEnabled = isAiEnabled
    self.tiles = tiles
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
      tiles: tiles.map { $0.zeroed() }
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
