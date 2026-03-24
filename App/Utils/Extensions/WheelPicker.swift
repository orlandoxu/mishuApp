// import SwiftUI
// import UIKit

// /**
//  * 这是一个滚轮的Picker，采用的是UIKit中的UIPickerView
//  * 作用是替代SwiftUI中的Picker，因为swiftUI中的Picker无法自定义样式
//  *
//  * 实现了的功能
//  * 1. 实现了swiftUI的Picker的功能
//  * 2. 支持设置Picker选中行的背景色
//  * 3. 实现不成熟，会崩溃，我先注销了
//  */

// struct WheelPicker<SelectionValue: Hashable, Content: View>: UIViewRepresentable
// {
//   // MARK: - Properties
//   @Binding var selection: SelectionValue
//   let content: Content
//   let selectedBackgroundColor: UIColor

//   // MARK: - Initialization
//   init(
//     selection: Binding<SelectionValue>,
//     selectedBackgroundColor: UIColor = .clear,
//     @ViewBuilder content: () -> Content
//   ) {
//     self._selection = selection
//     self.selectedBackgroundColor = selectedBackgroundColor
//     self.content = content()
//   }

//   // MARK: - UIViewRepresentable
//   func makeCoordinator() -> Coordinator {
//     Coordinator(self)
//   }

//   func makeUIView(context: Context) -> UIPickerView {
//     let picker = UIPickerView()
//     picker.dataSource = context.coordinator
//     picker.delegate = context.coordinator

//     // 设置初始选中行
//     let options = parseContent()
//     if let index = options.firstIndex(where: { $0.value == selection }) {
//       picker.selectRow(index, inComponent: 0, animated: false)
//     }

//     return picker
//   }

//   func updateUIView(_ uiView: UIPickerView, context: Context) {
//     let options = parseContent()

//     // 当选中项变化时更新
//     if let index = options.firstIndex(where: { $0.value == selection }) {
//       uiView.selectRow(index, inComponent: 0, animated: true)
//     }
//   }

//   // MARK: - Private Methods
//   private func parseContent() -> [(value: SelectionValue, view: AnyView)] {
//     var options: [(value: SelectionValue, view: AnyView)] = []

//     // 获取内容中的所有选项
//     let mirror = Mirror(reflecting: content)
//     if let children = mirror.children.first?.value {
//       let childrenMirror = Mirror(reflecting: children)
//       for child in childrenMirror.children {
//         if let taggedView = child.value as? (any View),
//           let tag = Mirror(reflecting: taggedView).children.first(where: {
//             $0.label == "tag"
//           })?.value as? SelectionValue
//         {
//           options.append((tag, AnyView(taggedView)))
//         }
//       }
//     }
//     return options
//   }

//   // MARK: - Coordinator
//   class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
//     var parent: WheelPicker
//     private var currentOptions: [(value: SelectionValue, view: AnyView)] = []

//     init(_ parent: WheelPicker) {
//       self.parent = parent
//       super.init()
//       self.currentOptions = parent.parseContent()
//     }

//     // MARK: UIPickerViewDataSource
//     func numberOfComponents(in pickerView: UIPickerView) -> Int {
//       return 1
//     }

//     func pickerView(
//       _ pickerView: UIPickerView,
//       numberOfRowsInComponent component: Int
//     ) -> Int {
//       return currentOptions.count
//     }

//     // MARK: UIPickerViewDelegate
//     func pickerView(
//       _ pickerView: UIPickerView,
//       didSelectRow row: Int,
//       inComponent component: Int
//     ) {
//       parent.selection = currentOptions[row].value
//     }

//     func pickerView(
//       _ pickerView: UIPickerView,
//       viewForRow row: Int,
//       forComponent component: Int,
//       reusing view: UIView?
//     ) -> UIView {
//       let hostingController = UIHostingController(
//         rootView:
//           currentOptions[row].view
//           .background(
//             row == pickerView.selectedRow(inComponent: 0)
//               ? Color(parent.selectedBackgroundColor)
//               : Color.clear
//           )
//       )
//       return hostingController.view
//     }

//     func pickerView(
//       _ pickerView: UIPickerView,
//       rowHeightForComponent component: Int
//     ) -> CGFloat {
//       return 32
//     }
//   }
// }
