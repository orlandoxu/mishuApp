import Foundation

// MARK: - 基础消息结构

/// WebSocket 消息根结构
struct SocketMessage: Decodable {
  let type: String
  let taskId: String?
  let payload: SocketPayload?

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(String.self, forKey: .type)
    taskId = try container.decodeIfPresent(String.self, forKey: .taskId)

    // 根据type解码对应的payload
    switch type {
    case "connected":
      if let value = try? container.decode(ConnectedPayload.self, forKey: .payload) {
        payload = .connected(value)
      } else {
        payload = nil
      }
    case "login":
      if let value = try? container.decode(LoginPayload.self, forKey: .payload) {
        payload = .login(value)
      } else {
        payload = nil
      }
    case "login_ack":
      if let value = try? container.decode(LoginAckPayload.self, forKey: .payload) {
        payload = .loginAck(value)
      } else {
        payload = nil
      }
    case "ping":
      payload = .ping(PingPayload())
    case "pong":
      payload = .pong(PongPayload())
    case "ack":
      if let value = try? container.decode(AckPayload.self, forKey: .payload) {
        payload = .ack(value)
      } else {
        payload = nil
      }
    case "status_online":
      if let value = try? container.decode(DeviceOnlinePayload.self, forKey: .payload) {
        payload = .statusOnline(value)
      } else {
        payload = nil
      }
    case "status_tcard":
      if let value = try? container.decode(TCardStatusPayload.self, forKey: .payload) {
        payload = .statusTCard(value)
      } else {
        payload = nil
      }
    case "gps_update":
      if let value = try? container.decode(GPSBatchUpdatePayload.self, forKey: .payload) {
        payload = .gpsUpdate(value)
      } else {
        payload = nil
      }
    case "device_unbind":
      if let value = try? container.decode(DeviceUnbindPayload.self, forKey: .payload) {
        payload = .deviceUnbind(value)
      } else {
        payload = nil
      }
    case "shutdown":
      if let value = try? container.decode(ShutdownPayload.self, forKey: .payload) {
        payload = .shutdown(value)
      } else {
        payload = .shutdown(ShutdownPayload(message: nil))
      }
    case "error":
      if let value = try? container.decode(ErrorPayload.self, forKey: .payload) {
        payload = .error(value)
      } else {
        payload = nil
      }
    case "app_log_upload", "log_upload":
      if let value = try? container.decode(AppLogUploadPayload.self, forKey: .payload) {
        payload = .appLogUpload(value)
      } else {
        payload = .appLogUpload(AppLogUploadPayload(reason: nil, maxBytes: nil))
      }
    case "mobile_info":
      payload = nil
    default:
      payload = nil
    }
  }

  private enum CodingKeys: String, CodingKey {
    case type
    case taskId
    case payload
  }
}

// MARK: - Payload 枚举（按type区分）

/// 消息载荷 - 每个type有专属的结构
enum SocketPayload: Decodable {
  // 客户端消息
  case login(LoginPayload)
  case ping(PingPayload)
  case ack(AckPayload)

  // 服务端响应
  case connected(ConnectedPayload)
  case loginAck(LoginAckPayload)
  case pong(PongPayload)

  // 服务端推送
  case statusOnline(DeviceOnlinePayload)
  case statusTCard(TCardStatusPayload)
  case gpsUpdate(GPSBatchUpdatePayload)
  case deviceUnbind(DeviceUnbindPayload)
  case shutdown(ShutdownPayload)
  case error(ErrorPayload)
  case appLogUpload(AppLogUploadPayload)
}

// MARK: - 客户端消息Payload

/// 登录请求载荷
struct LoginPayload: Codable {
  let token: String
}

/// 心跳请求载荷（无数据）
struct PingPayload: Codable {}

/// 消息确认载荷
struct AckPayload: Codable {
  let taskId: String
}

// MARK: - 服务端响应Payload

/// 连接成功载荷
struct ConnectedPayload: Codable {
  let uid: String
  let devices: [String]
}

/// 登录响应载荷
struct LoginAckPayload: Codable {
  let uid: String
  let devices: [String]
}

/// 心跳响应载荷（无数据）
struct PongPayload: Codable {}

// MARK: - 服务端推送Payload

/// 设备在线状态载荷
/// status: 0-离线, 1-在线, 2-休眠
struct DeviceOnlinePayload: Codable {
  let imei: String
  let status: Int
  let changeAt: Int64
}

/// T-Card状态载荷
struct TCardStatusPayload: Codable {
  let imei: String
  let tcard: Bool
  let changeAt: Int64
}

/// GPS单点数据
struct GPSUpdatePayload: Codable {
  let imei: String
  let latitude: Double
  let longitude: Double
  let speed: Double
  let direction: Double
  let timestamp: Int64
}

/// GPS批量更新载荷
/// 服务端当前下发结构:
/// {
///   "imei": "...",
///   "gps": [
///     {"latitude":..., "longitude":..., "speed":..., "direction":..., "timestamp":...}
///   ]
/// }
struct GPSBatchUpdatePayload: Decodable {
  let imei: String
  let gps: [GPSModel]
}

/// 设备解绑载荷
struct DeviceUnbindPayload: Codable {
  let imei: String
  let message: String?
}

/// 服务器关闭载荷
struct ShutdownPayload: Codable {
  let message: String?
}

/// 错误响应载荷
struct ErrorPayload: Codable {
  let code: Int
  let message: String
}

struct AppLogUploadPayload: Codable {
  let reason: String?
  let maxBytes: Int?
}

// MARK: - 消息类型枚举

/// 服务端推送的消息类型
enum ServerMessageType: String, Codable {
  case connected
  case loginAck = "login_ack"
  case pong
  case mobileInfo = "mobile_info"
  case statusOnline = "status_online"
  case statusTCard = "status_tcard"
  case gpsUpdate = "gps_update"
  case deviceUnbind = "device_unbind"
  case shutdown
  case error
  case appLogUpload = "app_log_upload"
}

// MARK: - 推送消息事件

/// 推送消息事件 - 用于观察者模式
enum SocketPushEvent {
  case deviceOnline(imei: String, status: Int, changeAt: Int64)
  case tcardStatus(imei: String, enabled: Bool, changeAt: Int64)
  case gpsBatchUpdate(imei: String, points: [GPSModel])
  case deviceUnbind(imei: String, message: String)
  case serverShutdown(message: String)
  case error(code: Int, message: String)
  case appLogUploadRequested(taskId: String, reason: String?)
}

// MARK: - 客户端消息构建函数

/// 创建ping消息
func createPingMessage() -> [String: String] {
  ["type": "ping"]
}

/// 创建ACK消息
func createAckMessage(taskId: String) -> [String: Any] {
  ["type": "ack", "payload": ["taskId": taskId]]
}

/// 创建mobile_info_resp消息
func createMobileInfoRespMessage(taskId: String?, payload: [String: Any]) -> [String: Any] {
  var message: [String: Any] = [
    "type": "mobile_info_resp",
    "payload": payload,
  ]
  if let taskId, !taskId.isEmpty {
    message["taskId"] = taskId
  }
  return message
}

func createAppLogUploadRespMessage(
  taskId: String?,
  success: Bool,
  url: String?,
  message: String
) -> [String: Any] {
  var payload: [String: Any] = [
    "success": success,
    "message": message,
  ]
  if let url, !url.isEmpty {
    payload["url"] = url
  }
  var result: [String: Any] = [
    "type": "app_log_upload_resp",
    "payload": payload,
  ]
  if let taskId, !taskId.isEmpty {
    result["taskId"] = taskId
  }
  return result
}

// MARK: - 错误码定义

/// Socket错误码
enum SocketErrorCode: Int {
  // 认证相关 (1xxx)
  case invalidToken = 1001
  case tokenExpired = 1002
  case unauthenticated = 1003

  // 消息相关 (2xxx)
  case invalidMessage = 2001
  case messageTooLarge = 2002
  case unknownMessageType = 2003
  case rateLimitExceeded = 2004

  // 连接相关 (3xxx)
  case heartbeatTimeout = 3001
  case alreadyAuthenticated = 3002
  case connectionLimitExceeded = 3003

  // 业务相关 (4xxx)
  case deviceNotFound = 4001
  case insufficientPermission = 4002

  // 服务端错误 (5xxx)
  case internalError = 5001
  case serviceUnavailable = 5002
  case serviceBusy = 5003
}
