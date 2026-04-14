import SwiftUI

struct AppNavigationStack: View {
  @ObservedObject private var model = AppNavigationModel.shared

  var body: some View {
    NavigationStack(
      path: Binding(
        get: { model.path },
        set: { model.handleSystemPathUpdate($0) }
      )
    ) {
      RootHostView()
        .navigationBarHidden(true)
        .onAppear {
          AppStateStore.shared.markRootViewReady()
          AppStateStore.shared.markUserInfoRefreshed()
          AppStateStore.shared.markMessageSynced()
        }
        .navigationDestination(for: NavigationPathItem.self) { item in
          item.route.view()
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
      MainView(initialTab: tab)
    }
  }
}
