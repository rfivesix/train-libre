// ios/Runner/AppleFoundationPlugin.swift

import Flutter
import UIKit
import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
private struct DirectNutritionItemEstimate {
  @Guide(description: "Short food or drink name as eaten, in the requested language")
  var name: String

  @Guide(description: "True for drinks measured in ml, false for solid food measured in grams")
  var isFluid: Bool

  @Guide(description: "Total eaten portion weight in grams, or volume in ml for drinks", .range(1...2500))
  var grams: Int

  @Guide(description: "Protein in grams per 100g or 100ml as eaten", .range(0.0...100.0))
  var proteinPer100g: Double

  @Guide(description: "Carbohydrates in grams per 100g or 100ml as eaten", .range(0.0...100.0))
  var carbsPer100g: Double

  @Guide(description: "Fat in grams per 100g or 100ml as eaten", .range(0.0...100.0))
  var fatPer100g: Double

  @Guide(description: "Sugars in grams per 100g or 100ml as eaten, or nil if unknown")
  var sugarPer100g: Double?

  @Guide(description: "Dietary fiber in grams per 100g or 100ml as eaten, or nil if unknown")
  var fiberPer100g: Double?

  @Guide(description: "Salt in grams per 100g or 100ml as eaten, or nil if unknown")
  var saltPer100g: Double?

  @Guide(description: "Caffeine in mg per 100ml or 100g, or nil if none or unknown")
  var caffeineMgPer100g: Double?

  @Guide(description: "Confidence in this item estimate from 0.0 to 1.0", .range(0.0...1.0))
  var confidence: Double
}

@available(iOS 26.0, *)
@Generable
private struct DirectNutritionMealEstimate {
  @Guide(description: "Short meal title in the requested language")
  var dishType: String

  @Guide(description: "Consumed food and drink components, or empty if no food is present", .count(0...10))
  var items: [DirectNutritionItemEstimate]
}
#endif

enum AppleFoundationPlugin {
  static let channelName = "trainlibre.ai/apple_foundation"

  private static var _warmSession: Any? = nil
  private static var _warmSessionPrompt: String? = nil
  // Accessed on the Flutter platform thread; each request owns its task.
  private static var tasks: [String: Task<Void, Never>] = [:]

  #if canImport(FoundationModels)
  @available(iOS 26.0, *)
  private static func makeGenerationOptions(
    from args: [String: Any],
    defaultGreedy: Bool
  ) -> GenerationOptions {
    let greedy = (args["greedy"] as? Bool) ?? defaultGreedy
    let temperature = args["temperature"] as? Double
    if greedy {
      #if compiler(>=6.4)
      return GenerationOptions(samplingMode: .greedy)
      #else
      return GenerationOptions(sampling: .greedy)
      #endif
    }
    if let temperature, temperature.isFinite {
      return GenerationOptions(temperature: max(0.0, temperature))
    }
    return GenerationOptions()
  }

  @available(iOS 26.0, *)
  private static func resolveSession(trimmedSysPrompt: String) -> LanguageModelSession {
    if let existing = _warmSession as? LanguageModelSession,
       (trimmedSysPrompt.isEmpty || _warmSessionPrompt == trimmedSysPrompt) {
      // Reuse prewarmed session with its already cached neural weights and instructions
      _warmSession = nil
      _warmSessionPrompt = nil
      return existing
    }
    _warmSession = nil
    _warmSessionPrompt = nil
    if !trimmedSysPrompt.isEmpty {
      // Dedicated instructions parameter separates system prompt from conversation turns
      return LanguageModelSession(instructions: trimmedSysPrompt)
    }
    return LanguageModelSession()
  }

  @available(iOS 26.0, *)
  private static func encodeDirectNutritionEstimate(
    _ estimate: DirectNutritionMealEstimate
  ) throws -> String {
    func round1(_ value: Double) -> Double {
      (value * 10.0).rounded() / 10.0
    }
    func round2(_ value: Double) -> Double {
      (value * 100.0).rounded() / 100.0
    }
    func clampFinite(_ value: Double, min lower: Double, max upper: Double) -> Double {
      guard value.isFinite else { return lower }
      return Swift.min(Swift.max(value, lower), upper)
    }
    func sanitizeOptional(_ value: Double?, max upper: Double) -> Double? {
      guard let value, value.isFinite, value >= 0.0 else { return nil }
      return Swift.min(value, upper)
    }

    var encodedItems: [[String: Any]] = []
    for item in estimate.items {
      let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !name.isEmpty, item.grams > 0 else { continue }

      var protein = clampFinite(item.proteinPer100g, min: 0.0, max: 100.0)
      var carbs = clampFinite(item.carbsPer100g, min: 0.0, max: 100.0)
      var fat = clampFinite(item.fatPer100g, min: 0.0, max: 100.0)
      let macroSum = protein + carbs + fat
      if macroSum > 100.0 {
        let scale = 100.0 / macroSum
        protein *= scale
        carbs *= scale
        fat *= scale
      }

      var nutrition: [String: Any] = [
        "protein": round1(protein),
        "carbs": round1(carbs),
        "fat": round1(fat),
      ]
      if let sugar = sanitizeOptional(item.sugarPer100g, max: carbs) {
        nutrition["sugar"] = round1(sugar)
      }
      if let fiber = sanitizeOptional(item.fiberPer100g, max: 100.0) {
        nutrition["fiber"] = round1(fiber)
      }
      if let salt = sanitizeOptional(item.saltPer100g, max: 100.0) {
        nutrition["salt"] = round1(salt)
      }
      if let caffeine = sanitizeOptional(item.caffeineMgPer100g, max: 2000.0) {
        nutrition["caffeine"] = round1(caffeine)
      }

      let confidence = clampFinite(item.confidence, min: 0.0, max: 1.0)
      encodedItems.append([
        "name": name,
        "estimatedGrams": item.grams,
        "servedGrams": item.grams,
        "isFluid": item.isFluid,
        "confidence": round2(confidence),
        "nutritionPer100g": nutrition,
      ])
    }

    let payload: [String: Any] = [
      "dishType": estimate.dishType.trimmingCharacters(in: .whitespacesAndNewlines),
      "items": encodedItems,
    ]
    let data = try JSONSerialization.data(withJSONObject: payload, options: [])
    guard let jsonString = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "AppleFoundationPlugin", code: 1)
    }
    return jsonString
  }

  @available(iOS 26.0, *)
  private static func mapGenerationError(_ error: Error) -> String {
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
    return code
  }
  #endif

  private static func decodeImages(from args: [String: Any]) -> [CGImage] {
    let imagesBase64 = (args["images"] as? [String]) ?? []
    var cgImages: [CGImage] = []
    for b64 in imagesBase64 {
      if let data = Data(base64Encoded: b64),
         let uiImage = UIImage(data: data),
         let cgImage = uiImage.cgImage {
        cgImages.append(cgImage)
      }
    }
    return cgImages
  }

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
      let trimmedSysPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      #if canImport(FoundationModels)
      if #available(iOS 26.0, *) {
        let model = SystemLanguageModel.default
        if case .available = model.availability {
          Task {
            let session: LanguageModelSession
            if !trimmedSysPrompt.isEmpty {
              session = LanguageModelSession(instructions: trimmedSysPrompt)
            } else {
              session = LanguageModelSession()
            }
            _warmSession = session
            _warmSessionPrompt = trimmedSysPrompt
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

    case "generateMealJson", "generateDirectMealEstimate":
      guard let args = call.arguments as? [String: Any],
            let prompt = args["prompt"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Prompt is required", details: nil))
        return
      }

      let useDirectGuided = call.method == "generateDirectMealEstimate"
      let systemPrompt = args["systemPrompt"] as? String
      let trimmedSysPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let requestId = args["requestId"] as? String ?? UUID().uuidString
      let cgImages = decodeImages(from: args)

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
        let options = makeGenerationOptions(from: args, defaultGreedy: useDirectGuided)
        let task = Task {
          do {
            let session = resolveSession(trimmedSysPrompt: trimmedSysPrompt)
            let responseContent: String

            if useDirectGuided {
              let estimate: DirectNutritionMealEstimate
              #if compiler(>=6.4)
              if #available(iOS 27.0, *), !cgImages.isEmpty {
                let response = try await session.respond(
                  generating: DirectNutritionMealEstimate.self,
                  options: options
                ) {
                  prompt
                  for img in cgImages {
                    Attachment(img)
                  }
                }
                estimate = response.content
              } else {
                let response = try await session.respond(
                  to: prompt,
                  generating: DirectNutritionMealEstimate.self,
                  options: options
                )
                estimate = response.content
              }
              #else
              let response = try await session.respond(
                to: prompt,
                generating: DirectNutritionMealEstimate.self,
                options: options
              )
              estimate = response.content
              #endif
              responseContent = try encodeDirectNutritionEstimate(estimate)
            } else {
              #if compiler(>=6.4)
              if #available(iOS 27.0, *), !cgImages.isEmpty {
                // Multimodal prompting using Apple FoundationModels Attachment (iOS 27+)
                let response = try await session.respond(options: options) {
                  prompt
                  for img in cgImages {
                    Attachment(img)
                  }
                }
                responseContent = response.content
              } else {
                let response = try await session.respond(to: prompt, options: options)
                responseContent = response.content
              }
              #else
              let response = try await session.respond(to: prompt, options: options)
              responseContent = response.content
              #endif
            }

            DispatchQueue.main.async {
              tasks.removeValue(forKey: requestId)
              result(responseContent)
            }
          } catch {
            let code = mapGenerationError(error)
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
