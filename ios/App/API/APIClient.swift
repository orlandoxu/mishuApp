import Foundation

// 本文件包含功能：
// 1. 定义 request 方法，用于发起 HTTP 请求
// 2. 定义空结构体 Empty，用于表示无 body 的请求
// 3. 定义 AnyParams 结构体，用于封装任意 Encodable 参数

enum HTTPMethod: String {
  case Get = "GET"
  case Post = "POST"
  case Put = "PUT"
  case Patch = "PATCH"
  case Delete = "DELETE"
}

struct Empty: Codable {}

struct AnyParams: Encodable {
  private let encodeFunc: (Encoder) throws -> Void

  init<T: Encodable>(_ value: T) {
    encodeFunc = value.encode
  }

  func encode(to encoder: Encoder) throws {
    try encodeFunc(encoder)
  }
}

/// 用于封装任意 JSON 类型参数
enum JSONValue: Codable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case null
  case array([JSONValue])
  case object([String: JSONValue])

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if container.decodeNil() {
      self = .null
      return
    }
    if let value = try? container.decode(Bool.self) {
      self = .bool(value)
      return
    }
    if let value = try? container.decode(Int.self) {
      self = .int(value)
      return
    }
    if let value = try? container.decode(Double.self) {
      self = .double(value)
      return
    }
    if let value = try? container.decode(String.self) {
      self = .string(value)
      return
    }
    if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
      return
    }
    if let value = try? container.decode([String: JSONValue].self) {
      self = .object(value)
      return
    }

    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Unsupported JSON value"
    )
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .string(v): try container.encode(v)
    case let .int(v): try container.encode(v)
    case let .double(v): try container.encode(v)
    case let .bool(v): try container.encode(v)
    case .null: try container.encodeNil()
    case let .array(v): try container.encode(v)
    case let .object(v): try container.encode(v)
    }
  }
}

/// 统一 ret/msg/data 结构
struct APIResponse<T: Decodable>: Decodable {
  let ret: Int
  let msg: String?
  let data: T?

  private enum CodingKeys: String, CodingKey {
    case ret
    case msg
    case message
    case data
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    // Step 1. 解析ret
    ret = (try? container.decode(Int.self, forKey: .ret)) ?? 0

    // Step 2. 解析msg
    if let value = try? container.decodeIfPresent(String.self, forKey: .msg) {
      msg = value
    } else {
      msg = try? container.decodeIfPresent(String.self, forKey: .message)
    }

    // Step 3. 解析data
    // if container.contains(.data) {
    //   let isNull = try container.decodeNil(forKey: .data)
    //   if isNull {
    //     data = nil
    //   } else {
    //     data = try container.decode(T.self, forKey: .data)
    //   }
    // } else {
    //   data = nil
    // }
    if container.contains(.data) {
      if try container.decodeNil(forKey: .data) {
        data = nil
      } else {
        data = try container.decode(T.self, forKey: .data)
      }
    } else {
      data = nil
    }
  }
}

final class APIClient {
  static var defaultBaseURL: URL {
    resolvedBaseURL()
  }

  private let baseURL: URL
  private let session: URLSession
  private let storage: KeyValueStorage

  init(
    baseURL: URL = APIClient.defaultBaseURL,
    session: URLSession = .shared,
    storage: KeyValueStorage = UserDefaultsStorage()
  ) {
    self.baseURL = baseURL
    self.session = session
    self.storage = storage
  }

  private static func resolvedBaseURL() -> URL {
    if let override = UserDefaults.standard.string(forKey: "mishu_base_url_override"),
       let url = URL(string: override)
    {
      return url
    }

    // let env = UserDefaults.standard.string(forKey: "mishu_environment") ?? ""

    return AppConst.apiBaseURL
  }

  func getRequest<T: Decodable>(
    _ endpoint: String,
    _ body: Encodable? = Empty(),
    _ requiresAuth: Bool = true,
    _ toast: Bool = true
  ) async -> T? {
    return await request(.Get, endpoint, body, requiresAuth, toast)
  }

  func postRequest<T: Decodable>(
    _ endpoint: String,
    _ body: Encodable? = Empty(),
    _ requiresAuth: Bool = true,
    _ toast: Bool = true
  ) async -> T? {
    return await request(.Post, endpoint, body, requiresAuth, toast)
  }

  private func request<T: Decodable>(
    _ method: HTTPMethod = .Get,
    _ endpoint: String,
    _ body: Encodable? = Empty(),
    _ requiresAuth: Bool = true,
    _ toast: Bool = true
  ) async -> T? {
    let lastRoute = await AppNavigationModel.shared.last()
    do {
      return try await _request(method, endpoint, body, requiresAuth)
    } catch let error as BusinessError {
      let newLastRoute = await AppNavigationModel.shared.last()
      let notChanged = lastRoute == newLastRoute
      LKLog(
        "api business error endpoint=\(endpoint) code=\(error.code) message=\(error.message) toast=\(toast) sameRoute=\(notChanged)",
        type: "network",
        label: "warning"
      )
      if toast, notChanged {
        await ToastCenter.shared.show(error.message)
      }
      return nil
    } catch {
      LKLog(
        "api unknown error endpoint=\(endpoint) error=\(error.localizedDescription)",
        type: "network",
        label: "error"
      )
      // 其他错误直接忽略
      return nil
    }
  }

  private func _request<T: Decodable>(
    _ method: HTTPMethod = .Get,
    _ endpoint: String,
    _ body: Encodable? = Empty(),
    _ requiresAuth: Bool = true
  ) async throws -> T {
    // Step 1. 构建URL
    guard let url = URL(string: "\(APIClient.defaultBaseURL)\(endpoint)") else {
      throw BusinessError(message: "Invalid URL", code: 400, data: nil as Any?)
    }

    // Step 2. 创建请求
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Step 3. 添加认证头
    // TODO: 这儿可能要改改，要看看小镜的登录，是怎么做的，用的什么方案。大概率不是Bearer
    var authToken = UserDefaults.standard.string(forKey: "mishu_auth_token")
    // #if targetEnvironment(simulator)
    //   if authToken == nil || authToken?.isEmpty == true {
    //     authToken = "2tfz3JA6gx5YqF17r"
    //   }
    // #endif
    if requiresAuth, let token = authToken {
      request.setValue(token, forHTTPHeaderField: "Authorization")
    }

    // Step 4. 添加请求体
    if let body {
      // 先把 Codable body 转成字典
      let data = try JSONEncoder().encode(body)
      var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

      // 添加额外字段
      dict["appPlatform"] = "ios"
      dict["appVersion"] = "2.0.0" // 先写死，后续还需要做配置读

      // 转回 JSON Data
      request.httpBody = try JSONSerialization.data(withJSONObject: dict, options: [])
    }

    // Step 5. 发送请求
    // DispatchQueue.main.async {
    //   self.isLoading = true
    //   self.lastError = nil
    // }

    do {
      let requestBodyText: String = {
        guard let body = request.httpBody, !body.isEmpty else { return "-" }
        return String(data: body, encoding: .utf8) ?? "<binary \(body.count)b>"
      }()
      LKLog(
        "request method=\(request.httpMethod ?? "unknown") url=\(request.url?.absoluteString ?? "unknown") body=\(requestBodyText)",
        type: "network",
        label: "info"
      )

      let (data, response) = try await session.data(for: request)

      // DispatchQueue.main.async {
      //   self.isLoading = false
      // }

      // Step 6. 检查HTTP状态码
      guard let httpResponse = response as? HTTPURLResponse else {
        LKLog(
          "invalid http response url=\(request.url?.absoluteString ?? "unknown")",
          type: "network",
          label: "error"
        )
        throw BusinessError(message: "Invalid response", code: 400, data: nil as Any?)
      }

      LKLog(
        "response url=\(request.url?.absoluteString ?? "unknown") status=\(httpResponse.statusCode) body=\(String(data: data, encoding: .utf8) ?? "<binary \(data.count)b>")",
        type: "network",
        label: "info"
      )

      // Step 8. 处理服务器错误响应
      if httpResponse.statusCode >= 400 {
        // 尝试解析错误响应
        if let errorResponse = try? JSONDecoder().decode(
          APIResponse<String>.self,
          from: data
        ) {
          LKLog(
            "server error response url=\(request.url?.absoluteString ?? "unknown") status=\(httpResponse.statusCode) message=\(errorResponse.msg ?? "Unknown error")",
            type: "network",
            label: "warning"
          )
          throw BusinessError(
            message: errorResponse.msg ?? "Unknown error",
            code: errorResponse.ret,
            data: errorResponse.data
          )
        } else {
          LKLog(
            "http error response url=\(request.url?.absoluteString ?? "unknown") status=\(httpResponse.statusCode)",
            type: "network",
            label: "warning"
          )
          throw BusinessError(message: "HTTP \(httpResponse.statusCode)", code: httpResponse.statusCode, data: nil as Any?)
        }
      }

      // Step 9. 尝试解析成功响应
      let apiResponse = try JSONDecoder().decode(
        APIResponse<T>.self,
        from: data
      )
      LKLog(
        "api envelope url=\(request.url?.absoluteString ?? "unknown") ret=\(apiResponse.ret) msg=\(apiResponse.msg ?? "")",
        type: "network",
        label: "info"
      )

      if apiResponse.ret == 0, let data = apiResponse.data {
        return data
      } else if apiResponse.ret == 0 && T.self == Empty.self {
        return Empty() as! T
      } else if apiResponse.ret == 0 && T.self == Empty?.self {
        return Empty() as! T
        // TODO: 明天还需要向后台确认，这个ret = 62 来判断是否需要退出，是否合理
      } else if apiResponse.ret == 62 {
        await SelfStore.shared.logout(false)
        await MainActor.run {
          AppNavigationModel.shared.root = .login
        }
        throw BusinessError(message: "登录状态失效", code: 401, data: nil as Any?)
      } else {
        throw BusinessError(
          message: apiResponse.msg ?? "Req failed",
          code: apiResponse.ret,
          data: apiResponse.data as Any?
        )
      }
    } catch let error as URLError {
      LKLog(
        "network transport error url=\(request.url?.absoluteString ?? "unknown") code=\(error.errorCode) error=\(error.localizedDescription)",
        type: "network",
        label: "error"
      )
      throw BusinessError(message: "访问失败，请检查网络稍后再试", code: 400, data: nil as Any?)
    }
  }
}

struct AnyEncodable: Encodable {
  let value: Encodable

  init(_ value: Encodable) {
    self.value = value
  }

  func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
  }
}
