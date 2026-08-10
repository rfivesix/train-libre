import Flutter
import Foundation

#if canImport(WidgetKit)
  import WidgetKit
#endif

/// MethodChannel between the Flutter app and the Home Screen widgets.
///
/// The app is the only writer. Everything arriving here is already a finished
/// JSON snapshot — this class validates it, stores it in the App Group and asks
/// WidgetKit to re-render.
final class HomeWidgetBridge {
  static let channelName = "trainlibre.widgets/home_screen"

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(Self.isSupported)
    case "writeSnapshot":
      writeSnapshot(args: call.arguments as? [String: Any], result: result)
    case "clearSnapshot":
      TrainLibreHomeWidget.defaults?.removeObject(forKey: TrainLibreHomeWidget.snapshotKey)
      Self.reloadTimelines()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The widgets are gated to iOS 18 in the bundle, so anything older can skip
  /// building snapshots altogether rather than write into a void.
  private static var isSupported: Bool {
    #if canImport(WidgetKit)
      if #available(iOS 18.0, *) { return true }
    #endif
    return false
  }

  private func writeSnapshot(args: [String: Any]?, result: @escaping FlutterResult) {
    guard
      let json = args?["json"] as? String,
      let data = json.data(using: .utf8),
      // Decode before storing: a snapshot the widget cannot read is worse than
      // no snapshot, because it would silently freeze the last good render.
      (try? JSONDecoder().decode(HomeWidgetSnapshot.self, from: data)) != nil,
      let defaults = TrainLibreHomeWidget.defaults
    else {
      result(false)
      return
    }

    defaults.set(json, forKey: TrainLibreHomeWidget.snapshotKey)
    Self.reloadTimelines()
    result(true)
  }

  private static func reloadTimelines() {
    #if canImport(WidgetKit)
      if #available(iOS 18.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: TrainLibreHomeWidget.kindTodayGlance)
        WidgetCenter.shared.reloadTimelines(ofKind: TrainLibreHomeWidget.kindQuickActions)
      }
    #endif
  }
}
