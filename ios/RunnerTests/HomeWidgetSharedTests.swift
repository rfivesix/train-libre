import XCTest

@testable import Runner

/// Covers the two things the widget computes for itself: which diary day a
/// point in time belongs to, and when that answer next changes.
///
/// Everything else the widget shows is handed to it fully formed by the Flutter
/// side and is tested there (`test/features/home_widgets/`).
final class HomeWidgetSharedTests: XCTestCase {

  /// Fixed to a zone without DST surprises inside the cases below, so a failure
  /// means the logic broke rather than the machine moved.
  private var calendar: Calendar = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
    return cal
  }()

  private func date(
    _ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0
  ) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components)!
  }

  // MARK: - Day key

  func testBefore3AMReportsPreviousDay() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(
        for: date(2026, 8, 10, 2, 59), rolloverHour: 3, calendar: calendar),
      "2026-08-09"
    )
  }

  func testAt3AMTheDayHasRolledOver() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 8, 10, 3), rolloverHour: 3, calendar: calendar),
      "2026-08-10"
    )
  }

  func testMiddayReportsCalendarDay() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 8, 10, 12), rolloverHour: 3, calendar: calendar),
      "2026-08-10"
    )
  }

  func testJustBeforeMidnightStillReportsSameDay() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(
        for: date(2026, 8, 10, 23, 59), rolloverHour: 3, calendar: calendar),
      "2026-08-10"
    )
  }

  func testRolloverHourZeroFollowsTheCalendar() {
    // The widget's "Kalendertag" configuration.
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 8, 10, 1), rolloverHour: 0, calendar: calendar),
      "2026-08-10"
    )
  }

  func testDayKeyRollsBackAcrossMonthBoundary() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 9, 1, 1), rolloverHour: 3, calendar: calendar),
      "2026-08-31"
    )
  }

  func testDayKeyRollsBackAcrossYearBoundary() {
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 1, 1, 0, 30), rolloverHour: 3, calendar: calendar),
      "2025-12-31"
    )
  }

  func testDayKeyMatchesTheDartFormat() {
    // Zero padded yyyy-MM-dd, so the string compare against
    // `HomeWidgetSnapshot.logicalDayKey` is exact.
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: date(2026, 3, 7, 12), rolloverHour: 3, calendar: calendar),
      "2026-03-07"
    )
  }

  // MARK: - Next rollover

  func testNextRolloverIsLaterTodayWhenBoundaryIsAhead() {
    let next = HomeWidgetDay.nextRollover(
      after: date(2026, 8, 10, 1), rolloverHour: 3, calendar: calendar)
    XCTAssertEqual(next, date(2026, 8, 10, 3))
  }

  func testNextRolloverIsTomorrowWhenBoundaryHasPassed() {
    let next = HomeWidgetDay.nextRollover(
      after: date(2026, 8, 10, 12), rolloverHour: 3, calendar: calendar)
    XCTAssertEqual(next, date(2026, 8, 11, 3))
  }

  func testNextRolloverIsAlwaysInTheFuture() {
    // Exactly on the boundary must schedule the *next* one, or the timeline
    // would fire an entry for a moment that has already passed.
    let now = date(2026, 8, 10, 3)
    let next = HomeWidgetDay.nextRollover(after: now, rolloverHour: 3, calendar: calendar)
    XCTAssertGreaterThan(next, now)
    XCTAssertEqual(next, date(2026, 8, 11, 3))
  }

  func testNextRolloverCrossesMidnightForCalendarDayMode() {
    let next = HomeWidgetDay.nextRollover(
      after: date(2026, 8, 10, 22), rolloverHour: 0, calendar: calendar)
    XCTAssertEqual(next, date(2026, 8, 11, 0))
  }

  /// The entry scheduled at the rollover must render the day the widget will
  /// then be in — this is the pairing the timeline relies on.
  func testDayKeyJustAfterNextRolloverIsTheFollowingDay() {
    let now = date(2026, 8, 10, 12)
    let next = HomeWidgetDay.nextRollover(after: now, rolloverHour: 3, calendar: calendar)
    XCTAssertEqual(
      HomeWidgetDay.dayKey(
        for: next.addingTimeInterval(60), rolloverHour: 3, calendar: calendar),
      "2026-08-11"
    )
    XCTAssertEqual(
      HomeWidgetDay.dayKey(for: now, rolloverHour: 3, calendar: calendar),
      "2026-08-10"
    )
  }

  // MARK: - Snapshot decoding

  private func makeSnapshot(dayKey: String) -> HomeWidgetSnapshot {
    HomeWidgetSnapshot(
      schemaVersion: 1,
      generatedAtEpochMs: 1_786_355_823_833,
      logicalDayKey: dayKey,
      rolloverHour: 3,
      isAiEnabled: true,
      tiles: [
        HomeWidgetTile(
          slot: "calories", label: "Kalorien", unit: "kcal",
          value: 1234, target: 2000, colorHex: "#FF9800")
      ]
    )
  }

  func testDecodesThePayloadDartWrites() throws {
    let json = """
      {"schemaVersion":1,"generatedAtEpochMs":1786355823833.0,\
      "logicalDayKey":"2026-08-10","rolloverHour":3,"isAiEnabled":true,\
      "tiles":[{"slot":"calories","label":"Kalorien","unit":"kcal",\
      "value":1234.0,"target":2000.0,"colorHex":"#FF9800"}]}
      """
    let decoded = try JSONDecoder().decode(
      HomeWidgetSnapshot.self, from: Data(json.utf8))

    XCTAssertEqual(decoded.logicalDayKey, "2026-08-10")
    XCTAssertEqual(decoded.rolloverHour, 3)
    XCTAssertTrue(decoded.isAiEnabled)
    XCTAssertEqual(decoded.tiles.count, 1)
    XCTAssertEqual(decoded.tiles[0].value, 1234)
  }

  // MARK: - Zeroing

  func testZeroedClearsValuesButKeepsTargets() {
    let zeroed = makeSnapshot(dayKey: "2026-08-10").zeroed(forDayKey: "2026-08-11")

    XCTAssertEqual(zeroed.logicalDayKey, "2026-08-11")
    XCTAssertEqual(zeroed.tiles[0].value, 0)
    XCTAssertEqual(zeroed.tiles[0].target, 2000, "targets survive the rollover")
    XCTAssertEqual(zeroed.tiles[0].label, "Kalorien", "labels survive the rollover")
    XCTAssertEqual(zeroed.tiles[0].colorHex, "#FF9800")
  }

  // MARK: - Tile formatting

  func testValueTextMatchesTheDartTemplateExactly() {
    // GlassProgressBar uses toStringAsFixed, which is locale independent — the
    // widget must not "improve" this into a localized separator.
    let tile = HomeWidgetTile(
      slot: "calories", label: "Kalorien", unit: "kcal",
      value: 1234, target: 2000, colorHex: "#FF9800")
    XCTAssertEqual(tile.valueText, "1234.0 / 2000 kcal")
  }

  func testValueTextRoundsToOneDecimal() {
    let tile = HomeWidgetTile(
      slot: "extra", label: "Zucker", unit: "g",
      value: 40.25, target: 50, colorHex: "#F48FB1")
    // An exact tie. `String(format: "%.1f")` alone renders 40.2 here, which
    // would disagree with the diary by a visible digit.
    XCTAssertEqual(tile.valueText, "40.3 / 50 g")
  }

  /// Every expectation below is the literal output of Dart's
  /// `toStringAsFixed`, captured from the same values. If this drifts, the
  /// widget and the diary have started disagreeing on a digit.
  func testDartFixedMatchesToStringAsFixedOnOneDecimal() {
    let cases: [(Double, String)] = [
      (0.0, "0.0"), (1234.0, "1234.0"), (55.5, "55.5"), (123.456, "123.5"),
      // Exact ties — Dart rounds away from zero, C's %f rounds to even.
      (40.25, "40.3"), (0.25, "0.3"), (0.75, "0.8"), (7.75, "7.8"),
      (1_000_000.25, "1000000.3"),
      // Not ties, despite looking like them: the double sits just below or
      // just above, and scaling by 10 would hide that.
      (0.15, "0.1"), (12.35, "12.3"), (1.05, "1.1"), (3.45, "3.5"),
      (40.35, "40.4"), (0.05, "0.1"), (3.125, "3.1"), (2.625, "2.6"),
      // Carries all the way up.
      (99.95, "100.0"),
    ]
    for (value, expected) in cases {
      XCTAssertEqual(
        HomeWidgetTile.dartFixed(value, 1), expected,
        "toStringAsFixed(1) of \(value)")
    }
  }

  func testDartFixedMatchesToStringAsFixedOnZeroDecimals() {
    let cases: [(Double, String)] = [
      (2000.0, "2000"), (30.0, "30"), (2500.5, "2501"),
      (0.5, "1"), (1.5, "2"), (2.5, "3"),
    ]
    for (value, expected) in cases {
      XCTAssertEqual(
        HomeWidgetTile.dartFixed(value, 0), expected,
        "toStringAsFixed(0) of \(value)")
    }
  }

  func testValueTextDropsTargetWhenThereIsNone() {
    let tile = HomeWidgetTile(
      slot: "calories", label: "Kalorien", unit: "kcal",
      value: 500, target: 0, colorHex: "#FF9800")
    XCTAssertEqual(tile.valueText, "500.0 kcal")
    XCTAssertFalse(tile.hasTarget)
  }

  func testProgressIsClampedAndNeverDividesByZero() {
    func tile(value: Double, target: Double) -> HomeWidgetTile {
      HomeWidgetTile(
        slot: "calories", label: "", unit: "", value: value, target: target,
        colorHex: "#FF9800")
    }

    XCTAssertEqual(tile(value: 1000, target: 2000).progress, 0.5)
    XCTAssertEqual(tile(value: 3000, target: 2000).progress, 1.0, "over target clamps to full")
    XCTAssertEqual(tile(value: 500, target: 0).progress, 0.0, "no target means no fill")
    XCTAssertEqual(tile(value: 0, target: 2000).progress, 0.0)
  }
}
