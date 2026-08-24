// ios/Runner/DepthScanPlugin.swift

import AVFoundation
import Flutter
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
      DepthScanController.shared.capturePhotoWithDepth { response in
        result(response)
      }

    case "makeThumbnail":
      guard let args = call.arguments as? [String: Any],
        let sourcePath = args["sourcePath"] as? String,
        let targetPath = args["targetPath"] as? String
      else {
        result(false)
        return
      }
      let maxSize = (args["maxSize"] as? NSNumber)?.doubleValue ?? 320
      let quality = (args["quality"] as? NSNumber)?.doubleValue ?? 0.8
      let ok = ImageDownscaler.write(
        sourcePath: sourcePath,
        targetPath: targetPath,
        maxSize: CGFloat(maxSize),
        quality: CGFloat(quality)
      )
      result(ok)

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

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func emit(_ value: String) {
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

// MARK: - Capture session

public class DepthScanController: NSObject {
  public static let shared = DepthScanController()

  /// Everything that touches the session runs here. `AVCaptureSession`
  /// configuration blocks the caller, so it must stay off the main thread.
  private let sessionQueue = DispatchQueue(label: "com.trainlibre.app.depth_scan.session")

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

  /// LiDAR camera when the device has one, plain wide angle otherwise. Devices
  /// without LiDAR still get preview, barcodes and photos — only the depth map
  /// is missing, and the whole capture screen behaves the same either way.
  private static func bestBackCamera() -> AVCaptureDevice? {
    if #available(iOS 15.4, *),
      let lidar = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)
    {
      return lidar
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
        self.session.startRunning()
      }

      DispatchQueue.main.async { completion(self.session.isRunning) }
    }
  }

  public func stop() {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning else { return }
      self.session.stopRunning()
    }
  }

  private func configureSession() -> Bool {
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
      metadata.setMetadataObjectsDelegate(self, queue: sessionQueue)
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

  public func capturePhotoWithDepth(completion: @escaping ([String: Any]?) -> Void) {
    sessionQueue.async { [weak self] in
      guard let self, self.session.isRunning, let output = self.photoOutput else {
        DispatchQueue.main.async { completion(nil) }
        return
      }

      self.waitForStableExposureAndFocus()

      let settings: AVCapturePhotoSettings
      if output.availablePhotoCodecTypes.contains(.jpeg) {
        settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
      } else {
        settings = AVCapturePhotoSettings()
      }
      settings.isDepthDataDeliveryEnabled = output.isDepthDataDeliveryEnabled

      let delegate = PhotoCaptureDelegate { [weak self] response in
        DispatchQueue.main.async { completion(response) }
        self?.captureDelegate = nil
      }
      // The photo output only holds the delegate weakly.
      self.captureDelegate = delegate
      output.capturePhoto(with: settings, delegate: delegate)
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
  private let completion: ([String: Any]?) -> Void

  init(completion: @escaping ([String: Any]?) -> Void) {
    self.completion = completion
    super.init()
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    guard error == nil, let photoData = photo.fileDataRepresentation() else {
      completion(nil)
      return
    }

    let tempDir = FileManager.default.temporaryDirectory
    let imageURL = tempDir.appendingPathComponent("depth_capture_\(UUID().uuidString).jpg")
    do {
      try photoData.write(to: imageURL, options: .atomic)
    } catch {
      completion(nil)
      return
    }

    var depthResult: [String: Any]?
    var intrinsicsResult: [String: Any]?

    if let depthData = photo.depthData?.converting(
      toDepthDataType: kCVPixelFormatType_DepthFloat32)
    {
      let pixelBuffer = depthData.depthDataMap
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

      let width = CVPixelBufferGetWidth(pixelBuffer)
      let height = CVPixelBufferGetHeight(pixelBuffer)

      if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
        let byteCount = width * height * MemoryLayout<Float32>.size
        let rawData = Data(bytes: baseAddress, count: byteCount)
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
    completion(response)
  }
}
