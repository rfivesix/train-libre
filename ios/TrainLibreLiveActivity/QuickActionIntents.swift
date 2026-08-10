import AppIntents
import SwiftUI
import WidgetKit

// MARK: - App Deep Link Launcher

@MainActor
private func openAppDeepLink(_ urlString: String) {
  guard let url = URL(string: urlString) else { return }
  if let applicationClass = NSClassFromString("UIApplication") as? NSObject.Type,
     let sharedApplication = applicationClass.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? NSObject {
    let selector = NSSelectorFromString("openURL:options:completionHandler:")
    if sharedApplication.responds(to: selector) {
      typealias OpenURLMethod = @convention(c) (AnyObject, Selector, NSURL, [String: Any], (@convention(block) (Bool) -> Void)?) -> Void
      let method = sharedApplication.method(for: selector)
      let openURL = unsafeBitCast(method, to: OpenURLMethod.self)
      openURL(sharedApplication, selector, url as NSURL, [:], nil)
    }
  }
}

// MARK: - App Intents

@available(iOS 16.0, *)
public struct AIMealCaptureIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.aiMealCapture" }
  public static var description: IntentDescription { "quickAction.aiMealCapture.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/ai_meal_capture")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct ScanBarcodeIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.scanBarcode" }
  public static var description: IntentDescription { "quickAction.scanBarcode.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/scan_barcode")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct StartWorkoutIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.startWorkout" }
  public static var description: IntentDescription { "quickAction.startWorkout.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/start_workout")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct AddMeasurementIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.addMeasurement" }
  public static var description: IntentDescription { "quickAction.addMeasurement.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/add_measurement")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct LogSupplementIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.logSupplement" }
  public static var description: IntentDescription { "quickAction.logSupplement.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/log_supplement")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct AddLiquidIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.addLiquid" }
  public static var description: IntentDescription { "quickAction.addLiquid.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/add_liquid")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct AddFoodIntent: AppIntent {
  public static var title: LocalizedStringResource { "quickAction.addFood" }
  public static var description: IntentDescription { "quickAction.addFood.description" }
  public static var openAppWhenRun: Bool { true }

  public init() {}

  @MainActor
  public func perform() async throws -> some IntentResult {
    openAppDeepLink("trainlibre://action/add_food")
    return .result()
  }
}

// MARK: - Control Center & Lock Screen Controls (iOS 18+)

@available(iOS 18.0, *)
public struct AIMealControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.aiMeal"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: AIMealCaptureIntent()) {
        Label("quickAction.aiMealCapture", systemImage: "sparkles")
      }
    }
    .displayName("quickAction.aiMealCapture")
    .description("quickAction.aiMealCapture.description")
  }
}

@available(iOS 18.0, *)
public struct ScanBarcodeControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.scanBarcode"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: ScanBarcodeIntent()) {
        Label("quickAction.scanBarcode", systemImage: "barcode.viewfinder")
      }
    }
    .displayName("quickAction.scanBarcode")
    .description("quickAction.scanBarcode.description")
  }
}

@available(iOS 18.0, *)
public struct StartWorkoutControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.startWorkout"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: StartWorkoutIntent()) {
        Label("quickAction.startWorkout", systemImage: "dumbbell.fill")
      }
    }
    .displayName("quickAction.startWorkout")
    .description("quickAction.startWorkout.description")
  }
}

@available(iOS 18.0, *)
public struct AddMeasurementControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.addMeasurement"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: AddMeasurementIntent()) {
        Label("quickAction.addMeasurement", systemImage: "ruler")
      }
    }
    .displayName("quickAction.addMeasurement")
    .description("quickAction.addMeasurement.description")
  }
}

@available(iOS 18.0, *)
public struct LogSupplementControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.logSupplement"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: LogSupplementIntent()) {
        Label("quickAction.logSupplement", systemImage: "pills.fill")
      }
    }
    .displayName("quickAction.logSupplement")
    .description("quickAction.logSupplement.description")
  }
}

@available(iOS 18.0, *)
public struct AddLiquidControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.addLiquid"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: AddLiquidIntent()) {
        Label("quickAction.addLiquid", systemImage: "drop.fill")
      }
    }
    .displayName("quickAction.addLiquid")
    .description("quickAction.addLiquid.description")
  }
}

@available(iOS 18.0, *)
public struct AddFoodControlWidget: ControlWidget {
  public static let kind = "com.rfivesix.trainlibre.control.addFood"

  public init() {}

  public var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: Self.kind) {
      ControlWidgetButton(action: AddFoodIntent()) {
        Label("quickAction.addFood", systemImage: "plus.circle.fill")
      }
    }
    .displayName("quickAction.addFood")
    .description("quickAction.addFood.description")
  }
}
