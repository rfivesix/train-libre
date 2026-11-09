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
  private static var _warmSessionPrompt: String? = nil
  // Accessed on the Flutter platform thread; each request owns its task.
  private static var tasks: [String: Task<Void, Never>] = [:]

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

    case "supportsImageInput":
      #if canImport(FoundationModels)
      #if compiler(>=6.4)
      if #available(iOS 27.0, *) {
        result(true)
      } else {
        result(false)
      }
      #else
      result(false)
      #endif
      #else
      result(false)
      #endif

    case "prewarm":
      let systemPrompt = (call.arguments as? [String: Any])?["systemPrompt"] as? String
      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
          Task {
            let session: LanguageModelSession
            if let sysPrompt = systemPrompt, !sysPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
              session = LanguageModelSession(instructions: sysPrompt)
            } else {
              session = LanguageModelSession()
            }
            _warmSession = session
            _warmSessionPrompt = systemPrompt
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

    case "cancel":
      if let id = (call.arguments as? [String: Any])?["requestId"] as? String {
        tasks[id]?.cancel()
      }
      result(nil)

    case "generateMealJson":
      guard let args = call.arguments as? [String: Any],
            let prompt = args["prompt"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Prompt is required", details: nil))
        return
      }

      let systemPrompt = args["systemPrompt"] as? String
      let requestId = args["requestId"] as? String ?? UUID().uuidString
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
        if case .unavailable(let reason) = SystemLanguageModel.default.availability {
          let code: String
          switch reason {
          case .deviceNotEligible: code = "DEVICE_NOT_ELIGIBLE"
          case .appleIntelligenceNotEnabled: code = "APPLE_INTELLIGENCE_DISABLED"
          case .modelNotReady: code = "MODEL_NOT_READY"
          @unknown default: code = "UNAVAILABLE"
          }
          result(FlutterError(code: code, message: nil, details: nil))
          return
        }
        let task = Task {
          do {
            let session: LanguageModelSession
            let trimmedSysPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if let existing = _warmSession as? LanguageModelSession,
               (trimmedSysPrompt.isEmpty || _warmSessionPrompt == systemPrompt) {
              // Reuse prewarmed session with its already cached neural weights and instructions
              session = existing
              _warmSession = nil
              _warmSessionPrompt = nil
            } else if !trimmedSysPrompt.isEmpty {
              // Dedicated instructions parameter separates system prompt from conversation turns
              session = LanguageModelSession(instructions: trimmedSysPrompt)
              _warmSession = nil
              _warmSessionPrompt = nil
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
              tasks.removeValue(forKey: requestId)
              result(responseContent)
            }
          } catch {
            var code = error is CancellationError ? "CANCELLED" : "GENERATION_FAILED"
            if let generationError = error as? LanguageModelSession.GenerationError {
              switch generationError {
              case .rateLimited: code = "RATE_LIMITED"
              case .exceededContextWindowSize: code = "CONTEXT_TOO_LONG"
              case .unsupportedLanguageOrLocale: code = "UNSUPPORTED_LANGUAGE"
              case .decodingFailure: code = "INVALID_RESPONSE"
              default: break
              }
            }
            DispatchQueue.main.async {
              tasks.removeValue(forKey: requestId)
              result(FlutterError(code: code, message: nil, details: nil))
            }
          }
        }
        tasks[requestId] = task
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
