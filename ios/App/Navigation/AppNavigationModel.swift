import Foundation
import SwiftUI

@MainActor
final class AppNavigationModel: ObservableObject {
  static let shared = AppNavigationModel()

  @Published var root: NavigationRoot {
    didSet { path.removeAll() }
  }

  @Published var path: [NavigationPathItem] = []

  private init() {
    // Step 1. 按迁移阶段需求，App 启动时统一直接进入主页
    // Step 2. 保留登录页路由与页面实现，后续可随时恢复登录入口
    root = .mainTab(.home)
  }

  func push(_ route: NavigationRoute) {
    path.append(NavigationPathItem(route: route))
  }

  func pop() {
    guard !path.isEmpty else { return }
    path.removeLast()
  }

  func replaceTop(with route: NavigationRoute) {
    if path.isEmpty {
      push(route)
    } else {
      path[path.count - 1] = NavigationPathItem(route: route)
    }
  }

  func popToRoot() {
    path.removeAll()
  }

  func last() -> NavigationRoute? {
    path.last?.route
  }

  func handleSystemPathUpdate(_ newPath: [NavigationPathItem]) {
    path = newPath
  }
}

enum NavigationRoot: Hashable {
  case login
  case mainTab(MainTab)
}

enum NavigationRoute: Hashable {
  case web(url: String, title: String?)
}

extension NavigationRoute {
  init?(path: String, params: [RouteParam]) {
    guard path == "/webview" else { return nil }
    let paramsDict = Dictionary(uniqueKeysWithValues: params.map { ($0.key, $0.value) })
    guard let url = paramsDict["url"], !url.isEmpty else { return nil }
    self = .web(url: url, title: paramsDict["title"])
  }

  @ViewBuilder @MainActor
  func view() -> some View {
    switch self {
    case let .web(url, title):
      BasicWebView(urlString: url, title: title)
    }
  }
}

struct NavigationPathItem: Hashable {
  let id: UUID
  let route: NavigationRoute

  init(id: UUID = UUID(), route: NavigationRoute) {
    self.id = id
    self.route = route
  }
}
