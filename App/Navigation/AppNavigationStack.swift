import SwiftUI

struct AppNavigationStack: View {
  @ObservedObject private var model = AppNavigationModel.shared
  @Namespace private var namespace

  var body: some View {
    NavigationStack(
      path: Binding(
        get: { model.path },
        set: { model.handleSystemPathUpdate($0) }
      )
    ) {
      RootHostView()
        .environment(\.nsGlobal, namespace)
        .navigationBarHidden(true)
        .onAppear {
          AppStateStore.shared.markRootViewReady()
        }
        .navigationDestination(for: NavigationPathItem.self) { item in
          item.route.view()
            .environment(\.nsGlobal, namespace)
            .navigationBarHidden(true)
        }
    }
  }
}

private struct RootHostView: View {
  @ObservedObject private var model = AppNavigationModel.shared

  var body: some View {
    switch model.root {
    case .login:
      LoginView()
    case let .mainTab(tab):
      MainTabView(initialTab: tab)
        // 启动websocket服务
        .taskOnce {
          if let token = SelfStore.shared.token, !token.isEmpty {
            WebSocketStore.shared.start(token: token)
          }
        }
        // 监听本地网络
        .taskOnce {
          await MainActor.run {
            WifiStore.shared.startMonitoringWifi()
          }
        }
        // 刷新用户信息 & 启动友盟登录
        .taskOnce {
          await SelfStore.shared.refresh()

          await AppStateStore.shared.markUserInfoRefreshed()

          if let userId = SelfStore.shared.selfUser?.userId {
            UmengService.login(userId: userId)
          }
        }
        // 同步最新的消息
        .taskOnce {
          await MessageStore.shared.syncLatest()

          await AppStateStore.shared.markMessageSynced()
        }
        .onAppear {
          LocalNetworkPermissionStore.shared.refresh()
          LocalNetworkPermissionStore.shared.requestIfNeeded()
        }
    }
  }
}
