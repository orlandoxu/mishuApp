import Foundation
import Network
import SwiftUI
import UIKit

@MainActor
final class WebSocketStore: ObservableObject {
  static let shared = WebSocketStore()

  // MARK: - Published Properties

  @Published private(set) var status: WebsocketStatus = .idle
  @Published private(set) var isNetworkReachable: Bool = true
  @Published private(set) var lastConnectedAt: Date?
  @Published private(set) var lastMessageAt: Date?
  @Published private(set) var isAuthenticated: Bool = false

  // MARK: - Observers

  /// 推送事件观察者
  private var pushEventObservers: [(SocketPushEvent) -> Void] = []

  var notice: String? {
    switch status {
    case .idle, .connecting, .connected, .suspended:
      return nil
    case .disconnected, .failed, .reconnecting:
      return "服务器连接失败，请检查网络"
    }
  }

  // MARK: - Private Properties

  private let service = WebsocketHelper()
  private var lifecycleObservers: [NSObjectProtocol] = []
  private var currentToken: String?
  private var startCount: Int = 0

  // MARK: - Initialization

  private init() {
    // 自动注册VehiclesStore作为观察者
    pushEventObservers.append { event in
      VehiclesStore.shared.handlePushEvent(event)
    }

    Task {
      await service.setHandlers(
        onStatus: { [weak self] status in
          Task { @MainActor in
            self?.handleStatusChange(status)
          }
        },
        onMessage: { [weak self] message in
          Task { @MainActor in
            self?.handleMessage(message)
          }
        },
        onPushEvent: { [weak self] event in
          Task { @MainActor in
            self?.handlePushEvent(event)
          }
        }
      )
    }
  }

  // MARK: - Observer Management

  /// 添加推送事件观察者
  func addObserver(_ handler: @escaping (SocketPushEvent) -> Void) {
    pushEventObservers.append(handler)
  }

  /// 移除所有观察者
  func removeAllObservers() {
    pushEventObservers.removeAll()
    // 重新注册VehiclesStore
    pushEventObservers.append { event in
      VehiclesStore.shared.handlePushEvent(event)
    }
  }

  // MARK: - Public Methods

  func start(token: String) {
    startCount += 1
    currentToken = token

    if case .suspended = status {
      status = .disconnected
    }

    log("start #\(startCount), reachable=\(isNetworkReachable)")

    Task {
      await service.connect(token: token, url: AppConst.appWebSocketURL)
    }
  }

  func stop() {
    log("stop")
    currentToken = nil
    isAuthenticated = false
    status = .idle
    Task {
      await service.disconnect()
    }
  }

  func appDidEnterBackground() {
    log("appDidEnterBackground")
    status = .suspended
    Task {
      await service.disconnect()
    }
  }

  func appWillEnterForeground() {
    log("appWillEnterForeground")
    guard let token = currentToken, !token.isEmpty else { return }
    start(token: token)
  }

  // MARK: - Private Methods

  private func handleStatusChange(_ status: WebsocketStatus) {
    let previous = self.status
    self.status = status

    switch status {
    case .connected:
      lastConnectedAt = Date()
      isAuthenticated = true
    case .disconnected, .failed:
      isAuthenticated = false
    default:
      break
    }

    log("status \(statusText(previous)) -> \(statusText(status))")
  }

  private func handleMessage(_ message: SocketMessage) {
    lastMessageAt = Date()
    msgLog("message type=\(message.type) taskId=\(message.taskId ?? "-")")
  }

  private func handlePushEvent(_ event: SocketPushEvent) {
    msgLog("push event: \(event)")

    // 通知所有观察者
    for observer in pushEventObservers {
      observer(event)
    }
  }

  // MARK: - App 生命周期监听

  /// 启动 App 生命周期监听
  /// 作用：监听 App 进入后台/进入前台，自动断开/重连 Socket
  private func startMonitoring() {
    let center = NotificationCenter.default

    // 监听：App 进入后台
    let didEnterBackground = center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.appDidEnterBackground()
    }

    // 监听：App 即将进入前台
    let willEnterForeground = center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.appWillEnterForeground()
    }
    // 保存观察者引用，防止被释放
    lifecycleObservers = [didEnterBackground, willEnterForeground]
  }

  private func stopMonitoring() {
    let center = NotificationCenter.default
    lifecycleObservers.forEach { center.removeObserver($0) }
    lifecycleObservers.removeAll()
  }

  // MARK: - 日志

  private func log(_ message: String) {
    LKLog("[Store] \(message)", type: "socket", label: "info")
    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      let timestamp = formatter.string(from: Date())
      print("[Store] \(timestamp) \(message)")
    #endif
  }

  private func msgLog(_ message: String) {
    LKLog("[Store] \(message)", type: "socket", label: "debug")
    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      let timestamp = formatter.string(from: Date())
      print("[Store] \(timestamp) \(message)")
    #endif
  }

  private func statusText(_ status: WebsocketStatus) -> String {
    switch status {
    case .idle:
      return "idle"
    case .connecting:
      return "connecting"
    case .connected:
      return "connected"
    case .disconnected:
      return "disconnected"
    case let .reconnecting(attempt):
      return "reconnecting(\(attempt))"
    case .suspended:
      return "suspended"
    case let .failed(message):
      return "failed(\(message))"
    }
  }
}
