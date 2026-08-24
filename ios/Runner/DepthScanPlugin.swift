// ios/Runner/DepthScanPlugin.swift

import Flutter
import AVFoundation
import UIKit

public class DepthScanPlugin: NSObject {
  public static let channelName = "com.trainlibre.app/depth_scan"

  public static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let instance = DepthScanPlugin()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "capability":
      let isSupported = DepthScanController.isLiDARSupported()
      result([
        "supported": isSupported,
        "reason": isSupported ? nil : "Device lacks a built-in LiDAR depth camera"
      ])
    case "capture":
      DepthScanController.shared.capturePhotoWithDepth { response in
        result(response)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

public class DepthScanController: NSObject, AVCapturePhotoCaptureDelegate {
  public static let shared = DepthScanController()

  private var captureSession: AVCaptureSession?
  private var photoOutput: AVCapturePhotoOutput?
  private var pendingCompletion: (([String: Any]?) -> Void)?

  public static func isLiDARSupported() -> Bool {
    if #available(iOS 15.4, *) {
      return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
    } else {
      return false
    }
  }

  public func capturePhotoWithDepth(completion: @escaping ([String: Any]?) -> Void) {
    guard DepthScanController.isLiDARSupported() else {
      completion(nil)
      return
    }

    pendingCompletion = completion

    let session = AVCaptureSession()
    session.beginConfiguration()
    session.sessionPreset = .photo

    guard #available(iOS 15.4, *),
          let device = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back),
          let input = try? AVCaptureDeviceInput(device: device),
          session.canAddInput(input) else {
      session.commitConfiguration()
      completion(nil)
      return
    }

    session.addInput(input)

    let output = AVCapturePhotoOutput()
    output.isDepthDataDeliveryEnabled = output.isDepthDataDeliverySupported
    if session.canAddOutput(output) {
      session.addOutput(output)
    } else {
      session.commitConfiguration()
      completion(nil)
      return
    }

    session.commitConfiguration()
    self.captureSession = session
    self.photoOutput = output

    DispatchQueue.global(qos: .userInitiated).async {
      session.startRunning()

      let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
      settings.isDepthDataDeliveryEnabled = output.isDepthDataDeliveryEnabled

      output.capturePhoto(with: settings, delegate: self)
    }
  }

  public func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    defer {
      captureSession?.stopRunning()
      captureSession = nil
      photoOutput = nil
    }

    guard error == nil, let photoData = photo.fileDataRepresentation() else {
      pendingCompletion?(nil)
      pendingCompletion = nil
      return
    }

    // Save photo to temporary file
    let tempDir = FileManager.default.temporaryDirectory
    let imagePath = tempDir.appendingPathComponent("depth_capture_\(UUID().uuidString).jpg").path
    try? photoData.write(to: URL(fileURLWithPath: imagePath))

    var depthResult: [String: Any]? = nil
    var intrinsicsResult: [String: Any]? = nil

    if let depthData = photo.depthData?.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32) {
      let pixelBuffer = depthData.depthDataMap
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

      let width = CVPixelBufferGetWidth(pixelBuffer)
      let height = CVPixelBufferGetHeight(pixelBuffer)
      let count = width * height

      if let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) {
        let byteCount = count * MemoryLayout<Float32>.size
        let rawData = Data(bytes: baseAddress, count: byteCount)
        let accuracyStr = depthData.depthDataAccuracy == .absolute ? "absolute" : "relative"

        depthResult = [
          "width": width,
          "height": height,
          "values": FlutterStandardTypedData(bytes: rawData),
          "accuracy": accuracyStr,
          "filtered": depthData.isDepthDataFiltered
        ]
      }

      if let cameraCalibration = depthData.cameraCalibrationData {
        let matrix = cameraCalibration.intrinsicMatrix
        // matrix: 3x3 intrinsic matrix (fx 0 cx; 0 fy cy; 0 0 1)
        intrinsicsResult = [
          "fx": Double(matrix.columns.0.x),
          "fy": Double(matrix.columns.1.y),
          "cx": Double(matrix.columns.2.x),
          "cy": Double(matrix.columns.2.y),
          "refWidth": Int(cameraCalibration.intrinsicMatrixReferenceDimensions.width),
          "refHeight": Int(cameraCalibration.intrinsicMatrixReferenceDimensions.height)
        ]
      }
    }

    let response: [String: Any] = [
      "imagePath": imagePath,
      "depth": depthResult as Any,
      "intrinsics": intrinsicsResult as Any
    ]

    DispatchQueue.main.async { [weak self] in
      self?.pendingCompletion?(response)
      self?.pendingCompletion = nil
    }
  }
}
