import AVFoundation
import SwiftUI
import UIKit

struct CameraLayer: View {
  let authorization: AVAuthorizationStatus
  let scannerViewID: UUID
  @Binding var torchOn: Bool
  let onScanned: (String) -> Void

  var body: some View {
    Group {
      if authorization == .authorized {
        QRCodeScannerPreview(torchOn: $torchOn, onScanned: onScanned)
          .id(scannerViewID)
      } else {
        Color.black
      }
    }
  }
}

struct QRCodeScannerPreview: UIViewRepresentable {
  @Binding var torchOn: Bool
  let onScanned: (String) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onScanned: onScanned)
  }

  func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    view.videoPreviewLayer.videoGravity = .resizeAspectFill
    context.coordinator.attachPreviewLayer(view.videoPreviewLayer)
    context.coordinator.start()
    return view
  }

  func updateUIView(_ uiView: PreviewView, context: Context) {
    _ = uiView
    context.coordinator.setTorch(on: torchOn)
    context.coordinator.start()
  }

  static func dismantleUIView(_ uiView: PreviewView, coordinator: Coordinator) {
    _ = uiView
    coordinator.stop()
  }

  final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "tuyun.qrcode.scanner.session")
    private var isConfigured: Bool = false
    private var currentTorchOn: Bool = false
    private var didBecomeActiveObserver: NSObjectProtocol?
    private var willResignActiveObserver: NSObjectProtocol?

    private let onScanned: (String) -> Void

    init(onScanned: @escaping (String) -> Void) {
      self.onScanned = onScanned
      super.init()
      didBecomeActiveObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.start()
      }
      willResignActiveObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.willResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.stop()
      }
    }

    deinit {
      if let didBecomeActiveObserver {
        NotificationCenter.default.removeObserver(didBecomeActiveObserver)
      }
      if let willResignActiveObserver {
        NotificationCenter.default.removeObserver(willResignActiveObserver)
      }
    }

    func attachPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
      layer.session = session
    }

    func start() {
      sessionQueue.async { [weak self] in
        guard let self else { return }
        if !isConfigured {
          configureSessionIfNeeded()
        }
        if !isConfigured {
          return
        }
        if !session.isRunning {
          session.startRunning()
        }
      }
    }

    func stop() {
      sessionQueue.async { [weak self] in
        guard let self else { return }
        if session.isRunning {
          session.stopRunning()
        }
      }
    }

    func setTorch(on: Bool) {
      if currentTorchOn == on { return }
      currentTorchOn = on
      sessionQueue.async { [weak self] in
        guard let self else { return }
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
          try device.lockForConfiguration()
          device.torchMode = on ? .on : .off
          device.unlockForConfiguration()
        } catch {}
      }
    }

    private func configureSessionIfNeeded() {
      session.beginConfiguration()
      session.sessionPreset = .high

      guard let device = AVCaptureDevice.default(for: .video) else {
        session.commitConfiguration()
        isConfigured = false
        return
      }

      do {
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
          session.addInput(input)
        }
      } catch {
        session.commitConfiguration()
        isConfigured = false
        return
      }

      if session.canAddOutput(metadataOutput) {
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
          metadataOutput.metadataObjectTypes = [.qr]
        }
      }

      session.commitConfiguration()
      isConfigured = true
    }

    func metadataOutput(
      _: AVCaptureMetadataOutput,
      didOutput metadataObjects: [AVMetadataObject],
      from _: AVCaptureConnection
    ) {
      guard let first = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
      guard first.type == .qr else { return }
      guard let value = first.stringValue else { return }
      onScanned(value)
    }
  }
}

final class PreviewView: UIView {
  override class var layerClass: AnyClass {
    AVCaptureVideoPreviewLayer.self
  }

  var videoPreviewLayer: AVCaptureVideoPreviewLayer {
    layer as! AVCaptureVideoPreviewLayer
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    videoPreviewLayer.frame = bounds
  }
}
