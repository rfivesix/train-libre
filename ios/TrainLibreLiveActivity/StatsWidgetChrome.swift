import SwiftUI
import WidgetKit

/// The shared skin of the four statistics widgets.
///
/// Tokens come from the design document `Home Screen Widgets.dc.html`, which in
/// turn lifted them from `lib/util/design_constants.dart`. The one deliberate
/// deviation the document records: padding drops 16 → 14 and the headline
/// titleLarge 20 → 18/22, because the in-app card layout does not fit a 170pt
/// `systemMedium` frame otherwise.
@available(iOS 18.0, *)
enum StatsTheme {
  static let padding: CGFloat = 14

  /// `DesignConstants.borderRadiusL`.
  static let pillRadius: CGFloat = 19
  /// The smaller metric tiles of the Last Workout card.
  static let tileRadius: CGFloat = 14
  static let rowSpacing: CGFloat = 8

  static let accentDark = Color(hex: 0xDDFF00)
  static let accentLight = Color(hex: 0x8B9E00)

  /// `DesignConstants.summaryCardSecondary{Dark,Light}Mode`.
  static let secondarySurfaceDark = Color(hex: 0x2C2C2E)
  static let secondarySurfaceLight = Color(hex: 0xE4E6EB)

  static let titleFont = Font.system(size: 16, weight: .bold)
  static let chipFont = Font.system(size: 10, weight: .bold)
  static let headlineFont = Font.system(size: 18, weight: .bold)
  static let bigNumberFont = Font.system(size: 34, weight: .bold)
  static let overlineFont = Font.system(size: 10, weight: .bold)
  static let captionFont = Font.system(size: 10, weight: .regular)
}

/// Resolves every colour the widgets draw for the current appearance.
///
/// Three appearances have to work: light, dark, and the iOS 18 tinted home
/// screen. Tinted is not "dark with a hue" — the system renders the widget's
/// luminance through a single tint, so *every* hue collapses to the same colour.
/// Anything that carried meaning through hue therefore has to carry it through
/// opacity instead, which is what `stateColor` and `stateBorder` are for.
@available(iOS 18.0, *)
struct StatsPalette {
  let isMonochrome: Bool
  private let isDark: Bool

  init(colorScheme: ColorScheme, renderingMode: WidgetRenderingMode) {
    self.isDark = colorScheme == .dark
    self.isMonochrome = renderingMode != .fullColor
  }

  var accent: Color {
    isMonochrome ? .primary : (isDark ? StatsTheme.accentDark : StatsTheme.accentLight)
  }

  /// What is legible *on* the accent — a checkmark inside a filled badge, the
  /// label of a filled pill.
  ///
  /// The two accents are not two shades of one colour: dark mode's `#DDFF00` is
  /// near-white in luminance and light mode's `#8B9E00` is a dark olive. So the
  /// foreground flips with the scheme rather than staying white, which is what
  /// made the goal-met checkmark disappear in dark mode.
  var onAccent: Color {
    if isMonochrome { return Color.primary.opacity(0.2) }
    return isDark ? .black : .white
  }

  var onSurface: Color { .primary }

  var secondaryText: Color {
    isMonochrome ? Color.primary.opacity(0.55) : Color.secondary
  }

  var secondarySurface: Color {
    if isMonochrome { return Color.primary.opacity(0.10) }
    return isDark ? StatsTheme.secondarySurfaceDark : StatsTheme.secondarySurfaceLight
  }

  var chipBackground: Color {
    isMonochrome ? Color.primary.opacity(0.16) : accent.opacity(0.14)
  }

  /// A colour the app computed, honoured in full colour and folded into the
  /// tint otherwise.
  func stateColor(_ hex: String?) -> Color {
    guard let hex else { return secondaryText }
    return isMonochrome ? .primary : Color(hexString: hex)
  }

  /// The readiness pills' border.
  ///
  /// In full colour it is the state's own hue at the card's alpha. In tinted
  /// mode all three would be identical, so `emphasis` (0 = calmest state,
  /// 1 = most urgent) drives the opacity instead — see panel 2d of the design
  /// document.
  func stateBorder(_ hex: String?, emphasis: Double) -> Color {
    if isMonochrome {
      return Color.primary.opacity(0.20 + 0.35 * emphasis)
    }
    return Color(hexString: hex ?? "#8E8E93").opacity(isDark ? 0.35 : 0.25)
  }

  func stateBorderWidth(emphasis: Double) -> CGFloat {
    isMonochrome && emphasis >= 1 ? 1.5 : 1
  }
}

@available(iOS 18.0, *)
extension View {
  /// Applies the frame, padding and background every statistics widget shares.
  func statsWidgetContainer() -> some View {
    self
      .padding(StatsTheme.padding)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .containerBackground(.fill.tertiary, for: .widget)
  }
}

/// Title, optional chip and chevron — the header every hub card in the app has.
@available(iOS 18.0, *)
struct StatsHeader: View {
  let title: Text
  var chip: Text?
  let palette: StatsPalette

  var body: some View {
    HStack(spacing: StatsTheme.rowSpacing) {
      title
        .font(StatsTheme.titleFont)
        .foregroundStyle(palette.onSurface)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)

      if let chip {
        chip
          .font(StatsTheme.chipFont)
          .foregroundStyle(palette.accent)
          .lineLimit(1)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(palette.chipBackground, in: Capsule())
          // Outermost, so the HStack sees them. The chip states its width and
          // keeps it; without both, the title's `maxWidth: .infinity` claims
          // the whole row first and the chip is laid out at zero width — an
          // empty coloured pill, which is exactly what shipped in the first cut.
          .fixedSize(horizontal: true, vertical: false)
          .layoutPriority(1)
      }

      Image(systemName: "chevron.right")
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(palette.secondaryText)
    }
  }
}

/// The overline used where the card has no full-width title — the Last Workout
/// widget, whose title slot belongs to the workout's name.
@available(iOS 18.0, *)
struct StatsOverline: View {
  let text: Text
  let palette: StatsPalette
  var showsChevron: Bool = true

  var body: some View {
    HStack(spacing: 6) {
      text
        .font(StatsTheme.overlineFont)
        .textCase(.uppercase)
        .kerning(0.7)
        .foregroundStyle(palette.secondaryText)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)

      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(palette.secondaryText)
      }
    }
  }
}

/// The filled call to action of the empty states.
///
/// A `Link` rather than part of the widget's own URL: the empty states point at
/// an action ("start a workout", "add a value"), not at the screen the rest of
/// the card links to.
@available(iOS 18.0, *)
struct StatsActionPill: View {
  let label: Text
  let destination: URL
  let palette: StatsPalette
  var isFilled: Bool = true

  var body: some View {
    Link(destination: destination) {
      label
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(isFilled && !palette.isMonochrome ? palette.onAccent : palette.accent)
        .lineLimit(1)
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(
          isFilled && !palette.isMonochrome ? AnyShapeStyle(palette.accent)
            : AnyShapeStyle(palette.chipBackground),
          in: Capsule()
        )
    }
  }
}

// MARK: - Formatting

@available(iOS 18.0, *)
enum StatsFormat {
  /// Grouped integers (`8,432` / `8.432`), matching the app's
  /// `NumberFormat.decimalPattern()`.
  ///
  /// `Locale.autoupdatingCurrent` is `NumberFormatter`'s default already, but is
  /// spelled out here rather than left implicit: the widget has no Flutter
  /// locale of its own to defer to, so this — the device's own Language &
  /// Region setting — is the one source of truth for how a German or French
  /// user expects a thousands separator to look, and it must keep tracking a
  /// live change to that setting rather than a locale snapshotted at process
  /// launch.
  static func grouped(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
  }

  /// `StatisticsStepsCard._compactAxisLabel`, reproduced.
  static func compactAxis(_ value: Int) -> String {
    if value >= 10000 { return "\((value + 500) / 1000)k" }
    if value >= 1000 {
      let truncated = HomeWidgetTile.dartFixed(Double(value) / 1000, 1)
      return truncated.hasSuffix(".0")
        ? "\(truncated.dropLast(2))k"
        : "\(truncated)k"
    }
    return "\(value)"
  }

  /// `1h 14m`, or `42m` for anything under an hour — the design document's
  /// duration tile.
  static func duration(seconds: Int) -> String {
    let total = max(seconds, 0)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    if hours > 0 { return "\(hours)h \(String(format: "%02d", minutes))m" }
    return "\(minutes)m"
  }

  /// One decimal, the same way `toStringAsFixed(1)` does it in the app.
  static func decimal1(_ value: Double) -> String {
    HomeWidgetTile.dartFixed(value, 1)
  }

  /// "Yesterday, 18:30" close to today, a short date further back.
  ///
  /// `doesRelativeDateFormatting` is the system's own wording in the user's
  /// language, which beats anything reimplemented here.
  static func relativeDateTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
    return formatter.string(from: date)
  }

  /// A short date without a year — the "vs. 12 Jul" reference of the
  /// Measurements widget.
  static func shortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.setLocalizedDateFormatFromTemplate("ddMMM")
    return formatter.string(from: date)
  }

  /// The single upper-case initial under each steps bar — locale-aware, so a
  /// German calendar reads `D/M/D/D/F/S/S`, not the English `T/W/T/F/S/S/M`.
  static func weekdayInitial(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = .autoupdatingCurrent
    formatter.setLocalizedDateFormatFromTemplate("EEE")
    let text = formatter.string(from: date)
    return String(text.prefix(1)).uppercased()
  }

  /// Parses the `yyyy-MM-dd` day keys the snapshot carries.
  static func day(fromKey key: String) -> Date? {
    let formatter = DateFormatter()
    formatter.calendar = .current
    formatter.timeZone = .current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: key)
  }
}
