import UIKit

final class OrientationManager {
  static let shared = OrientationManager()

  private struct Entry: Equatable {
    let token: UUID
    let mask: UIInterfaceOrientationMask
  }

  private let lock = NSLock()
  private var stack: [Entry] = [Entry(token: UUID(), mask: .portrait)]

  private init() {}

  var currentMask: UIInterfaceOrientationMask {
    lock.lock()
    defer { lock.unlock() }
    return stack.last?.mask ?? .portrait
  }

  @discardableResult
  func push(_ mask: UIInterfaceOrientationMask) -> UUID {
    let token = UUID()
    lock.lock()
    stack.append(Entry(token: token, mask: mask))
    lock.unlock()
    applyCurrentMask()
    return token
  }

  func pop(_ token: UUID) {
    lock.lock()
    if let index = stack.lastIndex(where: { $0.token == token }) {
      stack.remove(at: index)
    }
    if stack.isEmpty {
      stack.append(Entry(token: UUID(), mask: .portrait))
    }
    lock.unlock()
    applyCurrentMask()
  }

  func setDefaultPortrait() {
    lock.lock()
    stack = [Entry(token: UUID(), mask: .portrait)]
    lock.unlock()
    applyCurrentMask()
  }

  private func applyCurrentMask() {
    let mask = currentMask
    DispatchQueue.main.async {
      if #available(iOS 16.0, *) {
        for scene in UIApplication.shared.connectedScenes {
          guard let windowScene = scene as? UIWindowScene else { continue }
          let prefs = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
          try? windowScene.requestGeometryUpdate(prefs)
        }
      }

      for window in UIApplication.shared.allWindows {
        if #available(iOS 16.0, *) {
          window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
      }
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }
}

private extension UIApplication {
  var allWindows: [UIWindow] {
    connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
  }
}
