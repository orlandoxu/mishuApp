import SwiftUI

struct VehicleSettingsSubPageView: View {
  let title: String
  let items: [TemplateItem]
  @ObservedObject private var store = TemplateStore.shared

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: title)

      ScrollView {
        VehicleSettingsListView(items: items)

        Spacer().frame(height: 200)
      }
      .background(Color(hex: "0xF5F6F7"))
      .onTapGesture {
        // 点击空白地方收起键盘
        UIApplication.shared.dismissKeyboard()
      }
    }
    .ignoresSafeArea()
    .navigationBarHidden(true)
  }
}
