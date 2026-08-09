import SwiftUI

/// Tokens taken 1:1 from the design document `Live Activity.dc.html`.
///
/// The brand values mirror `lib/util/design_constants.dart`; the glass itself
/// is the iOS system material and is deliberately not restyled here.
enum LATheme {
  static let accent = Color(hex: 0xDDFF00)
  static let onAccent = Color(hex: 0x14170A)
  /// Lightened out of `brandRedColor` (#E5253A) for contrast on black.
  static let overdue = Color(hex: 0xFF6B78)

  /// The one style every secondary label uses: workout title, workout
  /// duration and "Set x of y". They sit on the same card and must not read as
  /// three different faces.
  static let metaFont = Font.system(size: 12, weight: .semibold)
  static let secondaryText = Color.white.opacity(0.60)
  static let metricText = Color.white.opacity(0.55)

  /// Vertical rhythm inside the card — the gap below the exercise name, and
  /// the same gap above the timer row.
  static let rowSpacing: CGFloat = 7

  static let controlFill = Color.white.opacity(0.14)
  /// Checkmark glyph when the set cannot be completed from here.
  static let disabledTickForeground = Color.white.opacity(0.35)
  static let timerWellFill = Color.white.opacity(0.07)
  static let trackFill = Color.white.opacity(0.16)

  static let cardRadius: CGFloat = 22
  static let controlRadius: CGFloat = 11
  static let wideControlRadius: CGFloat = 13

  static let tickSize: CGFloat = 36
  static let controlHeight: CGFloat = 34
  static let wideControlHeight: CGFloat = 44
}

extension Color {
  init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }

  /// Parses the `#RRGGBB` strings Dart sends for set-type badges.
  init(hexString: String) {
    let trimmed = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
    let value = UInt32(trimmed, radix: 16) ?? 0x8E8E93
    self.init(hex: value)
  }
}
