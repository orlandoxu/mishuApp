import SwiftUI

struct SettingsView: View {
  @ObservedObject private var navigation = AppNavigationModel.shared
  @ObservedObject private var selfStore = SelfStore.shared

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F2F2F7").ignoresSafeArea()

      ScrollView(showsIndicators: false) {
        VStack(spacing: 28) {
          profile

          VStack(spacing: 24) {
            SettingsGroup(title: "账号与安全") {
              SettingsRow(symbol: "bubble.left.and.bubble.right.fill", symbolColor: Color(hex: "#07C160"), title: "微信绑定", value: "已绑定")
              Divider().padding(.leading, 58)
              SettingsRow(symbol: "message.fill", symbolColor: Color(hex: "#12B7F5"), title: "QQ 绑定", value: "去绑定")
            }

            SettingsGroup(title: "通用与隐私") {
              SettingsRow(symbol: "iphone.radiowaves.left.and.right", symbolColor: Color(hex: "#FF6B6B"), title: "触觉反馈")
              Divider().padding(.leading, 58)
              SettingsRow(symbol: "shield.fill", symbolColor: Color(hex: "#FF6B6B"), title: "隐私设置")
            }

            Button(action: logout) {
              HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("退出登录")
              }
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "#FF3B30"))
              .frame(maxWidth: .infinity)
              .padding(.vertical, 16)
              .background(Color.white)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
          }
          .padding(.horizontal, 16)
        }
        .padding(.top, 88)
        .padding(.bottom, 42)
      }

      NavHeader(title: "")
        .background(Color.clear)
    }
  }

  private var profile: some View {
    VStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color(hex: "#FFE0F0"), Color(hex: "#DCEEFF")],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: 96, height: 96)
        Text("探")
          .font(.system(size: 34, weight: .black))
          .foregroundColor(Color.black.opacity(0.62))
      }

      HStack(spacing: 8) {
        Text("探索者")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(Color.black.opacity(0.90))
        Text("PRO")
          .font(.system(size: 10, weight: .black))
          .foregroundColor(Color(hex: "#F3E5AB"))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color.black)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }

      HStack(spacing: 4) {
        Text(selfStore.mobile ?? "138 **** 8888")
          .font(.system(size: 14, weight: .medium))
        Image(systemName: "chevron.right")
          .font(.system(size: 11, weight: .bold))
      }
      .foregroundColor(Color.black.opacity(0.50))
    }
    .frame(maxWidth: .infinity)
  }

  private func logout() {
    Task {
      await selfStore.logout(false)
      navigation.root = .login
    }
  }
}
