import SwiftUI
import UIKit

/// 虽然使用了 swift-navigation 管理导航，但在 iOS 14 上 SwiftUI 原生 TextField 对中文输入法、光标控制等支持可能不如 UITextField 完善，因此保留此封装以确保输入体验。
struct UIKitTextField: UIViewRepresentable {
  let titleKey: String
  @Binding var text: String

  var keyboardType: UIKeyboardType = .default
  var autocapitalizationType: UITextAutocapitalizationType = .sentences
  var autocorrectionDisabled: Bool = false
  var font: UIFont? = UIFont.systemFont(ofSize: 16, weight: .medium)

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.delegate = context.coordinator
    textField.placeholder = titleKey
    textField.keyboardType = keyboardType
    textField.autocapitalizationType = autocapitalizationType
    textField.autocorrectionType = autocorrectionDisabled ? .no : .default

    if let font = font {
      textField.font = font
    }

    textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

    return textField
  }

  func updateUIView(_ uiView: UITextField, context: Context) {
    context.coordinator.parent = self
    if uiView.text != text {
      uiView.text = text
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UITextFieldDelegate {
    var parent: UIKitTextField

    init(_ parent: UIKitTextField) {
      self.parent = parent
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
      parent.text = textField.text ?? ""
    }
  }
}
