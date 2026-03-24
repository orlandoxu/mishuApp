import SwiftMessages
import UIKit

// DONE-AI: toast 样式统一为轻量纯文本，避免默认 emoji 与过大卡片样式
// DONE-AI: 修复 toast 被顶部非安全区域遮挡的问题
// DONE-AI: BottomSheetCenter 已拆分到独立插件文件中

@MainActor
final class ToastCenter {
  static let shared = ToastCenter()
  private var lastToastMessage: String?
  private var lastToastAt: Date?

  private init() {
    SwiftMessages.defaultConfig.presentationStyle = .top
    // SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: .normal)
    SwiftMessages.defaultConfig.presentationContext = .window(windowLevel: .statusBar)
    SwiftMessages.defaultConfig.duration = .seconds(seconds: 2.0)
    SwiftMessages.defaultConfig.dimMode = .none
    // SwiftMessages.defaultConfig.interactiveHide = true
    SwiftMessages.defaultConfig.interactiveHide = false
    SwiftMessages.defaultConfig.preferredStatusBarStyle = .lightContent
  }

  func show(_ message: String) {
    showInternal(message, duration: 3, maxLines: 2)
  }

  func showDetail(_ message: String) {
    showInternal(message, duration: 3.5, maxLines: 3)
  }

  private func showInternal(_ message: String, duration: TimeInterval?, maxLines: Int) {
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return
    }

    let now = Date()
    if
      let lastToastMessage,
      let lastToastAt,
      lastToastMessage == trimmed,
      now.timeIntervalSince(lastToastAt) < 0.7
    {
      return
    }
    lastToastMessage = trimmed
    lastToastAt = now

    let view = makeView(message: trimmed, maxLines: maxLines)
    // SwiftMessages.hideAll()
    if let duration {
      var config = SwiftMessages.defaultConfig
      config.duration = .seconds(seconds: duration)
      SwiftMessages.show(config: config, view: view)
    } else {
      SwiftMessages.show(view: view)
    }
  }

  private func makeView(message: String, maxLines: Int) -> UIView {
    ToastPillView(message: message, maxLines: maxLines)
  }
}

private final class ToastPillView: UIView {
  private let pillView: UIView = .init()
  private let label: UILabel = .init()

  init(message: String, maxLines: Int) {
    super.init(frame: .zero)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    setupUi(message: message, maxLines: maxLines)
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUi(message: String, maxLines: Int) {
    pillView.translatesAutoresizingMaskIntoConstraints = false
    pillView.backgroundColor = UIColor.black.withAlphaComponent(0.86)
    pillView.layer.cornerRadius = 12
    pillView.clipsToBounds = true
    // pillView.isUserInteractionEnabled = true

    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    label.textColor = .white
    label.textAlignment = .center
    label.numberOfLines = maxLines
    label.text = message

    addSubview(pillView)
    pillView.addSubview(label)

    NSLayoutConstraint.activate([
      pillView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
      pillView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10),
      pillView.centerXAnchor.constraint(equalTo: centerXAnchor),
      pillView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
      pillView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

      label.topAnchor.constraint(equalTo: pillView.topAnchor, constant: 10),
      label.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -10),
      label.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 18),
      label.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -18),
    ])
  }
}
