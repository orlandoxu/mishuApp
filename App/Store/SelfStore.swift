import Foundation
import SwiftUI

// DONE-AI: 登录态与用户信息由 SelfStore 统一管理（仅持久化 token + 用户信息）
@MainActor
final class SelfStore: ObservableObject {
  static let shared = SelfStore()

  private let tokenKey = "tuyun_auth_token"
  private let userKey = "tuyun_auth_user"

  @Published private(set) var token: String? = nil

  @Published var selfUser: UserModel? = nil
  // @Published var selfTripStatistical: UserTripStatistical? = nil // TODO: 未来这个要整合到selfUser里面去
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil

  var isLoggedIn: Bool {
    token?.isEmpty == false
  }

  var mobile: String? {
    selfUser?.mobile
  }

  /// 上传deviceToken到后台
  func uploadDeviceTokenIfNeeded() async {
    guard isLoggedIn else { return }

    guard let currentToken = NoticePermissionStore.shared.deviceToken, !currentToken.isEmpty else {
      print("[SelfStore] No deviceToken available")
      return
    }

    print("[SelfStore] Uploading deviceToken: \(currentToken)")

    if let _ = await UserAPI.shared.updateIosDeviceToken(currentToken) {
      print("[SelfStore] deviceToken uploaded successfully")
    } else {
      print("[SelfStore] Failed to upload deviceToken")
    }
  }

  private init() {
    // Step 1. 读取本地登录态
    token = UserDefaults.standard.string(forKey: tokenKey)
    if let data = UserDefaults.standard.data(forKey: userKey),
       let decoded = try? JSONDecoder().decode(UserModel.self, from: data)
    {
      selfUser = decoded
    }

    // Step 2. 初始化数据库
    if let userId = selfUser?.userId {
      try? AppDatabase.shared.setupIfNeeded(userId: userId)
    }
  }

  func applyLogin(_ data: LoginData) {
    // Step 1. 持久化 token 与用户信息
    UserDefaults.standard.set(data.token, forKey: tokenKey)
    UserDefaults.standard.removeObject(forKey: userKey)

    // Step 2. 更新内存状态
    token = data.token
    selfUser = nil

    // Step 3. 拉取并持久化用户信息
    Task {
      await refresh()
      await MessageStore.shared.syncLatest()

      // Step 4. 上传deviceToken到后台
      await uploadDeviceTokenIfNeeded()
    }
  }

  func clearAuth() {
    // Step 1. 清理登录信息
    UserDefaults.standard.removeObject(forKey: tokenKey)
    UserDefaults.standard.removeObject(forKey: userKey)

    // Step 2. 清理内存状态
    token = nil
    selfUser = nil
    WebSocketStore.shared.stop()
    AppDatabase.shared.reset()
    MessageStore.shared.reset()

    // Step 3. 清除登录的时候，要同步清除pendingLink
    AppStateStore.shared.clearPendingLink()
  }

  func refresh() async {
    // Step 1. 未登录直接清空
    guard isLoggedIn else {
      clear()
      return
    }

    // Step 2. 防止重复加载
    if isLoading { return }
    isLoading = true
    errorMessage = nil

    // Step 3. 拉取用户信息并同步基础字段
    if let user = await UserAPI.shared.getInfo() {
      selfUser = user
      if let encoded = try? JSONEncoder().encode(user) {
        UserDefaults.standard.set(encoded, forKey: userKey)
      }
      try? AppDatabase.shared.setupIfNeeded(userId: user.userId)
    } else {
      errorMessage = "用户信息获取失败"
    }

    // Step 4. 拉取行程统计信息
    // TODO: 目前先通过接口获取，后面要通过User接口服务器聚合
    // if let statistical = await TripAPI.shared.allStatisticalData() {
    //   selfTripStatistical = statistical
    // }

    // Step 5. 结束加载
    isLoading = false
  }

  func clear() {
    // Step 1. 清理本地缓存状态
    selfUser = nil
    errorMessage = nil
    isLoading = false
  }

  func logout(_ noticeServer: Bool = true) async {
    // Step 1. 请求后台退出（失败也要清本地）
    if noticeServer {
      _ = await UserAPI.shared.logout()
    }

    // Step 2. 清理本地登录态与用户信息
    clearAuth()
    clear()
  }
}
