import SwiftMessages
import UIKit
import class SwiftUI.UIHostingController
import protocol SwiftUI.View
import struct SwiftUI.ViewBuilder

// DONE-AI: 底部弹层增加左右边距，避免贴边
@MainActor
final class BottomSheetCenter {
  static let shared = BottomSheetCenter()

  private init() {}

  func show<Content: View>(
    _ fullScreen: Bool = false,
    _ content: Content,
    onHide: (() -> Void)? = nil
  ) {
    let animator = NaturalBottomSheetAnimator()
    let view = SwiftMessagesHostingView(
      rootView: BottomSheetContainer(content: content, full: fullScreen),
      isFullScreen: fullScreen
    )

    var config = SwiftMessages.Config()
    config.presentationStyle = .custom(animator: animator)
    config.presentationContext = .window(windowLevel: .normal)
    config.duration = .forever
    config.dimMode = .color(color: UIColor.black.withAlphaComponent(0.4), interactive: true)
    config.interactiveHide = true
    config.preferredStatusBarStyle = .lightContent
    if let onHide {
      config.eventListeners.append { event in
        if case .didHide = event {
          onHide()
        }
      }
    }

    SwiftMessages.hideAll()
    SwiftMessages.show(config: config, view: view)
  }

  func showCenter<Content: View>(
    _ content: Content,
    onHide: (() -> Void)? = nil
  ) {
    let animator = NaturalCenterPopupAnimator()
    let view = SwiftMessagesHostingView(
      rootView: CenterPopupContainer(content: content),
      isFullScreen: false
    )

    var config = SwiftMessages.Config()
    config.presentationStyle = .custom(animator: animator)
    config.presentationContext = .window(windowLevel: .normal)
    config.duration = .forever
    config.dimMode = .color(color: UIColor.black.withAlphaComponent(0.20), interactive: true)
    config.interactiveHide = true
    config.preferredStatusBarStyle = .lightContent
    if let onHide {
      config.eventListeners.append { event in
        if case .didHide = event {
          onHide()
        }
      }
    }

    SwiftMessages.hideAll()
    SwiftMessages.show(config: config, view: view)
  }

  func showCenter<Content: View>(
    onHide: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    showCenter(content(), onHide: onHide)
  }

  func show<Content: View>(
    full: Bool = false,
    onHide: (() -> Void)? = nil,
    @ViewBuilder content: () -> Content
  ) {
    show(full, content(), onHide: onHide)
  }

  func hide() {
    SwiftMessages.hide()
  }
}

private final class NaturalBottomSheetAnimator: Animator {
  weak var delegate: AnimationDelegate?

  let showDuration: TimeInterval = 0.26
  let hideDuration: TimeInterval = 0.18

  func show(context: AnimationContext, completion: @escaping AnimationCompletion) {
    let view = context.messageView
    let container = context.containerView

    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    container.layoutIfNeeded()
    view.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    UIView.animate(
      withDuration: showDuration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseOut, .allowUserInteraction]
    ) {
      view.transform = CGAffineTransform.identity
    } completion: { completed in
      completion(completed || UIApplication.shared.applicationState != .active)
    }
  }

  func hide(context: AnimationContext, completion: @escaping AnimationCompletion) {
    let view = context.messageView
    UIView.animate(
      withDuration: hideDuration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseIn, .allowUserInteraction]
    ) {
      view.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    } completion: { completed in
      completion(completed || UIApplication.shared.applicationState != .active)
    }
  }
}

private final class NaturalCenterPopupAnimator: Animator {
  weak var delegate: AnimationDelegate?

  let showDuration: TimeInterval = 0.20
  let hideDuration: TimeInterval = 0.16

  func show(context: AnimationContext, completion: @escaping AnimationCompletion) {
    let view = context.messageView
    let container = context.containerView

    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
      view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      view.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      view.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
      view.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
    ])

    container.layoutIfNeeded()
    view.alpha = 0
    view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
    UIView.animate(
      withDuration: showDuration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseOut, .allowUserInteraction]
    ) {
      view.alpha = 1
      view.transform = CGAffineTransform.identity
    } completion: { completed in
      completion(completed || UIApplication.shared.applicationState != .active)
    }
  }

  func hide(context: AnimationContext, completion: @escaping AnimationCompletion) {
    let view = context.messageView
    UIView.animate(
      withDuration: hideDuration,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseIn, .allowUserInteraction]
    ) {
      view.alpha = 0
      view.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
    } completion: { completed in
      completion(completed || UIApplication.shared.applicationState != .active)
    }
  }
}

private struct BottomSheetContainer<Content: View>: View {
  let content: Content
  let full: Bool

  var body: some View {
    content
      .padding(.horizontal, full ? 0 : 16)
      .padding(.bottom, full ? 0 : 12)
  }
}

private struct CenterPopupContainer<Content: View>: View {
  let content: Content

  var body: some View {
    content
      .padding(.horizontal, 24)
  }
}

private final class SwiftMessagesHostingView<Content: View>: UIView {
  private let hostingController: UIHostingController<Content>
  private let isFullScreen: Bool

  init(rootView: Content, isFullScreen: Bool) {
    self.isFullScreen = isFullScreen
    hostingController = UIHostingController(rootView: rootView)
    super.init(frame: .zero)
    backgroundColor = .clear
    hostingController.view.backgroundColor = .clear
    // if isFullScreen { // 这个好像没用，我先注释了
    //   hostingController.additionalSafeAreaInsets = .zero
    //   hostingController.view.insetsLayoutMarginsFromSafeArea = false
    //   hostingController.view.preservesSuperviewLayoutMargins = false
    //   hostingController.view.layoutMargins = .zero
    // }

    let hostedView = hostingController.view!
    hostedView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(hostedView)

    NSLayoutConstraint.activate([
      hostedView.topAnchor.constraint(equalTo: topAnchor),
      hostedView.bottomAnchor.constraint(equalTo: bottomAnchor),
      hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
      hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }

  override var safeAreaInsets: UIEdgeInsets {
    isFullScreen ? .zero : super.safeAreaInsets
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
