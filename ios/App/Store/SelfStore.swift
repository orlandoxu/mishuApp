import Foundation
import SwiftUI

@MainActor
final class SelfStore: ObservableObject {
  static let shared = SelfStore()

  private let tokenKey = "mishu_auth_token"
  private let userKey = "mishu_auth_user"

  @Published private(set) var token: String? = nil
  @Published var selfUser: UserModel? = nil
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil

  var isLoggedIn: Bool {
    token?.isEmpty == false
  }

  var mobile: String? {
    selfUser?.mobile
  }

  private init() {
    token = UserDefaults.standard.string(forKey: tokenKey)
    if let data = UserDefaults.standard.data(forKey: userKey),
       let decoded = try? JSONDecoder().decode(UserModel.self, from: data)
    {
      selfUser = decoded
    }
  }

  func applyLogin(_ data: LoginData) {
    UserDefaults.standard.set(data.token, forKey: tokenKey)
    UserDefaults.standard.removeObject(forKey: userKey)
    token = data.token
    selfUser = nil

    Task {
      await refresh()
    }
  }

  func clearAuth() {
    UserDefaults.standard.removeObject(forKey: tokenKey)
    UserDefaults.standard.removeObject(forKey: userKey)
    token = nil
    selfUser = nil
    AppStateStore.shared.clearPendingLink()
  }

  func refresh() async {
    guard isLoggedIn else {
      clear()
      return
    }

    if isLoading { return }
    isLoading = true
    errorMessage = nil

    if let user = await UserAPI.shared.getInfo() {
      selfUser = user
      if let encoded = try? JSONEncoder().encode(user) {
        UserDefaults.standard.set(encoded, forKey: userKey)
      }
    } else {
      errorMessage = "用户信息获取失败"
    }

    isLoading = false
  }

  func clear() {
    selfUser = nil
    errorMessage = nil
    isLoading = false
  }

  func logout(_ noticeServer: Bool = true) async {
    if noticeServer {
      _ = await UserAPI.shared.logout()
    }

    clearAuth()
    clear()
  }
}
