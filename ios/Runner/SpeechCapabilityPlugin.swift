// ios/Runner/SpeechCapabilityPlugin.swift

import Flutter
import Speech

/// Answers "can this device transcribe locally?" before dictation is started.
///
/// `speech_to_text` cannot be asked this. Worse, when it is told to listen
/// on-device for a locale the recognizer has no local assets for, it reports a
/// `FlutterError` *and* then reports success on the very same result callback —
/// completing one platform message twice, which tears the engine down. Probing
/// here keeps that path from ever being taken.
enum SpeechCapabilityPlugin {
  static let channelName = "trainlibre.speech/capability"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "onDeviceSupported":
      let requested = (call.arguments as? [String: Any])?["localeId"] as? String
      result(supportsOnDevice(localeId: requested))

    case "resolveLocale":
      let requested = (call.arguments as? [String: Any])?["localeId"] as? String
      result(resolveLocale(localeId: requested))

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The recognizer identifier that actually exists for [localeId].
  ///
  /// A bare language tag such as "de" is not one of `supportedLocales()`, and a
  /// recognizer built from it reports no on-device support even where "de-DE"
  /// works perfectly.
  private static func resolveLocale(localeId: String?) -> String? {
    guard let localeId, !localeId.isEmpty else { return nil }
    let normalized = localeId.replacingOccurrences(of: "_", with: "-")
    let supported = SFSpeechRecognizer.supportedLocales().map { $0.identifier }

    if let exact = supported.first(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame })
    {
      return exact
    }

    let language = normalized.split(separator: "-").first.map(String.init)?.lowercased()
    guard let language else { return nil }

    // Prefer the device's own region for that language before any other.
    if let region = Locale.current.regionCode?.uppercased(),
      let regional = supported.first(where: {
        $0.lowercased() == "\(language)-\(region.lowercased())"
      })
    {
      return regional
    }
    return supported.first { $0.lowercased().hasPrefix("\(language)-") }
  }

  private static func supportsOnDevice(localeId: String?) -> Bool {
    let resolved = resolveLocale(localeId: localeId) ?? localeId
    let recognizer: SFSpeechRecognizer?
    if let resolved, !resolved.isEmpty {
      recognizer = SFSpeechRecognizer(locale: Locale(identifier: resolved))
    } else {
      recognizer = SFSpeechRecognizer()
    }
    guard let recognizer, recognizer.isAvailable else { return false }
    if #available(iOS 13.0, *) {
      return recognizer.supportsOnDeviceRecognition
    }
    return false
  }
}
