import SwiftUI

struct WifiDirectOpeningPage: View {
  let onCancel: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 40)

      ZStack {
        Circle()
          .fill(Color(hex: "0xB9E8FD"))
          .frame(width: 120, height: 120)
          .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

        Image(systemName: "wifi")
          .font(.system(size: 42, weight: .semibold))
          .foregroundColor(ThemeColor.brand500)
      }

      Spacer().frame(height: 30)

      HStack(spacing: 12) {
        Text("正在打开设备WiFi")
          .font(.system(size: 52 / 3, weight: .semibold))
      }
      .padding(.horizontal, 36)
      .frame(height: 64)
      .background(Color.white.opacity(0.55))
      .cornerRadius(32)
      .padding(.top, 48)

      Spacer()

      Button(action: onCancel) {
        Text("取消")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x666666"))
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(Color(hex: "0xEAEAEA"))
          .cornerRadius(24)
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 40)
    }
    .background(Color(hex: "0xF3F4F6"))
  }
}
