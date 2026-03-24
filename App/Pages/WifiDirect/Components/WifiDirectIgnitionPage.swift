import SwiftUI

struct WifiDirectIgnitionPage: View {
  let onStart: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 0) {
        Text("车辆点火")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(Color(hex: "0x333333"))
          .padding(.top, 32)

        Text("确保记录仪已安装，点火车辆，并保持车辆处于点火状态")
          .font(.system(size: 14))
          .foregroundColor(Color(hex: "0x666666"))
          .padding(.top, 8)
          .padding(.horizontal, 32)
          .multilineTextAlignment(.center)

        Spacer().frame(height: 30)

        Image("img_start_engine")
          .frame(maxWidth: .infinity)

        Spacer()

        Button(action: onStart) {
          Text("已点火, 立即直连")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "0x28C4FB"))
            .cornerRadius(24)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
      }
    }
    .background(Color(hex: "0xF3F4F6"))
  }
}
