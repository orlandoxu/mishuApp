import UIKit

// 使用方法：
// UIApplication.shared.dismissKeyboard()

extension UIApplication {
  func dismissKeyboard() {
    sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil,
      from: nil,
      for: nil
    )
  }
}

enum Haptics {
  private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)

  static func impactLight() {
    lightGenerator.prepare()
    lightGenerator.impactOccurred()
  }
}
