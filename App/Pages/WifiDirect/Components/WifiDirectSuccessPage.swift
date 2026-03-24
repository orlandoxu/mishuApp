import SwiftUI

struct WifiDirectSuccessPage: View {
  let imei: String

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 40)

      ZStack {
        Circle()
          .fill(Color(hex: "0xEAF8EF"))
          .frame(width: 120, height: 120)
          .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

        Image(systemName: "wifi")
          .font(.system(size: 44, weight: .semibold))
          .foregroundColor(Color(hex: "0x16B50B"))
      }

      Text("连接成功")
        .font(.system(size: 22, weight: .semibold))
        .foregroundColor(Color(hex: "0x333333"))
        .padding(.top, 54)

      Spacer()

      Button(action: {
        AppNavigationModel.shared.replaceTop(with: .vehicleLive(deviceId: imei, entryMode: .wifi))
      }) {
        Text("连接成功，进入wifi模式")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(Color(hex: "0x28C4FB"))
          .cornerRadius(24)
      }
      .padding(.horizontal, 32)

      Spacer().frame(height: 40)
    }
    .background(Color(hex: "0xF3F4F6"))
  }
}
