import SwiftMessages
import SwiftUI
import UIKit

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
    let view = SwiftMessagesHostingView(
      rootView: BottomSheetContainer(content: content, full: fullScreen),
      isFullScreen: fullScreen
    )

    var config = SwiftMessages.Config()
    config.presentationStyle = .bottom
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
    let view = SwiftMessagesHostingView(
      rootView: CenterPopupContainer(content: content),
      isFullScreen: false
    )

    var config = SwiftMessages.Config()
    config.presentationStyle = .center
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
