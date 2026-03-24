// import Combine
// import SwiftUI

/**
 * 键盘避让
 * 用不了，这个没有写好，通过增加padding，无法解决scrollView的键盘避让问题
 */
// // me: 键盘事件处理
// extension Publishers {
//   static var keyboardInfo:
//     AnyPublisher<(height: CGFloat, duration: TimeInterval, curve: UInt), Never>
//   {
//     let willShow = NotificationCenter.default.publisher(
//       for: UIResponder.keyboardWillShowNotification
//     )
//     let willHide = NotificationCenter.default.publisher(
//       for: UIResponder.keyboardWillHideNotification
//     )
//     let willChange = NotificationCenter.default.publisher(
//       for: UIResponder.keyboardWillChangeFrameNotification
//     )

//     return MergeMany(willShow, willHide, willChange)
//       .map {
//         notification -> (height: CGFloat, duration: TimeInterval, curve: UInt)
//         in
//         let duration =
//           (notification.userInfo?[
//             UIResponder.keyboardAnimationDurationUserInfoKey
//           ] as? NSNumber)?.doubleValue ?? 0.25
//         let curve =
//           (notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey]
//           as? NSNumber)?.uintValue
//           ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
//         let keyboardFrame =
//           (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
//             as? CGRect) ?? .zero
//         let keyboardHeight =
//           notification.name == UIResponder.keyboardWillHideNotification
//           ? 0 : keyboardFrame.height

//         return (height: keyboardHeight, duration: duration, curve: curve)
//       }
//       .eraseToAnyPublisher()
//   }
// }

// // me: 键盘避让修饰器
// struct KeyboardAvoidingModifier: ViewModifier {
//   @State private var keyboardHeight: CGFloat = 0

//   func body(content: Content) -> some View {
//     ZStack {
//       content

//       // me: 用于撑开底部空间
//       VStack {
//         Spacer()
//         Color.clear
//           .frame(height: keyboardHeight)
//       }
//     }
//     .animation(.none, value: keyboardHeight)
//     .onReceive(Publishers.keyboardInfo) { info in
//       withAnimation(
//         .timingCurve(0.2, 0.8, 0.2, 1.0, duration: info.duration)
//       ) {
//         self.keyboardHeight = info.height
//       }
//     }
//   }
// }

// // me: View 扩展
// extension View {
//   func keyboardAvoiding() -> some View {
//     modifier(KeyboardAvoidingModifier())
//   }
// }
