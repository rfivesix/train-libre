// ios/Runner/AppleFoundationPlugin.swift

import Flutter
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleFoundationPlugin {
  static let channelName = "trainlibre.ai/apple_foundation"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
          result(true)
        default:
          result(false)
        }
      } else {
        result(false)
      }
      #else
      result(false)
      #endif

    case "generateMealJson":
      guard let args = call.arguments as? [String: Any],
            let prompt = args["prompt"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Prompt is required", details: nil))
        return
      }

      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        Task {
          do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            DispatchQueue.main.async {
              result(response.content)
            }
          } catch {
            DispatchQueue.main.async {
              result(FlutterError(code: "GENERATION_FAILED", message: error.localizedDescription, details: nil))
            }
          }
        }
      } else {
        result(FlutterError(code: "UNSUPPORTED_IOS_VERSION", message: "FoundationModels requires iOS 26+", details: nil))
      }
      #else
      result(FlutterError(code: "FRAMEWORK_UNAVAILABLE", message: "FoundationModels framework not present in this build", details: nil))
      #endif

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
