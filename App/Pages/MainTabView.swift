import SwiftUI

enum MainTab: Hashable {
  case home
}

struct MainTabView: View {
  @State private var selectedTab: MainTab = .home

  init(initialTab: MainTab) {
    _selectedTab = State(initialValue: initialTab)
  }

  var body: some View {
    VStack(spacing: 20) {
      Text("Mishu AI")
        .font(.system(size: 28, weight: .bold))

      Text("基础框架已保留，业务功能已移除")
        .font(.system(size: 16))
        .foregroundColor(.secondary)

      Button("退出登录") {
        Task { @MainActor in
          await SelfStore.shared.logout(false)
          AppNavigationModel.shared.root = .login
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
  }
}
