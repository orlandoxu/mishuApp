import SwiftUI
import UIKit

// 这个组件的意义，是因为系统自带的SecureText没有小眼睛

struct SecureTextField: UIViewRepresentable {
  @Binding var text: String
  var placeholder: String
  var isSecure: Bool

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.placeholder = placeholder
    textField.font = .systemFont(ofSize: 16)
    textField.isSecureTextEntry = isSecure
    textField.autocapitalizationType = .none
    textField.autocorrectionType = .no
    textField.keyboardType = .asciiCapable
    textField.textContentType = isSecure ? .password : .oneTimeCode
    textField.addTarget(
      context.coordinator,
      action: #selector(Coordinator.textChanged(_:)),
      for: .editingChanged
    )
    textField.delegate = context.coordinator
    return textField
  }

  func updateUIView(_ uiView: UITextField, context _: Context) {
    if uiView.text != text {
      uiView.text = text
    }
    if uiView.isSecureTextEntry != isSecure {
      uiView.isSecureTextEntry = isSecure
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UITextFieldDelegate {
    var parent: SecureTextField

    init(_ parent: SecureTextField) {
      self.parent = parent
    }

    @objc func textChanged(_ textField: UITextField) {
      parent.text = textField.text ?? ""
    }

    func textField(
      _: UITextField,
      shouldChangeCharactersIn _: NSRange,
      replacementString _: String
    ) -> Bool {
      return true
    }
  }
}
