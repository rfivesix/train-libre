// ios/Runner/LocalModelPlugin.swift

import Flutter
import UIKit
import Foundation

enum LocalModelPlugin {
  static let channelName = "trainlibre.ai/local_model"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      result(LocalModelRunner.isAvailable())

    case "runInference":
      guard let args = call.arguments as? [String: Any],
            let modelPath = args["modelPath"] as? String,
            let prompt = args["prompt"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "modelPath and prompt are required", details: nil))
        return
      }

      let mmprojPath = args["mmprojPath"] as? String
      let imagesBase64 = (args["images"] as? [String]) ?? []

      let fileManager = FileManager.default
      guard fileManager.fileExists(atPath: modelPath) else {
        result(FlutterError(code: "MODEL_NOT_FOUND", message: "Model file not found at \(modelPath)", details: nil))
        return
      }

      if !imagesBase64.isEmpty && (nullOrEmpty(mmprojPath) || !fileManager.fileExists(atPath: mmprojPath!)) {
        result(FlutterError(
          code: "MMPROJ_MISSING",
          message: "Für die On-Device Bilderkennung wird der Vision-Projektor (mmproj) benötigt. Bitte lade das Modell in den KI-Einstellungen vollständig herunter.",
          details: nil
        ))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let output = try LocalModelRunner.runInference(
            withModelPath: modelPath,
            mmprojPath: mmprojPath,
            prompt: prompt,
            imagesBase64: imagesBase64
          )
          DispatchQueue.main.async {
            result(output)
          }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "LOCAL_INFERENCE_ERROR",
              message: error.localizedDescription,
              details: nil
            ))
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func nullOrEmpty(_ str: String?) -> Bool {
    guard let s = str else { return true }
    return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}


