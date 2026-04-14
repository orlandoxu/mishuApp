import Foundation
import UIKit

enum WebsocketStatus: Equatable {
  case idle // 未连接
  case connecting // 正在连接中
  case connected // 已连接
  case disconnected // 已断开
  case reconnecting(attempt: Int) // 正在重连中
  case suspended // 已暂停，等待重新连接
  case failed(message: String) // 连接失败，包含失败信息
}

/// 消息回调类型
typealias SocketMessageHandler = @Sendable (SocketMessage) -> Void
typealias SocketPushEventHandler = @Sendable (SocketPushEvent) -> Void

actor WebsocketHelper {
  // MARK: - 回调

  private var onStatus: (@Sendable (WebsocketStatus) -> Void)?
  private var onMessageHandler: ((SocketMessage) -> Void)?
  private var onPushEventHandler: ((SocketPushEvent) -> Void)?

  // MARK: - 连接状态

  private var socketTask: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var pingTask: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?
  private var desiredConnection: Bool = false
  private var networkReachable: Bool = true

  /// 查询当前是否已连接（供外部判断是否需要触发重连）
  var isConnected: Bool {
    socketTask != nil && isAuthenticated
  }

  // MARK: - 配置

  private var currentToken: String?
  private var currentURL: URL?

  /// 心跳间隔（根据服务器配置9秒）
  private let heartbeatInterval: UInt64 = 5_000_000_000 // 5秒

  /// 是否已登录
  private var isAuthenticated: Bool = false

  // MARK: - 轻量调试信息

  private var currentConnectionId: String?
  private var currentConnectionStartAt: Date?

  // MARK: - 公共方法

  func setHandlers(
    onStatus: (@Sendable (WebsocketStatus) -> Void)?,
    onMessage: ((SocketMessage) -> Void)?,
    onPushEvent: ((SocketPushEvent) -> Void)?
  ) {
    self.onStatus = onStatus
    onMessageHandler = onMessage
    onPushEventHandler = onPushEvent
  }

  func setNetworkReachable(_ reachable: Bool) {
    if networkReachable != reachable {
      log("network reachable: \(networkReachable) -> \(reachable)")
    }

    networkReachable = reachable
    if !reachable {
      cleanupSocket(reason: "network unreachable", initiatedByClient: true)
      onStatus?(.disconnected)
      return
    }

    if desiredConnection {
      scheduleReconnectIfNeeded()
    }
  }

  func connect(token: String, url: URL) {
    let tokenChanged = currentToken != token
    let urlChanged = currentURL != url
    currentToken = token
    currentURL = url
    desiredConnection = true
    isAuthenticated = false

    log("connect requested tokenChanged=\(tokenChanged) urlChanged=\(urlChanged)")

    if tokenChanged || urlChanged {
      cleanupSocket(reason: "connect params changed", initiatedByClient: true)
    }
    scheduleReconnectIfNeeded()
  }

  func disconnect() {
    desiredConnection = false
    reconnectTask?.cancel()
    reconnectTask = nil
    cleanupSocket(reason: "manual disconnect", initiatedByClient: true)
    onStatus?(.disconnected)
  }

  // MARK: - 私有方法 - 连接管理

  private func scheduleReconnectIfNeeded() {
    guard reconnectTask == nil else { return }
    reconnectTask = Task {
      await runConnectLoop()
    }
  }

  private func runConnectLoop() async {
    var attempt = 0
    while !Task.isCancelled {
      guard desiredConnection else {
        reconnectTask = nil
        return
      }
      guard networkReachable else {
        onStatus?(.disconnected)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        continue
      }
      guard socketTask == nil else {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        continue
      }

      attempt += 1
      currentConnectionId = String(format: "%05d", Int.random(in: 0 ... 99999))
      currentConnectionStartAt = Date()

      if attempt == 1 {
        onStatus?(.connecting)
      } else {
        onStatus?(.reconnecting(attempt: attempt))
      }

      log("connect attempt #\(attempt)")

      do {
        try await openSocket()
        attempt = 0
        await startLoops()

        while socketTask != nil, desiredConnection, !Task.isCancelled {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
      } catch {
        isAuthenticated = false
        let message = summarize(error)
        log("open socket failed: \(message)")
        onStatus?(.failed(message: message))
        cleanupSocket(reason: "open socket failed", initiatedByClient: true)

        let backoff = min(pow(2.0, Double(min(attempt, 6))), 20.0)
        let jitter = Double.random(in: 0 ... (backoff * 0.2))
        let wait = backoff + jitter
        try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
      }
    }
    reconnectTask = nil
  }

  private func openSocket() async throws {
    guard let url = currentURL else { throw URLError(.badURL) }
    guard let token = currentToken, !token.isEmpty else { throw URLError(.userAuthenticationRequired) }

    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.webSocketTask(with: request)
    socketTask = task
    task.resume()
  }

  private func startLoops() async {
    receiveTask?.cancel()
    pingTask?.cancel()

    receiveTask = Task { [weak self] in
      await self?.receiveLoop()
    }
    pingTask = Task { [weak self] in
      await self?.pingLoop()
    }
  }

  // MARK: - 接收循环

  private func receiveLoop() async {
    while !Task.isCancelled {
      guard let task = socketTask else { return }
      do {
        let message = try await task.receive()
        switch message {
        case let .data(data):
          await handleReceivedData(data)
        case let .string(text):
          await handleReceivedText(text)
        @unknown default:
          break
        }
      } catch {
        let closeCode = task.closeCode.rawValue
        let closeReason = decodeCloseReason(task.closeReason)
        log("receive failed closeCode=\(closeCode) closeReason=\(closeReason) error=\(summarize(error))")
        cleanupSocket(reason: "receive failed", initiatedByClient: false)
        onStatus?(.disconnected)
        return
      }
    }
  }

  private func handleReceivedData(_ data: Data) async {
    guard let text = String(data: data, encoding: .utf8) else { return }
    await handleReceivedText(text)
  }

  private func handleReceivedText(_ text: String) async {
    guard let data = text.data(using: .utf8) else { return }

    do {
      let message = try JSONDecoder().decode(SocketMessage.self, from: data)
      onMessageHandler?(message)
      await handleServerMessage(message)
    } catch {
      msgLog("JSON decode error: \(error)")
    }
  }

  // MARK: - 服务端消息处理

  private func handleServerMessage(_ message: SocketMessage) async {
    let resolvedType: ServerMessageType?
    if message.type == "log_upload" {
      resolvedType = .appLogUpload
    } else {
      resolvedType = ServerMessageType(rawValue: message.type)
    }

    guard let type = resolvedType else {
      return
    }

    switch type {
    case .mobileInfo:
      await sendMobileInfoResponse(taskId: message.taskId)

    case .connected:
      guard case let .connected(payload)? = message.payload else { return }
      isAuthenticated = true
      log("server connected devices=\(payload.devices.count)")
      onStatus?(.connected)

    case .loginAck:
      msgLog("received login_ack")

    case .pong:
      msgLog("received pong")

    case .statusOnline:
      guard case let .statusOnline(payload)? = message.payload else { return }
      await sendAckIfNeeded(taskId: message.taskId)
      onPushEventHandler?(.deviceOnline(imei: payload.imei, status: payload.status, changeAt: payload.changeAt))

    case .statusTCard:
      guard case let .statusTCard(payload)? = message.payload else { return }
      await sendAckIfNeeded(taskId: message.taskId)
      onPushEventHandler?(.tcardStatus(imei: payload.imei, enabled: payload.tcard, changeAt: payload.changeAt))

    case .gpsUpdate:
      guard case let .gpsUpdate(payload)? = message.payload else { return }
      await sendAckIfNeeded(taskId: message.taskId)
      onPushEventHandler?(.gpsBatchUpdate(imei: payload.imei, points: payload.gps))

    case .deviceUnbind:
      guard case let .deviceUnbind(payload)? = message.payload else { return }
      let msg = payload.message ?? "设备已解绑"
      await sendAckIfNeeded(taskId: message.taskId)
      onPushEventHandler?(.deviceUnbind(imei: payload.imei, message: msg))

    case .shutdown:
      guard case let .shutdown(payload)? = message.payload else { return }
      let msg = payload.message ?? "server shutting down"
      onPushEventHandler?(.serverShutdown(message: msg))
      log("server shutdown: \(msg)")
      cleanupSocket(reason: "server shutdown", initiatedByClient: false)
      onStatus?(.disconnected)

    case .error:
      guard case let .error(payload)? = message.payload else { return }
      log("server error code=\(payload.code) msg=\(payload.message)")
      onPushEventHandler?(.error(code: payload.code, message: payload.message))

    case .appLogUpload:
      guard case let .appLogUpload(payload)? = message.payload else { return }
      let taskId = message.taskId
      await sendAckIfNeeded(taskId: taskId)
      onPushEventHandler?(.appLogUploadRequested(taskId: taskId ?? "", reason: payload.reason))
      log("received app_log_upload, taskId=\(taskId ?? "-"), reason=\(payload.reason ?? "-")")
      let uploadResult = await AppLogService.shared.uploadCurrentLog(trigger: .remote(taskId: taskId))
      let response = createAppLogUploadRespMessage(
        taskId: taskId,
        success: uploadResult.success,
        url: uploadResult.url,
        message: uploadResult.reason ?? (uploadResult.success ? "ok" : "failed")
      )
      do {
        try await sendDictMessage(response)
        log("sent app_log_upload_resp taskId=\(taskId ?? "-") success=\(uploadResult.success)")
      } catch {
        log("send app_log_upload_resp failed taskId=\(taskId ?? "-") error=\(summarize(error))")
      }
    }
  }

  // MARK: - 发送消息

  private func sendPingMessage() async throws {
    let pingMsg = createPingMessage()
    try await sendDictMessage(pingMsg)
    msgLog("sent ping")
  }

  private func sendAck(taskId: String) async throws {
    let ackMsg = createAckMessage(taskId: taskId)
    try await sendDictMessage(ackMsg)
    msgLog("sent ack for task: \(taskId)")
  }

  private func sendAckIfNeeded(taskId: String?) async {
    guard let taskId = taskId, !taskId.isEmpty else { return }
    do {
      try await sendAck(taskId: taskId)
    } catch {
      log("ack failed taskId=\(taskId) error=\(summarize(error))")
    }
  }

  private func sendMobileInfoResponse(taskId: String?) async {
    let payload = await MainActor.run {
      MobileInfoStateReportBuilder.buildMobileInfoPayload()
    }
    let responseMessage = createMobileInfoRespMessage(taskId: taskId, payload: payload)

    do {
      try await sendDictMessage(responseMessage)
      log("sent mobile_info_resp taskId=\(taskId ?? "-")")
    } catch {
      log("mobile_info_resp failed taskId=\(taskId ?? "-") error=\(summarize(error))")
    }
  }

  /// 发送字典类型消息
  private func sendDictMessage(_ message: [String: Any]) async throws {
    guard let task = socketTask else {
      throw URLError(.notConnectedToInternet)
    }

    let data = try JSONSerialization.data(withJSONObject: message)
    guard let text = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "WebsocketHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot convert message to string"])
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      task.send(.string(text)) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  private func sendMessage<T: Encodable>(_ message: T) async throws {
    guard let task = socketTask else {
      throw URLError(.notConnectedToInternet)
    }

    let data = try JSONEncoder().encode(message)
    guard let text = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "WebsocketHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot convert message to string"])
    }

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      task.send(.string(text)) { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: ())
        }
      }
    }
  }

  // MARK: - 心跳循环

  private func pingLoop() async {
    while !Task.isCancelled {
      try? await Task.sleep(nanoseconds: heartbeatInterval)
      guard desiredConnection, networkReachable else { continue }
      guard socketTask != nil, isAuthenticated else { continue }

      do {
        try await sendPingMessage()
      } catch {
        log("ping failed: \(summarize(error))")
        cleanupSocket(reason: "ping failed", initiatedByClient: true)
        onStatus?(.disconnected)
        return
      }
    }
  }

  // MARK: - 清理

  private func cleanupSocket(reason: String, initiatedByClient: Bool) {
    receiveTask?.cancel()
    receiveTask = nil
    pingTask?.cancel()
    pingTask = nil

    if let task = socketTask {
      var durationText = "-"
      if let currentConnectionStartAt {
        durationText = String(format: "%.1fs", Date().timeIntervalSince(currentConnectionStartAt))
      }
      log("cleanup reason=\(reason) byClient=\(initiatedByClient) duration=\(durationText)")
      if initiatedByClient {
        task.cancel(with: .goingAway, reason: nil)
      }
    }

    socketTask = nil
    isAuthenticated = false
    currentConnectionId = nil
    currentConnectionStartAt = nil
  }

  // MARK: - 日志

  private func log(_ message: String) {
    LKLog(message, type: "socket", label: "info")
    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      let timestamp = formatter.string(from: Date())
      let connectionId = currentConnectionId ?? "-"
      print("[\(connectionId)] \(timestamp) \(message)")
    #endif
  }

  private func msgLog(_ message: String) {
    LKLog(message, type: "socket", label: "debug")
    #if DEBUG
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm:ss.SSS"
      let timestamp = formatter.string(from: Date())
      let connectionId = currentConnectionId ?? "-"
      print("[\(connectionId)] \(timestamp) \(message)")
    #endif
  }

  private func summarize(_ error: Error) -> String {
    let nsError = error as NSError
    if let urlError = error as? URLError {
      return "URLError(\(urlError.code.rawValue): \(urlError.code))"
    }
    return "\(nsError.domain)#\(nsError.code): \(nsError.localizedDescription)"
  }

  private func decodeCloseReason(_ closeReason: Data?) -> String {
    guard let closeReason, !closeReason.isEmpty else { return "-" }
    if let text = String(data: closeReason, encoding: .utf8) {
      return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return "base64:\(closeReason.base64EncodedString())"
  }
}
