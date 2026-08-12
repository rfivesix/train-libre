import AppIntents
import SwiftUI
import UIKit

// MARK: - Home Screen Quick Actions (long press on the app icon)

/// The two static `UIApplicationShortcutItems` declared in `Info.plist`.
///
/// iOS shows at most four entries in the icon menu; we deliberately spend only
/// two of them on the actions that carry the app's daily use.
enum HomeScreenShortcut: String {
  case addFood = "com.rfivesix.trainlibre.shortcut.addFood"
  case startWorkout = "com.rfivesix.trainlibre.shortcut.startWorkout"

  /// The action key shared with the widgets and App Intents, see
  /// `HomeWidgetAction` on the Dart side.
  var actionKey: String {
    switch self {
    case .addFood: return "add_food"
    case .startWorkout: return "start_workout"
    }
  }

  static func deepLink(for item: UIApplicationShortcutItem) -> URL? {
    guard let shortcut = HomeScreenShortcut(rawValue: item.type) else { return nil }
    return URL(string: "trainlibre://action/\(shortcut.actionKey)")
  }
}

// MARK: - App Shortcuts Provider (Main App Target Only)

@available(iOS 16.0, *)
public struct TrainLibreAppShortcuts: AppShortcutsProvider {
  @AppShortcutsBuilder
  public static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AIMealCaptureIntent(),
      phrases: [
        "Erfasse Mahlzeit in \(.applicationName)",
        "AI Mahlzeit scannen in \(.applicationName)",
        "Mahlzeit mit Foto erfassen in \(.applicationName)",
      ],
      shortTitle: "quickAction.aiMealCapture",
      systemImageName: "sparkles"
    )
    AppShortcut(
      intent: ScanBarcodeIntent(),
      phrases: [
        "Scanne Barcode in \(.applicationName)",
        "Barcode scannen mit \(.applicationName)",
      ],
      shortTitle: "quickAction.scanBarcode",
      systemImageName: "barcode.viewfinder"
    )
    AppShortcut(
      intent: StartWorkoutIntent(),
      phrases: [
        "Starte Workout in \(.applicationName)",
        "Workout beginnen in \(.applicationName)",
      ],
      shortTitle: "quickAction.startWorkout",
      systemImageName: "dumbbell.fill"
    )
    AppShortcut(
      intent: AddMeasurementIntent(),
      phrases: [
        "Füge Messung hinzu in \(.applicationName)",
        "Messung eintragen in \(.applicationName)",
      ],
      shortTitle: "quickAction.addMeasurement",
      systemImageName: "ruler"
    )
    AppShortcut(
      intent: LogSupplementIntent(),
      phrases: [
        "Trage Nahrungsergänzung ein in \(.applicationName)",
        "Supplement eintragen in \(.applicationName)",
      ],
      shortTitle: "quickAction.logSupplement",
      systemImageName: "pills.fill"
    )
    AppShortcut(
      intent: AddLiquidIntent(),
      phrases: [
        "Trage Flüssigkeit ein in \(.applicationName)",
        "Wasser eintragen in \(.applicationName)",
      ],
      shortTitle: "quickAction.addLiquid",
      systemImageName: "drop.fill"
    )
    AppShortcut(
      intent: AddFoodIntent(),
      phrases: [
        "Füge Lebensmittel hinzu in \(.applicationName)",
        "Lebensmittel eintragen in \(.applicationName)",
      ],
      shortTitle: "quickAction.addFood",
      systemImageName: "plus.circle.fill"
    )
  }
}
