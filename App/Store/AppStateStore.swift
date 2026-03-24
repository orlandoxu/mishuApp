import Foundation
import SwiftUI

@MainActor
final class AppStateStore: ObservableObject {
  static let shared = AppStateStore()

  @Published private(set) var pendingLinkURLString: String? = nil
  @Published private(set) var bootstrapFinished: Bool = false
  @Published private(set) var rootViewReady: Bool = false
  @Published private(set) var userInfoRefreshed: Bool = false
  @Published private(set) var messageSynced: Bool = false

  private init() {}

  var canJumpPendingLink: Bool {
    bootstrapFinished && rootViewReady
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
  }

  func markMessageSynced() {
    messageSynced = true
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
      if let navRoute = NavigationRoute(path: path, params: params) {
        if case .login = navigation.root {
          navigation.root = .mainTab(.home)
        }
        navigation.popToRoot()
        navigation.push(navRoute)
      }
    }

    clearPendingLink()
  }
}
