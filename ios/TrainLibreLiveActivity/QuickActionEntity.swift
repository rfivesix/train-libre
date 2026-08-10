import AppIntents
import SwiftUI

/// The actions a quick-access tile can trigger.
///
/// Raw values are the deep-link keys and must stay in lockstep with
/// `HomeWidgetAction` in `lib/features/home_widgets/home_widget_deep_link.dart`
/// and with the `action` strings in `MainScreen._executeAddMenuAction`. A
/// mismatch produces a tile that opens the app and then silently does nothing.
///
/// ## Why an `AppEnum` and not an `AppEntity`
///
/// The first version modelled these as an `AppEntity` with an `EntityQuery`, so
/// the picker could hide AI meal capture while the user has AI switched off.
/// The picker worked, but **the selection never reached the widget**: an entity
/// parameter is persisted as a dynamic-option token that has to be resolved
/// through the query, and that resolution came back empty, so every slot fell
/// back to its default no matter what was chosen. An `AppEnum` is stored as its
/// raw value (`dayMode = followApp` in the widget configuration is proof it
/// round-trips) and simply works.
///
/// The cost is that the picker can no longer hide the AI action. That is
/// handled where it is harmless instead: the tile renders dimmed when AI is
/// off, and the deep link falls back to the diary rather than opening a screen
/// the app has disabled.
enum QuickActionKind: String, AppEnum, CaseIterable {
  case aiMealCapture = "ai_meal_capture"
  case scanBarcode = "scan_barcode"
  case startWorkout = "start_workout"
  case addMeasurement = "add_measurement"
  case logSupplement = "log_supplement"
  case addLiquid = "add_liquid"

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "quickAction.type")
  }

  static var caseDisplayRepresentations: [QuickActionKind: DisplayRepresentation] {
    [
      .aiMealCapture: .init(
        title: "quickAction.aiMealCapture", image: .init(systemName: "sparkles")),
      .scanBarcode: .init(
        title: "quickAction.scanBarcode", image: .init(systemName: "barcode.viewfinder")),
      .startWorkout: .init(
        title: "quickAction.startWorkout", image: .init(systemName: "dumbbell.fill")),
      .addMeasurement: .init(
        title: "quickAction.addMeasurement", image: .init(systemName: "ruler")),
      .logSupplement: .init(
        title: "quickAction.logSupplement", image: .init(systemName: "pills.fill")),
      .addLiquid: .init(
        title: "quickAction.addLiquid", image: .init(systemName: "drop.fill")),
    ]
  }

  /// SF Symbols rather than the app's Lucide glyphs: the brief asks for the
  /// Shortcuts widget's look, and that is drawn with SF Symbols.
  var systemImage: String {
    switch self {
    case .aiMealCapture: return "sparkles"
    case .scanBarcode: return "barcode.viewfinder"
    case .startWorkout: return "dumbbell.fill"
    case .addMeasurement: return "ruler"
    case .logSupplement: return "pills.fill"
    case .addLiquid: return "drop.fill"
    }
  }

  var titleKey: LocalizedStringResource {
    switch self {
    case .aiMealCapture: return "quickAction.aiMealCapture"
    case .scanBarcode: return "quickAction.scanBarcode"
    case .startWorkout: return "quickAction.startWorkout"
    case .addMeasurement: return "quickAction.addMeasurement"
    case .logSupplement: return "quickAction.logSupplement"
    case .addLiquid: return "quickAction.addLiquid"
    }
  }

  /// Mirrors the speed dial's colour language so the widget reads as Train
  /// Libre rather than as a generic Shortcuts grid.
  var tint: Color {
    switch self {
    case .aiMealCapture: return Color(hex: 0x7C5CFF)
    case .scanBarcode: return Color(hex: 0x2196F3)
    case .startWorkout: return Color(hex: 0xE5253A)
    case .addMeasurement: return Color(hex: 0x66BB6A)
    case .logSupplement: return Color(hex: 0xBA68C8)
    case .addLiquid: return Color(hex: 0x00A9C4)
    }
  }

  /// The AI action carries the app's gradient instead of a flat fill.
  var gradient: LinearGradient? {
    guard self == .aiMealCapture else { return nil }
    return LinearGradient(
      colors: [Color(hex: 0x7C5CFF), Color(hex: 0xE5253A)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  var deepLink: URL? {
    URL(string: "trainlibre://action/\(rawValue)")
  }
}
