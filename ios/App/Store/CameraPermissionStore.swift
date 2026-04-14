import AVFoundation
import Combine

final class CameraPermissionStore: ObservableObject {
  @Published private(set) var authorization: AVAuthorizationStatus =
    AVCaptureDevice.authorizationStatus(for: .video)

  func refresh() {
    authorization = AVCaptureDevice.authorizationStatus(for: .video)
  }

  func requestIfNeeded() {
    if authorization == .notDetermined {
      AVCaptureDevice.requestAccess(for: .video) { _ in
        DispatchQueue.main.async {
          self.refresh()
        }
      }
    }
  }
}
