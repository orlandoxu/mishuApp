import Foundation
import UIKit

actor AgentRouteWebSocketClient {
  static let shared = AgentRouteWebSocketClient()

  private let sessionIdKey = "mishu_agent_route_session_id"
  private var sessionVersion: Int?

  func requestReply(text: String) async throws -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "我没有听清楚，请再说一次。" }

    let request = await makeTurnRequest(text: trimmed)
    let envelope = try await sendTurnRequest(request)
    sessionVersion = envelope.payload.sessionVersion
    return envelope.payload.replyText
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

    return AgentTurnRequest(
      protocolVersion: "2026-04-14.v2",
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

  private func sendTurnRequest(_ request: AgentTurnRequest) async throws -> AgentTurnResultEnvelope {
    guard let token = await MainActor.run(body: { SelfStore.shared.token }),
          !token.isEmpty
    else {
      throw NSError(
        domain: "AgentRouteWebSocketClient",
        code: 401,
        userInfo: [NSLocalizedDescriptionKey: "缺少登录 token，无法发起 agent 路由请求"]
      )
    }

    var urlRequest = URLRequest(url: AppConst.appWebSocketURL)
    urlRequest.timeoutInterval = 15
    urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let task = URLSession.shared.webSocketTask(with: urlRequest)
    task.resume()
    defer {
      task.cancel(with: .normalClosure, reason: nil)
    }

    let payload: [String: Any] = [
      "type": "rpc",
      "method": "agent.turn",
      "requestId": request.messageId,
      "payload": try request.asDictionary(),
    ]
    try await task.send(.string(try payload.asJSONString()))

    let timeoutNs: UInt64 = 12_000_000_000
    while true {
      let raw = try await receiveText(task: task, timeoutNs: timeoutNs)
      guard let data = raw.data(using: .utf8) else { continue }
      let message = try JSONDecoder().decode(RpcResultEnvelope<AgentTurnResponse>.self, from: data)
      guard message.type == "rpc" else { continue }
      guard message.requestId == request.messageId else { continue }
      if !message.payload.isSuccess {
        throw NSError(
          domain: "AgentRouteWebSocketClient",
          code: 500,
          userInfo: [NSLocalizedDescriptionKey: message.payload.msg ?? "服务端执行失败"]
        )
      }
      guard let businessData = message.payload.data else {
        throw NSError(
          domain: "AgentRouteWebSocketClient",
          code: 500,
          userInfo: [NSLocalizedDescriptionKey: "服务端返回数据为空"]
        )
      }
      return AgentTurnResultEnvelope(
        type: message.type,
        requestId: message.requestId,
        payload: businessData
      )
    }
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
        throw NSError(
          domain: "AgentRouteWebSocketClient",
          code: 408,
          userInfo: [NSLocalizedDescriptionKey: "等待服务端响应超时"]
        )
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

private struct AgentTurnResultEnvelope: Decodable {
  let type: String
  let requestId: String?
  let payload: AgentTurnResponse
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
