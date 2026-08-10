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
    case "writeSharedFile":
      writeSharedFile(args: call.arguments as? [String: Any], result: result)
    case "sharedFileExists":
      let name = (call.arguments as? [String: Any])?["name"] as? String ?? ""
      guard let url = TrainLibreHomeWidget.sharedFileURL(named: name) else {
        result(false)
        return
      }
      result(FileManager.default.fileExists(atPath: url.path))
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

  /// Stores a binary asset — today only the muscle heatmap — in the App Group
  /// container, where the widget extension can read it as a file.
  ///
  /// Kept out of `UserDefaults`: a PNG is far past what a plist should carry,
  /// and the widget would have to decode it on every timeline render.
  private func writeSharedFile(args: [String: Any]?, result: @escaping FlutterResult) {
    guard
      let name = args?["name"] as? String,
      let url = TrainLibreHomeWidget.sharedFileURL(named: name)
    else {
      result(false)
      return
    }

    // A nil payload is a delete — the app uses it when a workout is removed and
    // its heatmap must not outlive it.
    guard let bytes = args?["bytes"] as? FlutterStandardTypedData else {
      try? FileManager.default.removeItem(at: url)
      Self.reloadTimelines()
      result(true)
      return
    }

    do {
      try bytes.data.write(to: url, options: .atomic)
      Self.sweepSiblings(of: url)
      Self.reloadTimelines()
      result(true)
    } catch {
      result(false)
    }
  }

  /// Removes older files sharing the new file's prefix.
  ///
  /// Heatmaps are named per workout so a snapshot can never point at the wrong
  /// session's map. The cost of that is that every finished workout would leave
  /// a file behind, so the newest write clears the ones it superseded.
  private static func sweepSiblings(of url: URL) {
    let name = url.lastPathComponent
    guard
      let separator = name.range(of: "_", options: .backwards),
      case let prefix = String(name[name.startIndex..<separator.upperBound]),
      !prefix.isEmpty,
      let directory = TrainLibreHomeWidget.containerURL,
      let entries = try? FileManager.default.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil
      )
    else { return }

    for entry in entries
    where entry.lastPathComponent.hasPrefix(prefix) && entry.lastPathComponent != name {
      try? FileManager.default.removeItem(at: entry)
    }
  }

  private static func reloadTimelines() {
    #if canImport(WidgetKit)
      if #available(iOS 18.0, *) {
        for kind in TrainLibreHomeWidget.allKinds {
          WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
      }
    #endif
  }
}
