import Foundation
import SwiftUI

@MainActor
final class AppStateStore: ObservableObject {
  static let shared = AppStateStore()

  @Published private(set) var pendingLinkURLString: String? = nil

  // 下面是启动的时候的一些步骤是否完成
  @Published private(set) var bootstrapFinished: Bool = false // 引导完成
  @Published private(set) var rootViewReady: Bool = false // 根视图准备就绪
  @Published private(set) var userInfoRefreshed: Bool = false // 用户信息是否刷新完成
  @Published private(set) var messageSynced: Bool = false // 消息是否同步完成

  private init() {}

  var canJumpPendingLink: Bool {
    bootstrapFinished && rootViewReady && userInfoRefreshed && messageSynced
  }

  func markBootstrapFinished() {
    bootstrapFinished = true
    handlePendingLinkIfPossible()
  }

  func markRootViewReady() {
    rootViewReady = true
    handlePendingLinkIfPossible()
  }

  func markUserInfoRefreshed() {
    userInfoRefreshed = true
    handlePendingLinkIfPossible()
  }

  func markMessageSynced() {
    messageSynced = true
    handlePendingLinkIfPossible()
  }

  func cachePendingLink(urlString: String?) {
    let trimmed = (urlString ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    pendingLinkURLString = trimmed
    handlePendingLinkIfPossible()
  }

  func clearPendingLink() {
    pendingLinkURLString = nil
  }

  func handlePendingLinkIfPossible() {
    guard canJumpPendingLink else { return }
    guard let raw = pendingLinkURLString else { return }
    guard let url = URL(string: raw) else {
      clearPendingLink()
      return
    }

    guard let route = RouteParser.parseLinkProtocol(url) else {
      clearPendingLink()
      return
    }

    guard SelfStore.shared.isLoggedIn else { return }

    let navigation = AppNavigationModel.shared
    switch route {
    case let .page(path, params, _):
      if path == "/message" {
        navigation.root = .mainTab(.message)
      } else if let navRoute = NavigationRoute(path: path, params: params) {
        if case .login = navigation.root {
          navigation.root = .mainTab(.recorder)
        }
        navigation.popToRoot()
        navigation.push(navRoute)
      } else {
        clearPendingLink()
        return
      }
    }

    clearPendingLink()
  }
}
