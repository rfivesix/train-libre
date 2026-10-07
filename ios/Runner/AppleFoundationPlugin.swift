// ios/Runner/AppleFoundationPlugin.swift

import Flutter
import UIKit
import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleFoundationPlugin {
  static let channelName = "trainlibre.ai/apple_foundation"

  private static var _warmSession: Any? = nil

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

    case "prewarm":
      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
          Task {
            let session = LanguageModelSession()
            _warmSession = session
            session.prewarm()
            DispatchQueue.main.async {
              result(true)
            }
          }
          return
        }
      }
      #endif
      result(false)

    case "generateMealJson":
      guard let args = call.arguments as? [String: Any],
            let prompt = args["prompt"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Prompt is required", details: nil))
        return
      }

      let imagesBase64 = (args["images"] as? [String]) ?? []
      var cgImages: [CGImage] = []
      for b64 in imagesBase64 {
        if let data = Data(base64Encoded: b64),
           let uiImage = UIImage(data: data),
           let cgImage = uiImage.cgImage {
          cgImages.append(cgImage)
        }
      }

      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        Task {
          do {
            let session: LanguageModelSession
            if let existing = _warmSession as? LanguageModelSession {
              session = existing
              _warmSession = nil
            } else {
              session = LanguageModelSession()
            }
            let responseContent: String

            #if compiler(>=6.4)
            if #available(iOS 27.0, *), !cgImages.isEmpty {
              // Multimodal prompting using Apple FoundationModels Attachment (iOS 27+)
              let response = try await session.respond {
                prompt
                for img in cgImages {
                  Attachment(img)
                }
              }
              responseContent = response.content
            } else {
              let response = try await session.respond(to: prompt)
              responseContent = response.content
            }
            #else
            let response = try await session.respond(to: prompt)
            responseContent = response.content
            #endif

            DispatchQueue.main.async {
              result(responseContent)
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
