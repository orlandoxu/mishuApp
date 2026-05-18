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
  let resultData: [String: AgentJSONValue]?
  let protocolEnvelope: AgentProtocolEnvelope?

  enum CodingKeys: String, CodingKey {
    case sessionId
    case sessionVersion
    case turnId
    case messageId
    case phase
    case message
    case resultData
    case protocolEnvelope = "protocol"
  }

  var replyText: String {
    let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "服务端未返回可展示内容" }
    return trimmed
  }

  var isTerminal: Bool {
    ["completed", "failed", "fallback", "cancelled"].contains(phase)
  }
}

struct AgentFoodMemoryDTO: Decodable, Equatable {
  let id: String
  let name: String
  let category: String
  let pricePerPerson: Double
  let review: String
  let rating: Int
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
  let request: AgentCapabilityRequest?
  let requestId: String?
  let action: String?
  let payload: [String: AgentJSONValue]?
}

struct AgentCapabilityRequest: Decodable {
  let requestId: String
  let kind: String
  let query: String
  let topK: Int?
  let namespace: String?
  let reason: String?
  let action: String?
  let payload: [String: AgentJSONValue]?
}

enum AgentJSONValue: Decodable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case object([String: AgentJSONValue])
  case array([AgentJSONValue])
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode(Double.self) {
      self = .number(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode([String: AgentJSONValue].self) {
      self = .object(value)
    } else if let value = try? container.decode([AgentJSONValue].self) {
      self = .array(value)
    } else {
      throw DecodingError.typeMismatch(AgentJSONValue.self, .init(codingPath: decoder.codingPath, debugDescription: "unsupported json value"))
    }
  }

  var rawObject: Any {
    switch self {
    case let .string(value):
      return value
    case let .number(value):
      return value
    case let .bool(value):
      return value
    case let .object(value):
      return value.mapValues { $0.rawObject }
    case let .array(value):
      return value.map { $0.rawObject }
    case .null:
      return NSNull()
    }
  }
}
