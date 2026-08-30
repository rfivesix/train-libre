import SwiftUI
import WidgetKit

/// Design tokens carried over from `lib/util/design_constants.dart` and
/// `lib/widgets/common/glass_progress_bar.dart`, so the widget and the diary
/// grid stay the same object in two renderers.
enum TGTheme {
  /// `DesignConstants.spacingS`
  static let gridSpacing: CGFloat = 8
  /// Outer inset between the widget's rounded edge and the tile grid.
  /// Matched to Apple's own Shortcuts widget, which keeps the outer margin the
  /// same as the gap between tiles rather than doubling it.
  static let containerPadding: CGFloat = 8
  /// Concentric with the widget's own corner (~26pt on current iPhones) minus
  /// `containerPadding`, which is how Apple's Shortcuts tiles are rounded.
  static let tileRadius: CGFloat = 20
  /// `DesignConstants.borderRadiusL`
  static let barRadius: CGFloat = 19
  /// `DesignConstants.spacingM` / `spacingXS`
  static let barPaddingH: CGFloat = 12
  static let barPaddingV: CGFloat = 4

  /// `DesignConstants.summaryCardDarkMode`
  static let cardDark = Color(hex: 0x1C1C1E)
  static let cardLight = Color.white

  /// The app uses `titleMedium` bold / `bodyMedium` w500 at a 54pt bar height.
  /// A `.systemMedium` widget leaves roughly 39pt per row, so both scale down
  /// proportionally. This is the one deliberate deviation from the diary.
  static let labelFont = Font.system(size: 13, weight: .bold)
  static let valueFont = Font.system(size: 11, weight: .medium)
}

/// The six-tile grid, laid out exactly like `NutritionSummaryWidget` with
/// `isExpandedView: false`: left column calories/water/extra, right column
/// protein/carbs/fat.
struct TodayGlanceGrid: View {
  let snapshot: HomeWidgetSnapshot?

  private func tile(_ slot: String) -> HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == slot }
  }

  /// Nothing logged yet for the day the widget is showing.
  ///
  /// Distinct from "no snapshot at all": here the targets are known and worth
  /// showing, so the grid stays and only gains a line explaining why every bar
  /// is empty.
  private var isUntouchedDay: Bool {
    guard let snapshot, !snapshot.tiles.isEmpty else { return false }
    return snapshot.tiles.allSatisfy { $0.value == 0 }
  }

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: TGTheme.gridSpacing) {
        column([tile("calories"), tile("water"), tile("extra")])
        column([tile("protein"), tile("carbs"), tile("fat")])
      }

      if snapshot == nil {
        // The app has never written a snapshot — usually a widget added before
        // the app was opened once. Say what is missing rather than showing six
        // dashes and letting the user guess.
        Text("widget.todayGlance.empty.noData")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      } else if isUntouchedDay {
        Text("widget.todayGlance.empty.noEntries")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
    }
  }

  private func column(_ tiles: [HomeWidgetTile?]) -> some View {
    VStack(spacing: TGTheme.gridSpacing) {
      ForEach(Array(tiles.enumerated()), id: \.offset) { _, tile in
        TodayGlanceBar(tile: tile)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

/// One progress bar.
///
/// Direct port of `GlassProgressBar`'s three-layer structure:
///  1. a solid card,
///  2. the plain text at full width,
///  3. the colour fill plus the same text with a shadow, clipped to the
///     progress ratio and drawn over layer 2.
///
/// Despite the Dart class name there is no blur involved — the app's bar is a
/// solid white / `#1C1C1E` card, which is what makes it reproducible in a
/// widget at all.
struct TodayGlanceBar: View {
  let tile: HomeWidgetTile?

  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.widgetRenderingMode) private var renderingMode

  private var isDark: Bool { colorScheme == .dark }
  private var isAccented: Bool { renderingMode == .accented }

  private var barBackground: Color {
    if isAccented {
      return Color.primary.opacity(0.12)
    }
    return isDark ? Color(white: 0.18) : Color.white
  }

  private var strokeColor: Color {
    if isAccented {
      return Color.primary.opacity(0.25)
    }
    return isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.08)
  }

  /// `GlassProgressBar`'s readability heuristic: a fill that is light in dark
  /// mode (or dark in light mode) gets a scrim so the shadowed text keeps its
  /// contrast against it.
  private var isLowContrast: Bool {
    guard let tile else { return false }
    let luminance = relativeLuminance(ofHex: tile.colorHex)
    return isDark ? luminance > 0.5 : luminance < 0.5
  }

  var body: some View {
    ZStack(alignment: .leading) {
      barBackground

      // Layer 2 — unfilled state, full width, no shadow.
      textContent(withShadow: false, inAccentedFill: false)

      // Layer 3 — the fill and its text, clipped to the progress ratio.
      if let tile, tile.progress > 0 {
        ZStack(alignment: .leading) {
          if isAccented {
            Color.primary.opacity(0.35)
          } else {
            Color(hexString: tile.colorHex)

            if isLowContrast || isDark {
              LinearGradient(
                stops: [
                  .init(color: .black.opacity(isDark ? 0.2 : 0.1), location: 0),
                  .init(color: .clear, location: 0.6),
                ],
                startPoint: .leading,
                endPoint: .trailing
              )
            }
          }

          textContent(withShadow: !isAccented, inAccentedFill: isAccented)
        }
        .mask(alignment: .leading) {
          GeometryReader { geo in
            Rectangle().frame(width: geo.size.width * tile.progress)
          }
        }
      }
    }
    .clipShape(RoundedRectangle(cornerRadius: TGTheme.barRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: TGTheme.barRadius, style: .continuous)
        .stroke(strokeColor, lineWidth: 0.8)
    )
  }

  private func textContent(withShadow: Bool, inAccentedFill: Bool = false) -> some View {
    let filled: Color = inAccentedFill ? .primary : (isDark ? .white : .black)
    let shadowColor = withShadow ? Color.black.opacity(0.3) : Color.clear

    return VStack(alignment: .leading, spacing: 2) {
      Text(tile?.label ?? "—")
        .font(TGTheme.labelFont)
        .foregroundStyle(withShadow || inAccentedFill ? filled : Color.primary)
        .shadow(color: shadowColor, radius: 1, x: 0, y: 1)
        .lineLimit(1)
        .minimumScaleFactor(0.8)

      Text(tile?.valueText ?? "–")
        .font(TGTheme.valueFont)
        .foregroundStyle(withShadow || inAccentedFill ? filled.opacity(0.9) : Color.primary)
        .shadow(color: shadowColor, radius: 1, x: 0, y: 1)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
    .padding(.horizontal, TGTheme.barPaddingH)
    .padding(.vertical, TGTheme.barPaddingV)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

/// WCAG relative luminance, matching Flutter's `Color.computeLuminance()`.
///
/// Only ever compared against 0.5, so parsing the hex directly is enough — no
/// need to round-trip through UIColor.
func relativeLuminance(ofHex hexString: String) -> Double {
  let trimmed = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
  let value = UInt32(trimmed, radix: 16) ?? 0x8E8E93

  func channel(_ shift: UInt32) -> Double {
    let raw = Double((value >> shift) & 0xFF) / 255
    return raw <= 0.03928 ? raw / 12.92 : pow((raw + 0.055) / 1.055, 2.4)
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
}

// MARK: - Lock Screen Views & Wrapper

@available(iOS 18.0, *)
struct TodayGlanceWidgetWrapperView: View {
  let snapshot: HomeWidgetSnapshot?

  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryInline:
      TodayGlanceLockScreenInline(snapshot: snapshot)
        .containerBackground(.clear, for: .widget)
    case .accessoryCircular:
      TodayGlanceLockScreenCircular(snapshot: snapshot)
        .containerBackground(.clear, for: .widget)
    case .accessoryRectangular:
      TodayGlanceLockScreenRectangular(snapshot: snapshot)
        .containerBackground(.clear, for: .widget)
    default:
      TodayGlanceGrid(snapshot: snapshot)
        .padding(TGTheme.containerPadding)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

@available(iOS 18.0, *)
struct TodayGlanceLockScreenInline: View {
  let snapshot: HomeWidgetSnapshot?

  private var caloriesTile: HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == "calories" }
  }

  private var proteinTile: HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == "protein" }
  }

  var body: some View {
    let calVal = Int(caloriesTile?.value ?? 0)
    let proVal = Int(proteinTile?.value ?? 0)
    Text("\(StatsFormat.grouped(calVal)) kcal · \(proVal)g P")
  }
}

@available(iOS 18.0, *)
struct TodayGlanceLockScreenCircular: View {
  let snapshot: HomeWidgetSnapshot?

  private var proteinTile: HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == "protein" }
  }

  var body: some View {
    let val = proteinTile?.value ?? 0
    let target = max(proteinTile?.target ?? 150, 1)
    Gauge(value: val, in: 0...target) {
      Text("Protein")
        .font(.system(size: 9, weight: .bold))
    } currentValueLabel: {
      Text("\(Int(val))")
        .font(.system(size: 13, weight: .bold))
    } minimumValueLabel: {
    } maximumValueLabel: {
    }
    .gaugeStyle(.accessoryCircular)
  }
}

@available(iOS 18.0, *)
struct TodayGlanceLockScreenRectangular: View {
  let snapshot: HomeWidgetSnapshot?

  private var caloriesTile: HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == "calories" }
  }

  private var proteinTile: HomeWidgetTile? {
    snapshot?.tiles.first { $0.slot == "protein" }
  }

  var body: some View {
    let calVal = Int(caloriesTile?.value ?? 0)
    let calTar = Int(caloriesTile?.target ?? 2000)
    let proVal = Int(proteinTile?.value ?? 0)
    let proTar = Int(proteinTile?.target ?? 150)

    VStack(alignment: .leading, spacing: 4) {
      Text("\(StatsFormat.grouped(calVal)) / \(StatsFormat.grouped(calTar)) kcal")
        .font(.system(size: 14, weight: .bold))
        .lineLimit(1)
        .minimumScaleFactor(0.85)

      Text("Protein: \(proVal)g / \(proTar)g")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
}
