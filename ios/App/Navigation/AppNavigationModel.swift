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
    if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
      root = .mainTab(.home)
      if let route = Self.uiTestingRoute() {
        path = [NavigationPathItem(route: route)]
      }
    } else {
      root = SelfStore.shared.isLoggedIn ? .mainTab(.home) : .login
    }
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

  private static func uiTestingRoute() -> NavigationRoute? {
    let arguments = ProcessInfo.processInfo.arguments
    guard let index = arguments.firstIndex(of: "--ui-route"),
          arguments.indices.contains(index + 1)
    else {
      return nil
    }

    switch arguments[index + 1] {
    case "contacts":
      return .contacts
    case "trueMemory":
      return .trueMemory
    case "memory":
      return .memory
    case "moneyJar":
      return .moneyJar
    case "treeHole":
      return .treeHole
    case "pro":
      return .pro
    default:
      return nil
    }
  }
}

enum NavigationRoot: Hashable {
  case login
  case mainTab(MainTab)
}

enum NavigationRoute: Hashable {
  case web(url: String, title: String?)
  case settings
  case contacts
  case memory
  case trueMemory
  case partner
  case child
  case moneyJar
  case treeHole
  case pro
  case checkout(planName: String, price: String)
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
    case .settings:
      SettingsView()
    case .contacts:
      ContactsView()
    case .memory:
      MemoryView()
    case .trueMemory:
      TrueMemoryView()
    case .partner:
      PartnerView()
    case .child:
      ChildView()
    case .moneyJar:
      MoneyJarView()
    case .treeHole:
      TreeHoleView()
    case .pro:
      ProMembershipView()
    case let .checkout(planName, price):
      CheckoutView(planName: planName, price: price)
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
