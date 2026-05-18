import Foundation
import UIKit

actor AgentRouteWebSocketClient {
  static let shared = AgentRouteWebSocketClient()
  private let responseTimeoutNs: UInt64 = 20_000_000_000

  private let sessionIdKey = "mishu_agent_route_session_id"
  private var sessionVersion: Int?

  func startNewSession() {
    let nextId = "ios-\(UUID().uuidString.lowercased())"
    UserDefaults.standard.set(nextId, forKey: sessionIdKey)
    sessionVersion = nil
  }

  func currentSessionId() -> String {
    loadOrCreateSessionId()
  }

  func requestReply(
    text: String,
    onEvent: (@Sendable (AgentTurnResponse) async -> Void)? = nil
  ) async throws -> AgentTurnResponse {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw NSError(domain: "AgentRouteWebSocketClient", code: 400, userInfo: [NSLocalizedDescriptionKey: "我没有听清楚，请再说一次。"])
    }

    let request = await makeTurnRequest(text: trimmed)
    return try await sendTurnRequest(request, onEvent: onEvent)
  }

  private func makeTurnRequest(text: String) async -> AgentTurnRequest {
    let sessionId = loadOrCreateSessionId()
    let now = Int64(Date().timeIntervalSince1970 * 1000)
    let locale = Locale.preferredLanguages.first ?? Locale.current.identifier
    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"

    let deviceId = await MainActor.run {
      UIDevice.current.identifierForVendor?.uuidString
    }

    #if DEBUG
    print("[agent.turn][ios] sessionId=\(sessionId) sessionVersion=\(sessionVersion.map(String.init) ?? "nil")")
    #endif

    return AgentTurnRequest(
      protocolVersion: "2026-05-08.v3",
      sessionId: sessionId,
      turnId: UUID().uuidString,
      messageId: UUID().uuidString,
      text: text,
      timestamp: now,
      clientSessionVersion: sessionVersion,
      clientContext: AgentClientContext(
        locale: locale,
        timezone: TimeZone.current.identifier,
        platform: "ios",
        appVersion: "\(appVersion)(\(buildNumber))",
        deviceId: deviceId
      )
    )
  }

  private func sendTurnRequest(
    _ request: AgentTurnRequest,
    onEvent: (@Sendable (AgentTurnResponse) async -> Void)? = nil
  ) async throws -> AgentTurnResponse {
    do {
      return try await sendTurnRequestOnce(request, onEvent: onEvent)
    } catch {
      let nsError = error as NSError
      guard nsError.code == 408 else { throw error }
      return try await sendTurnRequestOnce(request, onEvent: onEvent)
    }
  }

  private func sendTurnRequestOnce(
    _ request: AgentTurnRequest,
    onEvent: (@Sendable (AgentTurnResponse) async -> Void)? = nil
  ) async throws -> AgentTurnResponse {
    guard let token = await MainActor.run(body: { SelfStore.shared.token }), !token.isEmpty else {
      throw NSError(domain: "AgentRouteWebSocketClient", code: 401, userInfo: [NSLocalizedDescriptionKey: "缺少登录 token，无法发起 agent 路由请求"])
    }

    var urlRequest = URLRequest(url: AppConst.appWebSocketURL)
    urlRequest.timeoutInterval = 60
    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.webSocketTask(with: urlRequest)
    task.resume()
    defer {
      task.cancel(with: .normalClosure, reason: nil)
    }

    return try await withTimeout(nanoseconds: responseTimeoutNs) { [self] in
      try await self.sendRpc(task: task, payload: try request.asDictionary(), requestId: request.messageId)

      while true {
        let raw = try await self.receiveText(task: task, timeoutNs: self.responseTimeoutNs)
        guard let data = raw.data(using: .utf8) else { continue }
        guard let businessData = try self.decodeTurnResponse(data: data) else { continue }

        self.sessionVersion = businessData.sessionVersion
        if let onEvent {
          await onEvent(businessData)
        }

        if let actionDirective = businessData.protocolEnvelope?.directives.first(where: { $0.type == "request_client_action" }) {
          let actionRequestId = actionDirective.requestId ?? ""
          let action = actionDirective.action ?? ""
          let payload = actionDirective.payload?.mapValues { $0.rawObject } ?? [:]
          let actionResult = await self.executeClientAction(action: action, payload: payload)

          let interaction: [String: Any] = [
            "kind": "client_action_response",
            "payload": [
              "requestId": actionRequestId,
              "action": action,
              "success": actionResult.success,
              "result": actionResult.result,
              "error": actionResult.error ?? NSNull(),
            ],
          ]

          let followPayload: [String: Any] = [
            "protocolVersion": request.protocolVersion,
            "sessionId": businessData.sessionId,
            "turnId": UUID().uuidString,
            "messageId": UUID().uuidString,
            "text": "client_action_response",
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "clientSessionVersion": businessData.sessionVersion,
            "clientContext": try request.clientContext.asDictionary(),
            "interaction": interaction,
          ]

          try await self.sendRpc(task: task, payload: followPayload, requestId: UUID().uuidString)
          continue
        }

        if businessData.isTerminal {
          return businessData
        }

        // 需要用户确认/补槽时，立即把服务端提示回显到 UI，避免一直停在“思考中”
        if shouldReturnForUserInput(phase: businessData.phase) {
          return businessData
        }
      }
    }
  }

  private func withTimeout<T>(nanoseconds: UInt64, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask {
        try await operation()
      }
      group.addTask {
        try await Task.sleep(nanoseconds: nanoseconds)
        throw NSError(domain: "AgentRouteWebSocketClient", code: 408, userInfo: [NSLocalizedDescriptionKey: "等待服务端响应超时"])
      }
      let value = try await group.next()!
      group.cancelAll()
      return value
    }
  }

  private func shouldReturnForUserInput(phase: String) -> Bool {
    phase == "collecting_slots" || phase == "awaiting_confirmation"
  }

  private func decodeTurnResponse(data: Data) throws -> AgentTurnResponse? {
    guard
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let type = object["type"] as? String
    else {
      return nil
    }

    if type == "rpc" {
      let message = try JSONDecoder().decode(RpcResultEnvelope<AgentTurnResponse>.self, from: data)
      if !message.payload.isSuccess {
        throw NSError(domain: "AgentRouteWebSocketClient", code: 500, userInfo: [NSLocalizedDescriptionKey: message.payload.msg ?? "服务端执行失败"])
      }
      guard let turn = message.payload.data else {
        throw NSError(domain: "AgentRouteWebSocketClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "服务端返回数据为空"])
      }
      return turn
    }

    if type == "agent_turn_result" {
      let message = try JSONDecoder().decode(SocketMessage.self, from: data)
      if case let .agentTurnResult(turn)? = message.payload {
        return turn
      }
    }

    if type == "agent_turn_update",
       let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
       let payload = object["payload"],
       JSONSerialization.isValidJSONObject(payload)
    {
      let payloadData = try JSONSerialization.data(withJSONObject: payload)
      if let turn = try? JSONDecoder().decode(AgentTurnResponse.self, from: payloadData) {
        return turn
      }
    }

    // 兼容服务端其他消息壳：只要 payload 结构可解为 AgentTurnResponse 就接收
    if
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let payload = object["payload"],
      JSONSerialization.isValidJSONObject(payload)
    {
      let payloadData = try JSONSerialization.data(withJSONObject: payload)
      if let turn = try? JSONDecoder().decode(AgentTurnResponse.self, from: payloadData) {
        return turn
      }
    }

    return nil
  }

  private func executeClientAction(action: String, payload: [String: Any]) async -> (success: Bool, result: [String: Any], error: String?) {
    switch action {
    case "money.record":
      do {
        let direction = (payload["direction"] as? String) == "income" ? LedgerDirection.income : LedgerDirection.expense
        let amount = (payload["amount"] as? NSNumber)?.doubleValue ?? Double((payload["amount"] as? String) ?? "0") ?? 0
        let category = (payload["category"] as? String) ?? "其他"
        let note = payload["note"] as? String
        let occurredAt = (payload["occurredAt"] as? NSNumber)?.int64Value ?? Int64(Date().timeIntervalSince1970 * 1000)

        let record = try await LedgerLocalService.shared.createTransaction(
          input: LedgerCreateInput(direction: direction, amount: amount, category: category, occurredAt: occurredAt, note: note)
        )
        let label = direction == .income ? "收入" : "支出"
        return (true, ["summary": "已记账：\(label) \(Int(record.amount.rounded())) 元（\(record.category)）"], nil)
      } catch {
        return (false, [:], error.localizedDescription)
      }

    case "money.query":
      do {
        let period = (payload["period"] as? String) ?? "day"
        let range = makeRange(period: period)
        let summary = try await LedgerLocalService.shared.querySummary(periodStartMs: range.startMs, periodEndMs: range.endMs, groupByCategory: true)
        let topCategories = summary.byCategory
          .sorted { $0.value > $1.value }
          .prefix(3)
          .map { "\($0.key)\(Int($0.value.rounded()))" }
          .joined(separator: "、")
        let text = "查询完成：支出\(Int(summary.expenseTotal.rounded())) 元，收入\(Int(summary.incomeTotal.rounded())) 元" + (topCategories.isEmpty ? "" : "；主要支出：\(topCategories)")
        return (true, ["summary": text], nil)
      } catch {
        return (false, [:], error.localizedDescription)
      }

    default:
      return (false, [:], "不支持的本地动作: \(action)")
    }
  }

  private func makeRange(period: String) -> (startMs: Int64, endMs: Int64) {
    let calendar = Calendar.moneyJar
    let now = Date()
    let start: Date
    switch period {
    case "month":
      start = now.moneyJarMonthStart
    case "week":
      start = now.moneyJarWeekStart
    default:
      start = calendar.startOfDay(for: now)
    }

    let end: Date
    switch period {
    case "month":
      end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
    case "week":
      end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
    default:
      end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
    }

    return (
      Int64(start.timeIntervalSince1970 * 1000),
      Int64(end.timeIntervalSince1970 * 1000) - 1
    )
  }

  private func sendRpc(task: URLSessionWebSocketTask, payload: [String: Any], requestId: String) async throws {
    let rpcEnvelope: [String: Any] = [
      "type": "rpc",
      "method": "agent.turn",
      "requestId": requestId,
      "payload": payload,
    ]
    try await task.send(.string(try rpcEnvelope.asJSONString()))
  }

  private func receiveText(task: URLSessionWebSocketTask, timeoutNs: UInt64) async throws -> String {
    try await withThrowingTaskGroup(of: String.self) { group in
      group.addTask {
        let message = try await task.receive()
        switch message {
        case let .string(text):
          return text
        case let .data(data):
          return String(data: data, encoding: .utf8) ?? ""
        @unknown default:
          return ""
        }
      }

      group.addTask {
        try await Task.sleep(nanoseconds: timeoutNs)
        throw NSError(domain: "AgentRouteWebSocketClient", code: 408, userInfo: [NSLocalizedDescriptionKey: "等待服务端响应超时"])
      }

      let value = try await group.next() ?? ""
      group.cancelAll()
      return value
    }
  }

  private func loadOrCreateSessionId() -> String {
    if let existing = UserDefaults.standard.string(forKey: sessionIdKey), !existing.isEmpty {
      return existing
    }
    let newId = "ios-\(UUID().uuidString.lowercased())"
    UserDefaults.standard.set(newId, forKey: sessionIdKey)
    return newId
  }
}

private enum RpcCode: Decodable {
  case int(Int)
  case string(String)

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(Int.self) {
      self = .int(value)
      return
    }
    self = .string((try? container.decode(String.self)) ?? "")
  }

  var isSuccess: Bool {
    if case let .int(value) = self {
      return value == 0
    }
    return false
  }
}

private struct RpcBusinessPayload<T: Decodable>: Decodable {
  let code: RpcCode
  let msg: String?
  let data: T?

  var isSuccess: Bool {
    code.isSuccess
  }
}

private struct RpcResultEnvelope<T: Decodable>: Decodable {
  let type: String
  let requestId: String?
  let payload: RpcBusinessPayload<T>
}

private extension Encodable {
  func asDictionary() throws -> [String: Any] {
    let data = try JSONEncoder().encode(self)
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dict = object as? [String: Any] else {
      throw NSError(domain: "AgentRouteWebSocketClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Encode object is not dictionary"])
    }
    return dict
  }
}

private extension Dictionary where Key == String, Value == Any {
  func asJSONString() throws -> String {
    let data = try JSONSerialization.data(withJSONObject: self)
    guard let text = String(data: data, encoding: .utf8) else {
      throw NSError(domain: "AgentRouteWebSocketClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot convert payload to json text"])
    }
    return text
  }
}
