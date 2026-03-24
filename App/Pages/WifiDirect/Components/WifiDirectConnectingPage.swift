import SwiftUI

// MARK: - WifiDirectConnectingPage

/// WiFi 直连 - 正在连接设备页面
/// 展示手机与设备通过 WiFi 连接的动画效果
struct WifiDirectConnectingPage: View {
  // MARK: - Properties

  /// 取消按钮回调
  let onCancel: () -> Void

  // MARK: - State

  @State private var isAnimating = false

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 40)

      // 连接动画区域
      HStack(spacing: 24) {
        // 手机图标
        Image("img_mobile")

        // 动态连接点
        HStack(spacing: 4) {
          ForEach(0 ..< 3, id: \.self) { index in
            Circle()
              .fill(ThemeColor.brand500)
              .frame(width: 8, height: 8)
              .opacity(isAnimating ? 0.3 : 1.0)
              .animation(
                Animation
                  .easeInOut(duration: 1.0)
                  .repeatForever(autoreverses: true)
                  .delay(Double(index) * 0.2),
                value: isAnimating
              )
          }
        }
        .frame(width: 40)

        // 设备图标
        Image("img_vehicle_default")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
      }
      .padding(.top, 60)

      Spacer().frame(height: 30)

      // 提示文字
      Text("正在连接设备...")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x999999"))
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(24)

      Spacer()

      // 取消按钮
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
    .onAppear {
      isAnimating = true
    }
  }
}
