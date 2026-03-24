import SwiftUI

struct ActiveLandingIntroPage: View {
  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 120)

      Image("icon_active_placeholder")
        .resizable()
        .scaledToFit()
        .frame(width: 120, height: 120)

      Spacer().frame(height: 52)

      Text("激活您的记录仪")
        .font(.system(size: 54 / 2, weight: .bold))
        .foregroundColor(Color(hex: "0x2F3136"))

      Spacer().frame(height: 20)

      Text("激活设备，立即开启远程预览、T卡回\n放、车辆位置服务。")
        .font(.system(size: 20))
        .lineSpacing(8)
        .multilineTextAlignment(.center)
        .foregroundColor(Color(hex: "0x76797E"))

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
