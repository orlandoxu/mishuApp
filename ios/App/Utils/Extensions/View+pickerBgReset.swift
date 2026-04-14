// import SwiftUI
// @_spi(Advanced) import SwiftUIIntrospect

// /**
//  * 备注：有怀疑过这个插件，可能会带来性能问题或者内存泄漏
//  * 但经过测试，没有找到明显的证据，证明会有上面的问题
//  * 所以，目前该解决方案，目前可以认为，是完美的。
//  *
//  * 这个插件的作用，是清除 Picker 的背景色
//  * 因为 SwiftUI 的 Picker 的背景色，是默认的，无法通过 SwiftUI 的属性来修改
//  * 所以需要使用这个插件，来清除 Picker 的背景色
//  * 这个插件，是基于 SwiftUIIntrospect 的插件
//  * 所以需要先安装 SwiftUIIntrospect
//  * 安装方法：https://github.com/siteline/swiftui-introspect
//  *
//  * 注意，下面这个代码，是解决不了问题的（我测试过）
//  * // 设置默认的Picker样式
//  * UIPickerView.appearance().tintColor = .clear
//  * // 你可以尝试设置其他属性，如背景色
//  * UIPickerView.appearance().backgroundColor = .clear
//  */

// extension View {
//   /// 清除 Picker 的背景色
//   func pickerBgReset(color: Color = .clear) -> some View {
//     self.introspect(.picker(style: .wheel), on: .iOS(.v14...)) { picker in
//       picker.subviews[1].backgroundColor = UIColor(color)
//     }
//   }
// }
