import AVKit
import UIKit

@MainActor
final class VideoViewerManager {
  static let shared = VideoViewerManager()

  private var presentedController: AVPlayerViewController?
  private var dismissalObserver: DismissObserver?
  private var orientationToken: UUID?

  private init() {}

  func show(url: URL, autoPlay: Bool = true) {
    let player = AVPlayer(url: url)
    show(player: player, autoPlay: autoPlay)
  }

  func show(playerItem: AVPlayerItem, autoPlay: Bool = true) {
    let player = AVPlayer(playerItem: playerItem)
    show(player: player, autoPlay: autoPlay)
  }

  func hide(animated: Bool = true) {
    guard let controller = presentedController else { return }
    controller.dismiss(animated: animated) { [weak self] in
      Task { @MainActor in
        self?.cleanupAfterDismiss()
      }
    }
  }

  private func show(player: AVPlayer, autoPlay: Bool) {
    if let presentedController {
      if presentedController.presentingViewController != nil {
        return
      }
      cleanupAfterDismiss()
    }

    guard let presenter = topMostViewController() else { return }

    let controller = ManagedAVPlayerViewController()
    controller.modalPresentationStyle = .fullScreen
    controller.player = player
    controller.onDismiss = { [weak self] in
      Task { @MainActor in
        self?.cleanupAfterDismiss()
      }
    }

    let observer = DismissObserver { [weak self] in
      Task { @MainActor in
        self?.cleanupAfterDismiss()
      }
    }
    dismissalObserver = observer

    orientationToken = OrientationManager.shared.push(.allButUpsideDown)
    presentedController = controller

    presenter.present(controller, animated: true) {
      controller.presentationController?.delegate = observer
      if autoPlay {
        player.play()
      }
    }
  }

  private func cleanupAfterDismiss() {
    presentedController?.player?.pause()
    presentedController?.player = nil
    presentedController = nil
    dismissalObserver = nil
    if let token = orientationToken {
      orientationToken = nil
      OrientationManager.shared.pop(token)
    }
  }

  private func topMostViewController() -> UIViewController? {
    let windows = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }

    let keyWindow = windows.first(where: { $0.isKeyWindow }) ?? windows.first
    guard let root = keyWindow?.rootViewController else { return nil }
    return topMostViewController(from: root)
  }

  private func topMostViewController(from root: UIViewController) -> UIViewController {
    if let presented = root.presentedViewController {
      return topMostViewController(from: presented)
    }
    if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
      return topMostViewController(from: visible)
    }
    if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
      return topMostViewController(from: selected)
    }
    return root
  }
}

private final class DismissObserver: NSObject, UIAdaptivePresentationControllerDelegate {
  private let onDismiss: () -> Void

  init(onDismiss: @escaping () -> Void) {
    self.onDismiss = onDismiss
  }

  func presentationControllerDidDismiss(_: UIPresentationController) {
    onDismiss()
  }
}

private final class ManagedAVPlayerViewController: AVPlayerViewController {
  var onDismiss: (() -> Void)?

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed || presentingViewController == nil {
      let handler = onDismiss
      onDismiss = nil
      handler?()
    }
  }
}
