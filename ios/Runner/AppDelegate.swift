import Flutter
import CryptoKit
import HealthKit
import StoreKit
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()
  private let stepsChannelName = "trainlibre.health/steps"
  private let sleepHealthKitChannelName = "trainlibre.health/sleep_healthkit"
  private let exportAppleHealthChannelName = "trainlibre.health/export_apple_health"
  private let weightImportAppleHealthChannelName = "trainlibre.health/import_weight_apple_health"
  private let reviewChannelName = "trainlibre.app/review"
  private var channelsConfigured = false
  private var depthScanRegistered = false
  private let liveActivityBridge = WorkoutLiveActivityBridge()
  private let homeWidgetBridge = HomeWidgetBridge()
  private var pendingShortcutURL: URL?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    configureChannelsIfNeeded()
    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      enqueueShortcut(shortcutItem)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    configureChannelsIfNeeded()
    if let url = pendingShortcutURL {
      pendingShortcutURL = nil
      openInApp(url)
    }
    super.applicationDidBecomeActive(application)
  }

  /// Parks a Home Screen quick action tapped during a cold launch.
  ///
  /// At that point the Flutter engine is not listening yet, so the link is
  /// replayed from `applicationDidBecomeActive`.
  func enqueueShortcut(_ shortcutItem: UIApplicationShortcutItem) {
    pendingShortcutURL = HomeScreenShortcut.deepLink(for: shortcutItem)
  }

  /// Runs a Home Screen quick action on an app that is already up.
  @discardableResult
  func performShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
    guard let url = HomeScreenShortcut.deepLink(for: shortcutItem) else { return false }
    openInApp(url)
    return true
  }

  /// Feeds a `trainlibre://` deep link straight into the same handler the
  /// widgets and App Intents use, instead of `UIApplication.shared.open(url)`.
  ///
  /// The system `open` call sends the URL out to iOS and relies on it being
  /// routed back into this process — self-opening a custom scheme this way is
  /// unreliable when called from scene-lifecycle/active-transition callbacks,
  /// and was silently swallowing quick actions from the icon long-press menu.
  /// Widgets don't hit this because their URL genuinely arrives from outside
  /// the app (the WidgetKit extension process), so their round trip is real.
  private func openInApp(_ url: URL) {
    _ = application(UIApplication.shared, open: url, options: [:])
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // FlutterAppDelegate does not guarantee an implementation for this selector
    // across iOS/Xcode combinations. Returning an explicit scene configuration
    // avoids a runtime "doesNotRecognizeSelector" crash on app launch.
    let configuration = UISceneConfiguration(
      name: "flutter",
      sessionRole: connectingSceneSession.role
    )
    // Home Screen quick actions are only ever delivered to a scene delegate,
    // never to the app delegate, so the scene needs one. It keeps the window
    // and URL handling with this class, see TrainLibreSceneDelegate.
    configuration.delegateClass = TrainLibreSceneDelegate.self
    return configuration
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    configureChannelsIfNeeded(
      binaryMessenger: engineBridge.applicationRegistrar.messenger(),
      pluginRegistry: engineBridge.pluginRegistry
    )
  }

  private func configureChannelsIfNeeded(
    binaryMessenger: FlutterBinaryMessenger? = nil,
    pluginRegistry: FlutterPluginRegistry? = nil
  ) {
    // Nothing here may run before there is an engine to talk to — asking the
    // app delegate for a plugin registrar that early perturbs registration for
    // every other plugin as well.
    let messenger =
      binaryMessenger
      ?? resolveFlutterViewController()?.binaryMessenger
    guard let messenger else { return }

    // Tracked apart from the method channels: this runs from engine
    // initialisation and again from `applicationDidBecomeActive`, and only one
    // of the two is guaranteed to have a usable plugin registry. Bundling it
    // into `channelsConfigured` meant a nil registrar on the first pass
    // silently left the capture session unregistered for the whole run — Dart
    // then saw `MissingPluginException`, decided the device had no camera
    // session, and fell back to the system camera with no depth.
    registerDepthScanIfNeeded(pluginRegistry: pluginRegistry ?? self)

    guard !channelsConfigured else { return }

    let channel = FlutterMethodChannel(name: stepsChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleStepsCall(call: call, result: result)
    }

    let sleepChannel = FlutterMethodChannel(
      name: sleepHealthKitChannelName,
      binaryMessenger: messenger
    )
    sleepChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleSleepHealthKitCall(call: call, result: result)
    }

    let exportChannel = FlutterMethodChannel(
      name: exportAppleHealthChannelName,
      binaryMessenger: messenger
    )
    exportChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleExportAppleHealthCall(call: call, result: result)
    }

    let weightImportChannel = FlutterMethodChannel(
      name: weightImportAppleHealthChannelName,
      binaryMessenger: messenger
    )
    weightImportChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleAppleHealthWeightImportCall(call: call, result: result)
    }

    let reviewChannel = FlutterMethodChannel(
      name: reviewChannelName,
      binaryMessenger: messenger
    )
    reviewChannel.setMethodCallHandler { call, result in
      guard call.method == "requestReview" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 14.0, *) {
        guard let scene = UIApplication.shared.connectedScenes
          .compactMap({ $0 as? UIWindowScene })
          .first(where: { $0.activationState == .foregroundActive })
        else {
          result(false)
          return
        }
        SKStoreReviewController.requestReview(in: scene)
      } else if #available(iOS 10.3, *) {
        SKStoreReviewController.requestReview()
      }
      result(true)
    }

    let liveActivityChannel = FlutterMethodChannel(
      name: WorkoutLiveActivityBridge.channelName,
      binaryMessenger: messenger
    )
    liveActivityChannel.setMethodCallHandler { [weak self] call, result in
      self?.liveActivityBridge.handle(call: call, result: result)
    }

    let homeWidgetChannel = FlutterMethodChannel(
      name: HomeWidgetBridge.channelName,
      binaryMessenger: messenger
    )
    homeWidgetChannel.setMethodCallHandler { [weak self] call, result in
      self?.homeWidgetBridge.handle(call: call, result: result)
    }

    let imageOpsChannel = FlutterMethodChannel(
      name: ImageOpsPlugin.channelName,
      binaryMessenger: messenger
    )
    imageOpsChannel.setMethodCallHandler { call, result in
      ImageOpsPlugin.handle(call, result: result)
    }

    let speechCapabilityChannel = FlutterMethodChannel(
      name: SpeechCapabilityPlugin.channelName,
      binaryMessenger: messenger
    )
    speechCapabilityChannel.setMethodCallHandler { call, result in
      SpeechCapabilityPlugin.handle(call, result: result)
    }

    channelsConfigured = true
  }

  /// Needs a registrar rather than a bare messenger: the capture session also
  /// vends a platform view for the camera preview. Retried until it succeeds,
  /// because the registry is not necessarily available on the first attempt.
  private func registerDepthScanIfNeeded(pluginRegistry: FlutterPluginRegistry) {
    guard !depthScanRegistered else { return }
    guard let depthRegistrar = pluginRegistry.registrar(forPlugin: "DepthScanPlugin") else {
      return
    }
    DepthScanPlugin.register(with: depthRegistrar)
    depthScanRegistered = true
  }

  private func resolveFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }
    if #available(iOS 13.0, *) {
      for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        for sceneWindow in windowScene.windows {
          if let controller = sceneWindow.rootViewController as? FlutterViewController {
            return controller
          }
        }
      }
    }
    return nil
  }

  private func handleStepsCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "requestPermissions":
      requestHealthKitPermissions(result: result)
    case "requestHeartRatePermissions":
      requestHeartRatePermissions(result: result)
    case "readStepSegments":
      readStepSegments(call: call, result: result)
    case "readHeartRateSamples":
      readHeartRateSamples(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestHealthKitPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
      result(FlutterError(code: "not_available", message: "Step count type unavailable", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func requestHeartRatePermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
      result(FlutterError(code: "not_available", message: "Heart rate type unavailable", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: [heartRateType]) { success, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }
      result(success)
    }
  }

  private func readStepSegments(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String
    else {
      result([])
      return
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let fromDate = formatter.date(from: fromIso),
          let toDate = formatter.date(from: toIso),
          let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)
    else {
      result([])
      return
    }

    let predicate = HKQuery.predicateForSamples(withStart: fromDate, end: toDate, options: [.strictStartDate])
    let query = HKSampleQuery(
      sampleType: stepType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }

      let formatterOut = ISO8601DateFormatter()
      formatterOut.timeZone = TimeZone(secondsFromGMT: 0)
      formatterOut.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
        [
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "stepCount": Int(sample.quantity.doubleValue(for: HKUnit.count())),
          "sourceId": sample.sourceRevision.source.bundleIdentifier,
          "nativeId": sample.uuid.uuidString
        ] as [String: Any]
      }
      result(mapped)
    }
    healthStore.execute(query)
  }

  private func readHeartRateSamples(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String
    else {
      result([])
      return
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let fromDate = formatter.date(from: fromIso),
          let toDate = formatter.date(from: toIso),
          let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
    else {
      result([])
      return
    }

    let heartRateAuthorized =
      healthStore.authorizationStatus(for: heartRateType) == .sharingAuthorized
    if !heartRateAuthorized {
      result(
        FlutterError(
          code: "permission_denied",
          message: "Heart rate permission not granted",
          details: nil
        )
      )
      return
    }

    let predicate = HKQuery.predicateForSamples(
      withStart: fromDate,
      end: toDate,
      options: [.strictStartDate]
    )
    let sortDescriptors = [
      NSSortDescriptor(
        key: HKSampleSortIdentifierStartDate,
        ascending: true
      )
    ]
    let query = HKSampleQuery(
      sampleType: heartRateType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: sortDescriptors
    ) { _, samples, error in
      if let error = error {
        result(FlutterError(code: "query_failed", message: error.localizedDescription, details: nil))
        return
      }

      let formatterOut = ISO8601DateFormatter()
      formatterOut.timeZone = TimeZone(secondsFromGMT: 0)
      formatterOut.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let mapped = (samples as? [HKQuantitySample] ?? []).map { sample in
        [
          "sampledAtUtcIso": formatterOut.string(from: sample.startDate),
          "bpm": sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
          "sourceId": sample.sourceRevision.source.bundleIdentifier,
          "nativeId": sample.uuid.uuidString,
        ] as [String: Any]
      }
      result(mapped)
    }
    healthStore.execute(query)
  }

  private func handleSleepHealthKitCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "checkPermissions":
      result(currentSleepPermissionSnapshot())
    case "requestPermissions":
      requestSleepPermissions(result: result)
    case "readSleepAndHeartRate":
      readSleepAndHeartRate(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleExportAppleHealthCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      result(HKHealthStore.isHealthDataAvailable())
    case "requestPermissions":
      requestExportPermissions(result: result)
    case "writeMeasurement":
      writeMeasurement(call: call, result: result)
    case "writeNutrition":
      writeNutrition(call: call, result: result)
    case "writeHydration":
      writeHydration(call: call, result: result)
    case "writeWorkout":
      writeWorkout(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleAppleHealthWeightImportCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getStatus":
      let available = HKHealthStore.isHealthDataAvailable()
      // HealthKit does not expose whether a read category was granted. A
      // query is the authoritative check and returns permission_denied below.
      result([
        "available": available,
        "historyAvailable": available,
        "readGranted": available,
        "historyGranted": available,
      ])
    case "requestPermissions":
      requestAppleHealthWeightImportPermissions(result: result)
    case "readWeights":
      readAppleHealthWeights(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestAppleHealthWeightImportPermissions(result: @escaping FlutterResult) {
    guard
      HKHealthStore.isHealthDataAvailable(),
      let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
      let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
      let waist = HKObjectType.quantityType(forIdentifier: .waistCircumference)
    else {
      result(false)
      return
    }
    healthStore.requestAuthorization(toShare: [], read: [bodyMass, bodyFat, waist]) { success, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(
            code: self.healthExportErrorCode(error),
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(success)
        }
      }
    }
  }

  private func readAppleHealthWeights(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String,
      let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
      let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
      let waist = HKObjectType.quantityType(forIdentifier: .waistCircumference)
    else {
      result(FlutterError(code: "invalid_args", message: "Weight import requires a time range", details: nil))
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let from = formatter.date(from: fromIso), let to = formatter.date(from: toIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid weight import range", details: nil))
      return
    }

    let range = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
    // Never import Train Libre's own Apple Health export back as a new local
    // measurement. Other sources (scales, Apple Health, and companion apps)
    // retain their original HealthKit UUID as the local import identity.
    let ownSource = HKQuery.predicateForObjects(from: HKSource.default())
    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
      range,
      NSCompoundPredicate(notPredicateWithSubpredicate: ownSource),
    ])
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    let types: [(HKQuantityType, String, HKUnit, Double)] = [
      (bodyMass, "weight", HKUnit.gramUnit(with: .kilo), 1),
      // HealthKit stores body fat as a fraction while Train Libre stores %.
      (bodyFat, "fat_percent", HKUnit.percent(), 100),
      (waist, "waist", HKUnit.meterUnit(with: .centi), 1),
    ]
    let group = DispatchGroup()
    let lock = DispatchQueue(label: "trainlibre.appleHealthMeasurementImport")
    var rows: [[String: Any]] = []
    var queryError: Error?
    for (type, measurementType, unit, multiplier) in types {
      group.enter()
      let query = HKSampleQuery(
        sampleType: type,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: [sort]
      ) { _, samples, error in
        lock.async {
          if queryError == nil, let error { queryError = error }
          for sample in samples as? [HKQuantitySample] ?? [] {
            rows.append([
              "recordId": sample.uuid.uuidString,
              "timestampUtcIso": formatter.string(from: sample.startDate),
              "value": sample.quantity.doubleValue(for: unit) * multiplier,
              "unit": measurementType == "fat_percent" ? "%" : (measurementType == "waist" ? "cm" : "kg"),
              "measurementType": measurementType,
              "sourceBundleId": sample.sourceRevision.source.bundleIdentifier,
            ])
          }
          group.leave()
        }
      }
      healthStore.execute(query)
    }
    group.notify(queue: .main) {
      if let error = queryError {
        result(FlutterError(
          code: self.healthExportErrorCode(error),
          message: error.localizedDescription,
          details: nil
        ))
      } else {
        result(rows.sorted {
          ($0["timestampUtcIso"] as? String ?? "") < ($1["timestampUtcIso"] as? String ?? "")
        })
      }
    }
  }

  private func requestExportPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }
    guard
      let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass),
      let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage),
      let bmi = HKObjectType.quantityType(forIdentifier: .bodyMassIndex),
      let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
      let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
      let dietaryProtein = HKObjectType.quantityType(forIdentifier: .dietaryProtein),
      let dietaryCarbs = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates),
      let dietaryFat = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal),
      let dietaryFiber = HKObjectType.quantityType(forIdentifier: .dietaryFiber),
      let dietarySugar = HKObjectType.quantityType(forIdentifier: .dietarySugar),
      let dietarySodium = HKObjectType.quantityType(forIdentifier: .dietarySodium),
      let hydration = HKObjectType.quantityType(forIdentifier: .dietaryWater)
    else {
      result(false)
      return
    }
    let workout = HKObjectType.workoutType()

    let shareTypes: Set<HKSampleType> = [
      bodyMass, bodyFat, bmi, activeEnergy, dietaryEnergy, dietaryProtein,
      dietaryCarbs, dietaryFat, dietaryFiber, dietarySugar, dietarySodium,
      hydration, workout,
    ]
    let readTypes: Set<HKObjectType> = [
      bodyMass, bodyFat, bmi, dietaryEnergy, dietaryProtein, dietaryCarbs,
      dietaryFat, dietaryFiber, dietarySugar, dietarySodium, hydration,
      workout,
    ]

    // Recovery queries need read access to find and validate this app's
    // previously written revisions before older objects can be removed.
    healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
      DispatchQueue.main.async {
        if let error {
          result(FlutterError(
            code: self.healthExportErrorCode(error),
            message: error.localizedDescription,
            details: nil
          ))
        } else {
          result(success)
        }
      }
    }
  }

  private func writeMeasurement(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String,
          let typeRaw = args["type"] as? String,
          let rawValue = args["value"] as? NSNumber else {
      result(FlutterError(code: "invalid_args", message: "Invalid measurement payload", details: nil))
      return
    }
    let value = rawValue.doubleValue
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    let quantityType: HKQuantityType?
    let unit: HKUnit
    switch typeRaw {
    case "weight":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyMass)
      unit = HKUnit.gramUnit(with: .kilo)
    case "bodyFatPercentage":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)
      unit = HKUnit.percent()
    case "bmi":
      quantityType = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)
      unit = HKUnit.count()
    default:
      result(FlutterError(code: "invalid_args", message: "Unsupported measurement type", details: nil))
      return
    }

    guard let resolvedType = quantityType else {
      result(FlutterError(code: "not_available", message: "Measurement type unavailable", details: nil))
      return
    }

    let adjustedValue = typeRaw == "bodyFatPercentage" ? value / 100.0 : value
    let quantity = HKQuantity(unit: unit, doubleValue: adjustedValue)
    let sample = HKQuantitySample(type: resolvedType, quantity: quantity, start: timestamp, end: timestamp, metadata: exportMetadata(args))
    saveRevisionedSamples([sample], result: result)
  }

  private func writeNutrition(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Invalid nutrition payload", details: nil))
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    var samples: [HKQuantitySample] = []
    func value(_ key: String) -> Double? {
      return (args[key] as? NSNumber)?.doubleValue
    }
    func appendSample(_ identifier: HKQuantityTypeIdentifier, _ value: Double?, _ unit: HKUnit) {
      guard let value = value, let type = HKObjectType.quantityType(forIdentifier: identifier) else { return }
      let quantity = HKQuantity(unit: unit, doubleValue: value)
      samples.append(HKQuantitySample(type: type, quantity: quantity, start: timestamp, end: timestamp, metadata: exportMetadata(args, suffix: identifier.rawValue)))
    }

    appendSample(.dietaryEnergyConsumed, value("caloriesKcal"), HKUnit.kilocalorie())
    appendSample(.dietaryProtein, value("proteinGrams"), HKUnit.gram())
    appendSample(.dietaryCarbohydrates, value("carbsGrams"), HKUnit.gram())
    appendSample(.dietaryFatTotal, value("fatGrams"), HKUnit.gram())
    appendSample(.dietaryFiber, value("fiberGrams"), HKUnit.gram())
    appendSample(.dietarySugar, value("sugarGrams"), HKUnit.gram())
    appendSample(.dietarySodium, value("sodiumGrams"), HKUnit.gram())

    if samples.isEmpty {
      result(true)
      return
    }

    saveRevisionedSamples(samples, result: result)
  }

  private func writeHydration(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let timestampIso = args["timestampUtcIso"] as? String,
          let litersRaw = args["volumeLiters"] as? NSNumber,
          let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
      result(FlutterError(code: "invalid_args", message: "Invalid hydration payload", details: nil))
      return
    }
    let liters = litersRaw.doubleValue
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let timestamp = formatter.date(from: timestampIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid timestamp", details: nil))
      return
    }

    let quantity = HKQuantity(unit: HKUnit.liter(), doubleValue: liters)
    let sample = HKQuantitySample(type: type, quantity: quantity, start: timestamp, end: timestamp, metadata: exportMetadata(args))
    saveRevisionedSamples([sample], result: result)
  }

  private func writeWorkout(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let startIso = args["startUtcIso"] as? String,
          let endIso = args["endUtcIso"] as? String else {
      result(FlutterError(code: "invalid_args", message: "Invalid workout payload", details: nil))
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let start = formatter.date(from: startIso), let end = formatter.date(from: endIso) else {
      result(FlutterError(code: "invalid_args", message: "Invalid workout time range", details: nil))
      return
    }

    let typeRaw = (args["workoutType"] as? String) ?? "strength"
    let workoutType: HKWorkoutActivityType
    switch typeRaw {
    case "running":
      workoutType = .running
    case "walking":
      workoutType = .walking
    case "cycling":
      workoutType = .cycling
    case "yoga":
      workoutType = .yoga
    default:
      workoutType = .traditionalStrengthTraining
    }

    let calories = (args["caloriesBurnedKcal"] as? NSNumber).map {
      HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0.doubleValue)
    }
    let summaryNotes = (args["notes"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    var metadata = exportMetadata(args)
    if let summaryNotes, !summaryNotes.isEmpty {
      // HealthKit workout has no dedicated notes field; persist summary in metadata.
      metadata["trainlibre_workout_summary"] = summaryNotes
    }
    let duration = end.timeIntervalSince(start)
    let workout = HKWorkout(
      activityType: workoutType,
      start: start,
      end: end,
      duration: duration,
      totalEnergyBurned: calories,
      totalDistance: nil,
      metadata: metadata.isEmpty ? nil : metadata
    )
    saveRevisionedSamples([workout], result: result)
  }

  private func exportMetadata(_ args: [String: Any], suffix: String? = nil) -> [String: Any] {
    let base = (args["externalId"] as? String) ?? (args["idempotencyKey"] as? String)
    guard let base, !base.isEmpty else { return [:] }
    let revision = (args["exportRevision"] as? NSNumber)?.int64Value ?? 0
    let externalID = suffix.map { deterministicUUID("\(base):\($0)") } ?? base
    return [
      HKMetadataKeyExternalUUID: externalID,
      "trainlibre_export_revision": revision,
    ]
  }

  private func deterministicUUID(_ value: String) -> String {
    var bytes = Array(SHA256.hash(data: Data(value.utf8)).prefix(16))
    bytes[6] = (bytes[6] & 0x0f) | 0x50
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    let hex = bytes.map { String(format: "%02x", $0) }.joined()
    return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
  }

  /// HealthKit does not upsert by external UUID. Keep the previous complete
  /// revision until the new one has been saved and verified, then remove only
  /// older objects from this app. A retry repairs a partial newer revision.
  private func saveRevisionedSamples(
    _ samples: [HKSample],
    result: @escaping FlutterResult
  ) {
    guard !samples.isEmpty else {
      result(true)
      return
    }
    for sample in samples where healthStore.authorizationStatus(for: sample.sampleType) != .sharingAuthorized {
      result(FlutterError(
        code: "permission_denied",
        message: "Apple Health write permission is required for \(sample.sampleType.identifier)",
        details: nil
      ))
      return
    }

    let revision = (samples[0].metadata?["trainlibre_export_revision"] as? NSNumber)?.int64Value ?? 0
    var expected: [String: HKSampleType] = [:]
    for sample in samples {
      guard let externalID = sample.metadata?[HKMetadataKeyExternalUUID] as? String else {
        healthStore.save(samples) { success, error in
          if let error {
            result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
          } else {
            result(success)
          }
        }
        return
      }
      expected[externalID] = sample.sampleType
    }

    fetchOwnSamples(expected) { [weak self] existing, error in
      guard let self else { return }
      if let error {
        result(FlutterError(code: self.healthExportErrorCode(error), message: error.localizedDescription, details: nil))
        return
      }
      let complete = expected.keys.allSatisfy { externalID in
        (existing[externalID] ?? []).contains { self.exportRevision(of: $0) == revision }
      }
      if complete {
        self.cleanupOlderRevisions(existing, keeping: revision, result: result)
        return
      }

      let partialTarget = existing.values.flatMap { $0 }.filter {
        self.exportRevision(of: $0) == revision
      }
      self.deleteObjects(partialTarget) { deleteError in
        if let deleteError {
          result(FlutterError(code: "write_failed", message: deleteError.localizedDescription, details: nil))
          return
        }
        self.healthStore.save(samples) { success, saveError in
          guard success, saveError == nil else {
            result(FlutterError(
              code: "write_failed",
              message: saveError?.localizedDescription ?? "Apple Health save failed",
              details: nil
            ))
            return
          }
          self.fetchOwnSamples(expected) { verified, verifyError in
            if let verifyError {
              result(FlutterError(code: self.healthExportErrorCode(verifyError), message: verifyError.localizedDescription, details: nil))
              return
            }
            let verifiedComplete = expected.keys.allSatisfy { externalID in
              (verified[externalID] ?? []).contains {
                self.exportRevision(of: $0) == revision
              }
            }
            guard verifiedComplete else {
              result(FlutterError(code: "write_failed", message: "Apple Health revision verification failed", details: nil))
              return
            }
            self.cleanupOlderRevisions(verified, keeping: revision, result: result)
          }
        }
      }
    }
  }

  private func fetchOwnSamples(
    _ expected: [String: HKSampleType],
    completion: @escaping ([String: [HKSample]], Error?) -> Void
  ) {
    let group = DispatchGroup()
    let lock = NSLock()
    var found: [String: [HKSample]] = [:]
    var firstError: Error?

    for (externalID, type) in expected {
      group.enter()
      let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
        HKQuery.predicateForObjects(from: HKSource.default()),
        HKQuery.predicateForObjects(
          withMetadataKey: HKMetadataKeyExternalUUID,
          allowedValues: [externalID]
        ),
      ])
      let query = HKSampleQuery(
        sampleType: type,
        predicate: predicate,
        limit: HKObjectQueryNoLimit,
        sortDescriptors: nil
      ) { _, samples, error in
        lock.lock()
        found[externalID] = samples ?? []
        if firstError == nil { firstError = error }
        lock.unlock()
        group.leave()
      }
      healthStore.execute(query)
    }
    group.notify(queue: .global(qos: .utility)) {
      completion(found, firstError)
    }
  }

  private func cleanupOlderRevisions(
    _ existing: [String: [HKSample]],
    keeping revision: Int64,
    result: @escaping FlutterResult
  ) {
    var toDelete: [HKSample] = []
    for samples in existing.values {
      let current = samples.filter { exportRevision(of: $0) == revision }
      toDelete.append(contentsOf: samples.filter { exportRevision(of: $0) < revision })
      if current.count > 1 {
        toDelete.append(contentsOf: current.dropFirst())
      }
    }
    deleteObjects(toDelete) { error in
      if let error {
        result(FlutterError(code: "write_failed", message: error.localizedDescription, details: nil))
      } else {
        result(true)
      }
    }
  }

  private func deleteObjects(_ objects: [HKSample], completion: @escaping (Error?) -> Void) {
    guard !objects.isEmpty else {
      completion(nil)
      return
    }
    healthStore.delete(objects.map { $0 as HKObject }) { success, error in
      completion(success ? nil : (error ?? NSError(
        domain: "TrainLibreHealthExport",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Apple Health cleanup failed"]
      )))
    }
  }

  private func exportRevision(of sample: HKSample) -> Int64 {
    return (sample.metadata?["trainlibre_export_revision"] as? NSNumber)?.int64Value ?? -1
  }

  private func healthExportErrorCode(_ error: Error) -> String {
    let nsError = error as NSError
    guard nsError.domain == HKErrorDomain else { return "write_failed" }
    let permissionCodes = [
      HKError.Code.errorAuthorizationDenied.rawValue,
      HKError.Code.errorAuthorizationNotDetermined.rawValue,
    ]
    return permissionCodes.contains(nsError.code) ? "permission_denied" : "write_failed"
  }

  private func requestSleepPermissions(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }
    guard
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)
    else {
      result(FlutterError(code: "not_available", message: "Sleep/HR types unavailable", details: nil))
      return
    }

    healthStore.requestAuthorization(toShare: nil, read: [sleepType, heartRateType]) { [weak self] success, error in
      if let error = error {
        result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
        return
      }
      if !success {
        result(self?.currentSleepPermissionSnapshot() ?? ["sleepGranted": false, "heartRateGranted": false])
        return
      }
      result(self?.currentSleepPermissionSnapshot() ?? ["sleepGranted": false, "heartRateGranted": false])
    }
  }

  private func currentSleepPermissionSnapshot() -> [String: Any] {
    let available = HKHealthStore.isHealthDataAvailable()
    return ["sleepGranted": available, "heartRateGranted": available]
  }

  private func readSleepAndHeartRate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(FlutterError(code: "not_available", message: "HealthKit unavailable", details: nil))
      return
    }
    guard
      let args = call.arguments as? [String: Any],
      let fromIso = args["fromUtcIso"] as? String,
      let toIso = args["toUtcIso"] as? String
    else {
      result(["sessions": [], "stageSegments": [], "heartRateSamples": []])
      return
    }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard
      let fromDate = formatter.date(from: fromIso),
      let toDate = formatter.date(from: toIso),
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let heartType = HKObjectType.quantityType(forIdentifier: .heartRate)
    else {
      result(["sessions": [], "stageSegments": [], "heartRateSamples": []])
      return
    }
    let predicate = HKQuery.predicateForSamples(
      withStart: fromDate,
      end: toDate,
      options: [.strictStartDate]
    )

    let dispatch = DispatchGroup()
    var sleepSamples: [HKCategorySample] = []
    var heartSamples: [HKQuantitySample] = []
    var queryError: Error?

    dispatch.enter()
    let sleepQuery = HKSampleQuery(
      sampleType: sleepType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error { queryError = error }
      sleepSamples = (samples as? [HKCategorySample]) ?? []
      dispatch.leave()
    }
    healthStore.execute(sleepQuery)

    dispatch.enter()
    let hrQuery = HKSampleQuery(
      sampleType: heartType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, error in
      if let error = error { queryError = error }
      heartSamples = (samples as? [HKQuantitySample]) ?? []
      dispatch.leave()
    }
    healthStore.execute(hrQuery)

    dispatch.notify(queue: .main) {
      if let queryError = queryError {
        result(FlutterError(code: "query_failed", message: queryError.localizedDescription, details: nil))
        return
      }
      let formatterOut = ISO8601DateFormatter()
      formatterOut.timeZone = TimeZone(secondsFromGMT: 0)
      formatterOut.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let sessions: [[String: Any]] = sleepSamples.map { sample in
        [
          "recordId": sample.uuid.uuidString,
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "platformSessionType": "sleep",
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }
      let stageSegments: [[String: Any]] = sleepSamples.map { sample in
        [
          "recordId": "stage-\(sample.uuid.uuidString)",
          "sessionRecordId": sample.uuid.uuidString,
          "startAtUtcIso": formatterOut.string(from: sample.startDate),
          "endAtUtcIso": formatterOut.string(from: sample.endDate),
          "platformStage": self.mapHealthKitSleepValue(sample.value),
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }

      let hrRows: [[String: Any]] = heartSamples.compactMap { sample in
          guard let session = sleepSamples.first(where: { self.overlap(sample.startDate, sample.endDate, $0.startDate, $0.endDate) }) else {
          return nil
        }
        return [
          "recordId": sample.uuid.uuidString,
          "sessionRecordId": session.uuid.uuidString,
          "sampledAtUtcIso": formatterOut.string(from: sample.startDate),
          "bpm": sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
          "sourcePlatform": "apple_healthkit",
          "sourceAppId": sample.sourceRevision.source.bundleIdentifier,
          "sourceRecordHash": sample.uuid.uuidString
        ]
      }
      result([
        "sessions": sessions,
        "stageSegments": stageSegments,
        "heartRateSamples": hrRows
      ])
    }
  }

  private func mapHealthKitSleepValue(_ value: Int) -> String {
    if #available(iOS 16.0, *) {
      switch value {
      case HKCategoryValueSleepAnalysis.inBed.rawValue:
        return "in_bed"
      case HKCategoryValueSleepAnalysis.awake.rawValue:
        return "awake"
      case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
        return "core"
      case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
        return "deep"
      case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
        return "rem"
      case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
        return "asleep_unspecified"
      default:
        return "asleep"
      }
    } else {
      switch value {
      case HKCategoryValueSleepAnalysis.inBed.rawValue:
        return "in_bed"
      case HKCategoryValueSleepAnalysis.awake.rawValue:
        return "awake"
      default:
        return "asleep"
      }
    }
  }

  private func overlap(_ aStart: Date, _ aEnd: Date, _ bStart: Date, _ bEnd: Date) -> Bool {
    return aStart < bEnd && aEnd > bStart
  }

}
