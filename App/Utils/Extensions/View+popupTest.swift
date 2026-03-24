// import SwiftUI
/**
 * 这是View+popup.swift的测试文件
 * 由于没啥用了，所以注释掉了
 * 内部有一个nested的测试方法，实际上nested没啥用。
 * 因为popup根本没有实现这个功能！
 */

// /// 测试弹窗功能的视图
// struct PopupTestView: View {
//   @State private var showSimplePopup = false
//   @State private var showCustomPopup = false
//   @State private var showNestedPopup = false
//   @State private var showLargePopup = false

//   var body: some View {
//     NavigationView {
//       ScrollView {
//         VStack(spacing: 20) {
//           Text("弹窗测试")
//             .font(.largeTitle)
//             .padding(.top, 30)

//           // 简单弹窗测试
//           Button("显示简单弹窗") {
//             showSimplePopup = true
//           }
//           .buttonStyle(TestButtonStyle())
//           .popup(isPresented: $showSimplePopup) {
//             SimplePopupView()
//           }

//           // 自定义弹窗测试
//           Button("显示自定义弹窗") {
//             showCustomPopup = true
//           }
//           .buttonStyle(TestButtonStyle())
//           .popup(isPresented: $showCustomPopup) {
//             CustomPopupView()
//           }

//           // 嵌套弹窗测试
//           Button("显示嵌套弹窗") {
//             showNestedPopup = true
//           }
//           .buttonStyle(TestButtonStyle())
//           .popup(isPresented: $showNestedPopup) {
//             NestedPopupView()
//           }

//           // 大型弹窗测试
//           Button("显示大型弹窗") {
//             showLargePopup = true
//           }
//           .buttonStyle(TestButtonStyle())
//           .popup(isPresented: $showLargePopup) {
//             LargePopupView()
//           }

//           // 使用PopupLink测试
//           PopupLink(
//             destination: SimplePopupView(),
//             label: {
//               Text("使用PopupLink显示弹窗")
//                 .padding()
//                 .frame(maxWidth: .infinity)
//                 .background(Color.purple)
//                 .foregroundColor(.white)
//                 .cornerRadius(10)
//                 .padding(.horizontal)
//             }
//           )

//           Spacer()
//         }
//         .padding()
//       }
//       .navigationBarTitle("弹窗测试", displayMode: .inline)
//     }
//     // 注册弹窗容器
//     .registerPopupContainer()
//   }
// }

// /// 测试按钮样式
// struct TestButtonStyle: ButtonStyle {
//   func makeBody(configuration: Configuration) -> some View {
//     configuration.label
//       .padding()
//       .frame(maxWidth: .infinity)
//       .background(
//         configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue
//       )
//       .foregroundColor(.white)
//       .cornerRadius(10)
//       .padding(.horizontal)
//       .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
//       .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
//   }
// }

// /// 简单弹窗视图
// struct SimplePopupView: View {
//   @Environment(\.popupDismiss) private var popupDismiss

//   var body: some View {
//     VStack(spacing: 20) {
//       Text("简单弹窗")
//         .font(.headline)

//       Button("关闭") {
//         popupDismiss()
//       }
//       .padding()
//       .background(Color.red)
//       .foregroundColor(.white)
//       .cornerRadius(8)
//     }
//     .frame(width: 300, height: 200)
//     .background(Color.white)
//     .cornerRadius(12)
//   }
// }

// /// 自定义弹窗视图
// struct CustomPopupView: View {
//   @Environment(\.popupDismiss) private var popupDismiss
//   @State private var selectedTab = 0

//   var body: some View {
//     VStack(spacing: 0) {
//       // 标题栏
//       HStack {
//         Text("自定义弹窗")
//           .font(.headline)

//         Spacer()

//         Button(action: popupDismiss) {
//           Image(systemName: "xmark.circle.fill")
//             .foregroundColor(.gray)
//             .font(.title2)
//         }
//       }
//       .padding()
//       .background(Color.gray.opacity(0.1))

//       // 选项卡
//       HStack {
//         ForEach(0..<3) { index in
//           Button(
//             action: { selectedTab = index },
//             label: {
//               Text("选项 \(index + 1)")
//                 .padding(.vertical, 10)
//                 .padding(.horizontal, 15)
//                 .background(selectedTab == index ? Color.blue : Color.clear)
//                 .foregroundColor(selectedTab == index ? .white : .black)
//                 .cornerRadius(5)
//             }
//           )
//         }
//       }
//       .padding(.vertical, 10)

//       // 内容区域
//       TabView(selection: $selectedTab) {
//         ForEach(0..<3) { index in
//           VStack {
//             Text("内容 \(index + 1)")
//               .font(.title2)

//             Text("这是选项卡 \(index + 1) 的内容")
//               .foregroundColor(.gray)
//               .padding()
//           }
//           .tag(index)
//         }
//       }
//       .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//       .frame(height: 200)

//       // 底部按钮
//       HStack {
//         Button("取消", action: popupDismiss)
//           .frame(maxWidth: .infinity)
//           .padding()
//           .background(Color.gray.opacity(0.2))
//           .foregroundColor(.black)

//         Button("确定", action: popupDismiss)
//           .frame(maxWidth: .infinity)
//           .padding()
//           .background(Color.blue)
//           .foregroundColor(.white)
//       }
//     }
//     .frame(width: 350, height: 400)
//     .background(Color.white)
//     .cornerRadius(12)
//   }
// }

// /// 嵌套弹窗视图
// struct NestedPopupView: View {
//   @Environment(\.popupDismiss) private var popupDismiss
//   @State private var showNestedPopup = false

//   var body: some View {
//     VStack(spacing: 20) {
//       Text("嵌套弹窗")
//         .font(.headline)

//       Button("显示二级弹窗") {
//         showNestedPopup = true
//       }
//       .padding()
//       .background(Color.green)
//       .foregroundColor(.white)
//       .cornerRadius(8)
//       .popup(isPresented: $showNestedPopup) {
//         VStack(spacing: 20) {
//           Text("二级弹窗")
//             .font(.headline)

//           Button("关闭二级弹窗") {
//             showNestedPopup = false
//           }
//           .padding()
//           .background(Color.orange)
//           .foregroundColor(.white)
//           .cornerRadius(8)
//         }
//         .frame(width: 250, height: 150)
//         .background(Color.white)
//         .cornerRadius(12)
//       }

//       Button("关闭") {
//         popupDismiss()
//       }
//       .padding()
//       .background(Color.red)
//       .foregroundColor(.white)
//       .cornerRadius(8)
//     }
//     .frame(width: 300, height: 200)
//     .background(Color.white)
//     .cornerRadius(12)
//   }
// }

// /// 大型弹窗视图
// struct LargePopupView: View {
//   @Environment(\.popupDismiss) private var popupDismiss

//   var body: some View {
//     VStack(spacing: 0) {
//       // 标题栏
//       HStack {
//         Text("大型弹窗")
//           .font(.headline)

//         Spacer()

//         Button(action: popupDismiss) {
//           Image(systemName: "xmark.circle.fill")
//             .foregroundColor(.gray)
//             .font(.title2)
//         }
//       }
//       .padding()
//       .background(Color.gray.opacity(0.1))

//       // 内容区域
//       ScrollView {
//         VStack(alignment: .leading, spacing: 15) {
//           ForEach(1...20, id: \.self) { index in
//             HStack {
//               Image(systemName: "circle.fill")
//                 .foregroundColor(.blue)
//                 .font(.caption)

//               Text("这是列表项 \(index)")
//                 .font(.body)

//               Spacer()

//               Text("详情")
//                 .foregroundColor(.blue)
//             }
//             .padding(.horizontal)
//             .padding(.vertical, 8)
//             .background(index % 2 == 0 ? Color.gray.opacity(0.05) : Color.clear)
//           }
//         }
//       }

//       // 底部按钮
//       Button("关闭", action: popupDismiss)
//         .frame(maxWidth: .infinity)
//         .padding()
//         .background(Color.blue)
//         .foregroundColor(.white)
//     }
//     .frame(width: 350, height: 500)
//     .background(Color.white)
//     .cornerRadius(12)
//   }
// }

// #Preview {
//   PopupTestView()
// }
