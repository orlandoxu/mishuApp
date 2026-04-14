// import SwiftUI
// @_spi(Advanced) import SwiftUIIntrospect

// /**
//  * 这个插件的作用，是清除 Picker 的背景色
//  * 因为 SwiftUI 的 Picker 的背景色，是默认的，无法通过 SwiftUI 的属性来修改
//  * 所以需要使用这个插件，来清除 Picker 的背景色
//  * 这个插件，是基于 SwiftUIIntrospect 的插件
//  * 所以需要先安装 SwiftUIIntrospect
//  * 安装方法：https://github.com/siteline/swiftui-introspect
//  */

// extension View {
//   // 添加背景色，作用是如果有多个pickers，那么可以通过为多个pickers的父HStack
//   // 添加一个整体的背景（实际上是作用在pickers的父view伤的）
//   // 所以实际上，添加背景色的这个，是不需要使用Introspect的
//   func pickerAddBgColor(_ color: Color = Color("#EEEEF0")) -> some View {
//     // 添加一个拉通的，宽为父view的宽，高为默认的picker的高的背景
//     self.frame(maxWidth: .infinity)
//       .background(
//         Rectangle()
//           .fill(color)
//           .frame(maxWidth: .infinity)
//           .frame(height: 32)
//           .cornerRadius(5)
//       )
//   }
// }
