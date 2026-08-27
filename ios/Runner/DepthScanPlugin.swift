// ios/Runner/DepthScanPlugin.swift

import AVFoundation
import Flutter
import ImageIO
import UIKit

/// Bridges the unified capture session to Flutter.
///
/// One `AVCaptureSession` drives all three outputs the meal capture screen needs:
/// the live preview (via a platform view), passive barcode detection (via an
/// event channel) and the still photo with its depth map (via a method call).
/// Running separate sessions per feature does not work — only one client can own
/// the back camera at a time.
public class DepthScanPlugin: NSObject {
  public static let channelName = "com.trainlibre.app/depth_scan"
  public static let barcodeChannelName = "com.trainlibre.app/depth_scan/barcodes"
  public static let previewViewType = "com.trainlibre.app/depth_scan_preview"

  private static var instance: DepthScanPlugin?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = DepthScanPlugin()
    instance = plugin

    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      plugin.handle(call, result: result)
    }

    let barcodeChannel = FlutterEventChannel(
      name: barcodeChannelName,
      binaryMessenger: registrar.messenger()
    )
    barcodeChannel.setStreamHandler(BarcodeStreamHandler.shared)

    registrar.register(
      DepthScanPreviewFactory(),
      withId: previewViewType
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capability":
      result([
        "supported": DepthScanController.isLiDARSupported(),
        "cameraAvailable": DepthScanController.isCameraAvailable(),
        "reason": DepthScanController.isLiDARSupported()
          ? nil : "Device lacks a built-in LiDAR depth camera",
      ])

    case "start":
      DepthScanController.shared.start { started in
        result(started)
      }

    case "stop":
      DepthScanController.shared.stop()
      result(true)

    case "capture":
      DepthScanController.shared.capturePhotoWithDepth { response, failure in
        if let response {
          result(response)
        } else {
          // An explicit error rather than a bare nil: Dart used to treat every
          // failure here as "this device has no capture session" and quietly
          // opened the system camera instead, which is exactly how a broken
          // session turned into permanently missing depth data.
          result(
            FlutterError(
              code: "capture_failed",
              message: failure ?? "Photo capture failed",
              details: nil
            )
          )
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Barcode stream

/// Forwards passively detected barcodes to Dart.
///
/// Deliberately stateless about which codes were seen before: de-duplication is
/// the Dart side's job, because only it knows whether the user already dismissed
/// a suggestion.
final class BarcodeStreamHandler: NSObject, FlutterStreamHandler {
  static let shared = BarcodeStreamHandler()

  private var sink: FlutterEventSink?

  /// Guards `lastValue`/`lastEmit`, which are written from the metadata queue
  /// and read from nowhere else — but the sink itself is main-thread only.
  private let gate = NSLock()
  private var lastValue: String?
  private var lastEmit: TimeInterval = 0

  /// How long the same code stays suppressed after it was forwarded once.
  ///
  /// `AVCaptureMetadataOutput` reports a code in *every* frame it stays visible
  /// in, so without this the stream fires 30–60 times a second for as long as
  /// the barcode is in view. Each of those was a main-queue hop plus a platform
  /// channel message, which pinned the UI thread and made the screen look
  /// frozen from the moment the first code was recognised.
  private static let repeatInterval: TimeInterval = 2.0

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    gate.lock()
    lastValue = nil
    lastEmit = 0
    gate.unlock()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(_ value: String) {
    let now = Date().timeIntervalSinceReferenceDate
    gate.lock()
    let suppressed = value == lastValue && now - lastEmit < BarcodeStreamHandler.repeatInterval
    if !suppressed {
      lastValue = value
      lastEmit = now
    }
    gate.unlock()
    guard !suppressed else { return }

    DispatchQueue.main.async { [weak self] in
      self?.sink?(value)
    }
  }
}

// MARK: - Preview platform view

final class DepthScanPreviewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return DepthScanPreviewPlatformView(frame: frame)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

/// UIView whose backing layer *is* the preview layer, so it resizes with the
/// view instead of needing manual frame bookkeeping.
final class CameraPreviewUIView: UIView {
  override class var layerClass: AnyClass {
    return AVCaptureVideoPreviewLayer.self
  }

  var previewLayer: AVCaptureVideoPreviewLayer {
    // swiftlint:disable:next force_cast
    return layer as! AVCaptureVideoPreviewLayer
  }
}

final class DepthScanPreviewPlatformView: NSObject, FlutterPlatformView {
  private let previewView: CameraPreviewUIView

  init(frame: CGRect) {
    previewView = CameraPreviewUIView(frame: frame)
    previewView.backgroundColor = .black
    previewView.previewLayer.videoGravity = .resizeAspectFill
    super.init()
    DepthScanController.shared.attach(previewLayer: previewView.previewLayer)
  }

  func view() -> UIView {
    return previewView
  }

  deinit {
    DepthScanController.shared.detach(previewLayer: previewView.previewLayer)
  }
}

// MARK: - Image helper

enum ImageDownscaler {
  /// Downscales `sourcePath` so its longest edge is at most `maxSize` and writes
  /// it as JPEG. Used for meal photo thumbnails, which is why it runs natively:
  /// Flutter ships no JPEG encoder and pulling in an image library for one
  /// resize would not be proportionate.
  static func write(
    sourcePath: String,
    targetPath: String,
    maxSize: CGFloat,
    quality: CGFloat
  ) -> Bool {
    guard let image = UIImage(contentsOfFile: sourcePath) else { return false }

    let longestEdge = max(image.size.width, image.size.height)
    let scale = longestEdge > maxSize ? maxSize / longestEdge : 1.0
    let targetSize = CGSize(
      width: (image.size.width * scale).rounded(),
      height: (image.size.height * scale).rounded()
    )

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
    let scaled = renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    guard let data = scaled.jpegData(compressionQuality: quality) else { return false }

    do {
      try data.write(to: URL(fileURLWithPath: targetPath), options: .atomic)
      return true
    } catch {
      return false
    }
  }
}

// MARK: - Image ops

/// Scaling for meal photos, on its own channel.
///
/// Lives in this file because `ImageDownscaler` does; it has nothing to do with
/// the depth session and is reachable on devices without one.
public enum ImageOpsPlugin {
  public static let channelName = "com.trainlibre.app/image_ops"

  public static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "downscale":
      guard let args = call.arguments as? [String: Any],
        let sourcePath = args["sourcePath"] as? String,
        let targetPath = args["targetPath"] as? String
      else {
        result(false)
        return
      }
      let maxSize = (args["maxSize"] as? NSNumber)?.doubleValue ?? 1024
      let quality = (args["quality"] as? NSNumber)?.doubleValue ?? 0.8
      // Decoding a 12 MP JPEG and re-encoding it takes long enough to drop
      // frames if it runs on the platform thread.
      DispatchQueue.global(qos: .userInitiated).async {
        let ok = ImageDownscaler.write(
          sourcePath: sourcePath,
          targetPath: targetPath,
          maxSize: CGFloat(maxSize),
          quality: CGFloat(quality)
        )
        DispatchQueue.main.async { result(ok) }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - Capture session

public class DepthScanController: NSObject {
  public static let shared = DepthScanController()

  /// Everything that touches the session runs here. `AVCaptureSession`
  /// configuration blocks the caller, so it must stay off the main thread.
  private let sessionQueue = DispatchQueue(label: "com.trainlibre.app.depth_scan.session")

  /// Barcode metadata has its own serial queue. Sharing `sessionQueue` meant the
  /// 1.2 s focus wait before a photo blocked barcode delivery, and a barcode in
  /// frame delayed the shutter by however many frames had queued up behind it.
  private let metadataQueue = DispatchQueue(label: "com.trainlibre.app.depth_scan.metadata")

  private let session = AVCaptureSession()
  private var photoOutput: AVCapturePhotoOutput?
  private var videoDevice: AVCaptureDevice?
  private var isConfigured = false
  private var depthSupported = false

  private var pendingCompletion: (([String: Any]?) -> Void)?
  private var captureDelegate: PhotoCaptureDelegate?

  private var attachedPreviewLayers: [AVCaptureVideoPreviewLayer] = []

  public static func isLiDARSupported() -> Bool {
    if #available(iOS 15.4, *) {
      return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
    }
    return false
  }

  public static func isCameraAvailable() -> Bool {
    return bestBackCamera() != nil
  }

  /// The most depth-capable back camera the device has.
  ///
  /// LiDAR first — it is the only one that reports *absolute* distances, which
  /// is what the portion-size hint is built on. The multi-camera devices come
  /// next: their disparity-based depth is relative, but it still yields a depth
  /// map, so a non-Pro iPhone is no longer stuck with a flat photo. Plain wide
  /// angle is the last resort; there the screen behaves the same, just without
  /// a depth map.
  private static func bestBackCamera() -> AVCaptureDevice? {
    var wanted: [AVCaptureDevice.DeviceType] = []
    if #available(iOS 15.4, *) {
      wanted.append(.builtInLiDARDepthCamera)
    }
    wanted.append(contentsOf: [
      .builtInDualWideCamera,
      .builtInDualCamera,
      .builtInTripleCamera,
      .builtInWideAngleCamera,
    ])

    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: wanted,
      mediaType: .video,
      position: .back
    )
    for type in wanted {
      if let match = discovery.devices.first(where: { $0.deviceType == type }) {
        return match
      }
    }
    return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
  }

  // MARK: Preview attachment

  func attach(previewLayer: AVCaptureVideoPreviewLayer) {
    attachedPreviewLayers.append(previewLayer)
    previewLayer.session = session
  }

  func detach(previewLayer: AVCaptureVideoPreviewLayer) {
    attachedPreviewLayers.removeAll { $0 === previewLayer }
    previewLayer.session = nil
  }

  // MARK: Lifecycle

  /// Runs an AVFoundation call that can raise rather than return an error.
  ///
  /// `startRunning`/`stopRunning` raise an `NSException` when the session is in
  /// a state they dislike — most often one being reconfigured from elsewhere.
  /// Swift cannot catch that, so a session torn down at an awkward moment took
  /// the whole app with it from a background queue. Losing the preview is a far
  /// better outcome than losing the process.
  @discardableResult
  private func guarded(_ what: String, _ block: () -> Void) -> Bool {
    if let exception = TLExceptionCatcher.catchException(block) {
      NSLog("[DepthScan] %@ raised: %@", what, exception.reason ?? exception.name.rawValue)
      return false
    }
    return true
  }

  public func start(completion: @escaping (Bool) -> Void) {
    sessionQueue.async { [weak self] in
      guard let self else {
        DispatchQueue.main.async { completion(false) }
        return
      }

      if !self.isConfigured {
        guard self.configureSession() else {
          DispatchQueue.main.async { completion(false) }
          return
        }
      }

      if !self.session.isRunning {
        self.guarded("startRunning") { self.session.startRunning() }
      }

      DispatchQueue.main.async { completion(self.session.isRunning) }
    }
  }

  public func stop() {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.guarded("stopRunning") { self.session.stopRunning() }
    }
  }

  private func configureSession() -> Bool {
    var configured = false
    let completed = guarded("configureSession") {
      configured = self.applyConfiguration()
    }
    if !completed {
      // The block bailed out mid-configuration; the session must not be left
      // between begin and commit or every later start/stop raises as well.
      guarded("commitConfiguration") { self.session.commitConfiguration() }
      return false
    }
    return configured
  }

  private func applyConfiguration() -> Bool {
    session.beginConfiguration()
    session.sessionPreset = .photo

    guard let device = DepthScanController.bestBackCamera(),
      let input = try? AVCaptureDeviceInput(device: device),
      session.canAddInput(input)
    else {
      session.commitConfiguration()
      return false
    }
    session.addInput(input)
    videoDevice = device

    // Continuous autofocus so the frame is already sharp when the shutter is
    // pressed; `capturePhotoWithDepth` still waits for convergence.
    if let device = videoDevice, (try? device.lockForConfiguration()) != nil {
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      device.unlockForConfiguration()
    }

    let photo = AVCapturePhotoOutput()
    guard session.canAddOutput(photo) else {
      session.commitConfiguration()
      return false
    }
    session.addOutput(photo)
    photo.isDepthDataDeliveryEnabled = photo.isDepthDataDeliverySupported
    depthSupported = photo.isDepthDataDeliverySupported
    photoOutput = photo

    // Barcode detection shares the session — this is the whole reason the
    // capture screen can drop its separate scanner camera.
    let metadata = AVCaptureMetadataOutput()
    if session.canAddOutput(metadata) {
      session.addOutput(metadata)
      metadata.setMetadataObjectsDelegate(self, queue: metadataQueue)
      let wanted: [AVMetadataObject.ObjectType] = [
        .ean13, .ean8, .upce, .code128, .code39, .code93, .itf14, .dataMatrix, .qr,
      ]
      metadata.metadataObjectTypes = wanted.filter {
        metadata.availableMetadataObjectTypes.contains($0)
      }
    }

    session.commitConfiguration()
    isConfigured = true
    return true
  }

  // MARK: Capture

  public func capturePhotoWithDepth(
    completion: @escaping ([String: Any]?, String?) -> Void
  ) {
    sessionQueue.async { [weak self] in
      guard let self else {
        DispatchQueue.main.async { completion(nil, "Capture session went away") }
        return
      }

      // A stopped session used to mean an immediate nil, and the screen then
      // fell through to the system camera. The session is stopped on every
      // backgrounding, so a shutter tap racing the resume hit this routinely.
      if !self.session.isRunning {
        if !self.isConfigured, !self.configureSession() {
          DispatchQueue.main.async { completion(nil, "Camera could not be configured") }
          return
        }
        self.session.startRunning()
      }

      guard self.session.isRunning, let output = self.photoOutput else {
        DispatchQueue.main.async { completion(nil, "Capture session is not running") }
        return
      }

      self.waitForStableExposureAndFocus()
      self.capture(with: output, includeDepth: output.isDepthDataDeliveryEnabled, completion: completion)
    }
  }

  /// One `capturePhoto` round trip. Split out so a depth capture that the photo
  /// output refuses can be retried as a plain photo — losing the size hint is a
  /// great deal better than losing the picture.
  private func capture(
    with output: AVCapturePhotoOutput,
    includeDepth: Bool,
    completion: @escaping ([String: Any]?, String?) -> Void
  ) {
    let settings: AVCapturePhotoSettings
    if output.availablePhotoCodecTypes.contains(.jpeg) {
      settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    } else {
      settings = AVCapturePhotoSettings()
    }
    settings.isDepthDataDeliveryEnabled = includeDepth && output.isDepthDataDeliveryEnabled

    let delegate = PhotoCaptureDelegate { [weak self] response, failure in
      guard let self else {
        DispatchQueue.main.async { completion(response, failure) }
        return
      }
      self.captureDelegate = nil
      if response == nil && includeDepth {
        self.sessionQueue.async {
          self.capture(with: output, includeDepth: false, completion: completion)
        }
        return
      }
      DispatchQueue.main.async { completion(response, failure) }
    }
    // The photo output only holds the delegate weakly.
    captureDelegate = delegate
    if let exception = TLExceptionCatcher.catchException({
      output.capturePhoto(with: settings, delegate: delegate)
    }) {
      captureDelegate = nil
      let reason = exception.reason ?? exception.name.rawValue
      if includeDepth {
        // Almost always the depth request the output would not accept.
        capture(with: output, includeDepth: false, completion: completion)
      } else {
        DispatchQueue.main.async { completion(nil, "capturePhoto raised: \(reason)") }
      }
    }
  }

  /// Blocks the session queue until the camera has settled, or the budget runs
  /// out. Firing immediately after `startRunning()` is what produced dark and
  /// blurred captures before.
  private func waitForStableExposureAndFocus() {
    guard let device = videoDevice else { return }
    let deadline = Date().addingTimeInterval(1.2)
    while Date() < deadline {
      if !device.isAdjustingFocus && !device.isAdjustingExposure && !device.isAdjustingWhiteBalance
      {
        return
      }
      Thread.sleep(forTimeInterval: 0.05)
    }
  }
}

// MARK: - Barcode delegate

extension DepthScanController: AVCaptureMetadataOutputObjectsDelegate {
  public func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    for object in metadataObjects {
      guard let readable = object as? AVMetadataMachineReadableCodeObject,
        let value = readable.stringValue,
        !value.isEmpty
      else { continue }
      BarcodeStreamHandler.shared.emit(value)
      return
    }
  }
}

// MARK: - Photo delegate

/// One-shot delegate for a single `capturePhoto` call.
final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let originalCompletion: ([String: Any]?, String?) -> Void
  private var hasCompleted = false
  private let gate = NSLock()

  init(completion: @escaping ([String: Any]?, String?) -> Void) {
    self.originalCompletion = completion
    super.init()
  }

  /// Fires the completion exactly once. Both callbacks below can be the last
  /// one the output sends, depending on where the capture went wrong, and a
  /// completion that never fires leaves the shutter hanging forever.
  private func completion(_ response: [String: Any]?, _ failure: String?) {
    gate.lock()
    let alreadyDone = hasCompleted
    hasCompleted = true
    gate.unlock()
    guard !alreadyDone else { return }
    originalCompletion(response, failure)
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
    error: Error?
  ) {
    // Only reached as a fallback: on the happy path the photo callback below
    // has already completed and this is a no-op.
    completion(nil, error.map { "Capture failed: \($0.localizedDescription)" } ?? "Capture produced no photo")
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if let error {
      completion(nil, "Photo output failed: \(error.localizedDescription)")
      return
    }
    guard let photoData = photo.fileDataRepresentation() else {
      completion(nil, "Photo output produced no file data")
      return
    }

    let tempDir = FileManager.default.temporaryDirectory
    let imageURL = tempDir.appendingPathComponent("depth_capture_\(UUID().uuidString).jpg")
    do {
      try photoData.write(to: imageURL, options: .atomic)
    } catch {
      completion(nil, "Could not write photo: \(error.localizedDescription)")
      return
    }

    var depthResult: [String: Any]?
    var intrinsicsResult: [String: Any]?

    // The photo is written with an EXIF orientation tag; the depth map is not
    // rotated at all. Left alone the two disagree by a quarter turn, which is
    // why the depth preview came out sideways next to its own photo.
    let exifOrientationRaw =
      photo.metadata[kCGImagePropertyOrientation as String] as? UInt32
    var orientedDepth = photo.depthData
    if let raw = exifOrientationRaw,
      let exif = CGImagePropertyOrientation(rawValue: raw),
      let depth = orientedDepth
    {
      orientedDepth = depth.applyingExifOrientation(exif)
    }

    if let depthData = orientedDepth?.converting(
      toDepthDataType: kCVPixelFormatType_DepthFloat32)
    {
      let pixelBuffer = depthData.depthDataMap
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

      let width = CVPixelBufferGetWidth(pixelBuffer)
      let height = CVPixelBufferGetHeight(pixelBuffer)

      if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
        // Rotating the depth map leaves rows padded to an alignment boundary,
        // so the buffer is no longer width*4 bytes per row. Copying it as one
        // block then skewed the image by a few pixels per row.
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let rowBytes = width * MemoryLayout<Float32>.size
        var rawData = Data(capacity: rowBytes * height)
        for row in 0..<height {
          let rowStart = baseAddress.advanced(by: row * bytesPerRow)
          rawData.append(Data(bytes: rowStart, count: rowBytes))
        }
        depthResult = [
          "width": width,
          "height": height,
          "values": FlutterStandardTypedData(bytes: rawData),
          "accuracy": depthData.depthDataAccuracy == .absolute ? "absolute" : "relative",
          "filtered": depthData.isDepthDataFiltered,
        ]
      }

      CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)

      if let calibration = depthData.cameraCalibrationData {
        let matrix = calibration.intrinsicMatrix
        intrinsicsResult = [
          "fx": Double(matrix.columns.0.x),
          "fy": Double(matrix.columns.1.y),
          "cx": Double(matrix.columns.2.x),
          "cy": Double(matrix.columns.2.y),
          "refWidth": Int(calibration.intrinsicMatrixReferenceDimensions.width),
          "refHeight": Int(calibration.intrinsicMatrixReferenceDimensions.height),
        ]
      }
    }

    var response: [String: Any] = ["imagePath": imageURL.path]
    if let depthResult { response["depth"] = depthResult }
    if let intrinsicsResult { response["intrinsics"] = intrinsicsResult }

    // Reported so the Dart side can check the depth map, the intrinsics and the
    // photo against each other. `applyingExifOrientation` above rotates the
    // depth pixels but is not documented to rotate the calibration data with
    // them, and a frame size derived from unrotated intrinsics would be a
    // quarter turn out. These are the numbers that settle it on real hardware.
    var photoInfo: [String: Any] = [:]
    if let raw = exifOrientationRaw { photoInfo["exifOrientation"] = Int(raw) }
    if let pixelWidth = photo.metadata[kCGImagePropertyPixelWidth as String] as? Int,
      let pixelHeight = photo.metadata[kCGImagePropertyPixelHeight as String] as? Int
    {
      photoInfo["pixelWidth"] = pixelWidth
      photoInfo["pixelHeight"] = pixelHeight
    }
    if !photoInfo.isEmpty { response["photo"] = photoInfo }

    completion(response, nil)
  }
}
