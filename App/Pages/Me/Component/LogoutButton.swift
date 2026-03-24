import SwiftUI

struct LogoutButton: View {
  @StateObject private var selfStore: SelfStore = .shared
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var showLogoutAlert = false

  var body: some View {
    Button {
      showLogoutAlert = true
    } label: {
      Text("退出登录")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(ThemeColor.gray500)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.white)
        .cornerRadius(12)
    }
    .buttonStyle(.plain)
    .alert(isPresented: $showLogoutAlert) {
      Alert(
        title: Text("请确认"),
        message: Text("确定退出登录吗？"),
        primaryButton: .destructive(Text("确定")) {
          Task {
            await selfStore.logout()
            await MainActor.run {
              appNavigation.root = .login
            }
          }
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
  }
}
