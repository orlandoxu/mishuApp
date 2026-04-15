import Foundation

struct AgentTurnRequest: Encodable {
  let protocolVersion: String
  let sessionId: String
  let turnId: String
  let messageId: String
  let text: String
  let timestamp: Int64
  let clientSessionVersion: Int?
  let clientContext: AgentClientContext
}

struct AgentClientContext: Encodable {
  let locale: String
  let timezone: String
  let platform: String
  let appVersion: String
  let deviceId: String?
}

struct AgentTurnResponse: Decodable {
  let sessionId: String
  let sessionVersion: Int
  let turnId: String
  let messageId: String
  let phase: String
  let message: String
  let protocolEnvelope: AgentProtocolEnvelope?

  enum CodingKeys: String, CodingKey {
    case sessionId
    case sessionVersion
    case turnId
    case messageId
    case phase
    case message
    case protocolEnvelope = "protocol"
  }

  var replyText: String {
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "服务端未返回可展示内容" }
    return trimmed
  }
}

struct AgentProtocolEnvelope: Decodable {
  let version: String
  let recommendedInput: String
  let directives: [AgentDirective]
}

struct AgentDirective: Decodable {
  let type: String
  let text: String?
  let prompt: String?
  let summary: String?
  let message: String?
}
