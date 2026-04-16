
import Foundation

enum AppEnvironment: String, CaseIterable, Identifiable {
  case production
  case testing

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .production:
      return "生产环境"
    case .testing:
      return "测试环境"
    }
  }
}

/// 定义一个常量数据结构，包含客服的URL
enum AppConst {
  static let environmentKey = "mishu_environment"
  static let environmentUserSelectedKey = "mishu_environment_user_selected"

  /// iOS 包环境标识：`true` 表示 Debug 包，`false` 表示 Release 包。
  static var iosIsDebug: Bool {
    #if DEBUG
      true
    #else
      false
    #endif
  }

  static let weChatServiceToken = "9XYGTGWtq2xveMrMZdJg4Hv7RiYC4AbwmDiQlhwGvBhWMCX4k_gt_1MsKCdTqBMM-zXaTHF178EAZpVV9-7nhseZaD0NI5-1"

  static var apiBaseURLProd: URL {
    URL(string: "https://api.landeng.fun")!
  }

  static var currentEnvironment: AppEnvironment {
    let hasUserSelected = UserDefaults.standard.bool(forKey: environmentUserSelectedKey)
    if !hasUserSelected { return .testing }
    let raw = UserDefaults.standard.string(forKey: environmentKey) ?? ""
    return AppEnvironment(rawValue: raw) ?? .testing
  }

  static func setEnvironment(_ environment: AppEnvironment) {
    UserDefaults.standard.set(environment.rawValue, forKey: environmentKey)
    UserDefaults.standard.set(true, forKey: environmentUserSelectedKey)
  }

  static var apiBaseURL: URL {
    switch currentEnvironment {
    case .production:
      return apiBaseURLProd
    case .testing:
      return apiBaseURLProd
    }
  }

  /// WebSocket 地址（按环境切换）
  static var appWebSocketURL: URL {
    switch currentEnvironment {
    case .production:
      return URL(string: "wss://api.landeng.fun/house")!
    case .testing:
      return URL(string: "wss://api.landeng.fun/local/house")!
    }
  }

  static var wechatAppId: String {
    Bundle.main.object(forInfoDictionaryKey: "WeChatAppID") as? String ?? ""
  }

  static var wechatUniversalLink: String {
    Bundle.main.object(forInfoDictionaryKey: "WeChatUniversalLink") as? String ?? ""
  }

  static var umengAppKey: String {
    Bundle.main.object(forInfoDictionaryKey: "UMengAppKey") as? String ?? ""
  }

  static var umengChannel: String {
    Bundle.main.object(forInfoDictionaryKey: "UMengChannel") as? String ?? "App Store"
  }

  static var umengLogEnabled: Bool {
    Bundle.main.object(forInfoDictionaryKey: "UMengLogEnabled") as? Bool ?? false
  }

  // 火山（豆包）实时语音识别配置
  static let volcSpeechAppID = "6627245859"
  static let volcSpeechAccessKey = "894c4c83-6c8f-4b3b-8154-79b9fc97d545"
  static let volcSpeechSecretKey = "TmGjtW8Zciu6b36nRHKiRJjix43Q0aJR"
  static let volcSpeechResourceID = "volc.seedasr.sauc.duration"
  static let volcSpeechServerURL = "wss://openspeech.bytedance.com/api/v3/sauc/bigmodel_async"

  // Doubao Embedding（火山方舟）配置
  // 支持通过 UserDefaults 动态覆盖，便于真机调试时快速切换。
  static var doubaoEmbeddingApiKey: String {
    let override = UserDefaults.standard.string(forKey: "mishu_doubao_embedding_api_key") ?? ""
    if !override.isEmpty { return override }
    // 用户要求：先将 key 直接放到 Const.swift 里，后续可再迁移到更安全方案。
    let inline = "82831d8d-ac01-4049-a4bf-d4b4eeb0d63e"
    if !inline.isEmpty { return inline }
    return Bundle.main.object(forInfoDictionaryKey: "DoubaoEmbeddingAPIKey") as? String ?? ""
  }

  static var doubaoEmbeddingBaseURL: String {
    let override = UserDefaults.standard.string(forKey: "mishu_doubao_embedding_base_url") ?? ""
    if !override.isEmpty { return override }
    return Bundle.main.object(forInfoDictionaryKey: "DoubaoEmbeddingBaseURL") as? String
      ?? "https://ark.cn-beijing.volces.com/api/v3"
  }

  static var doubaoEmbeddingModel: String {
    let override = UserDefaults.standard.string(forKey: "mishu_doubao_embedding_model") ?? ""
    if !override.isEmpty { return override }
    return Bundle.main.object(forInfoDictionaryKey: "DoubaoEmbeddingModel") as? String ?? "text-240715"
  }

  static var doubaoEmbeddingDimension: Int {
    let override = UserDefaults.standard.integer(forKey: "mishu_doubao_embedding_dimension")
    if override > 0 { return override }
    let infoValue = Bundle.main.object(forInfoDictionaryKey: "DoubaoEmbeddingDimension") as? Int
    return infoValue ?? 2048
  }

  // 业务后端落库接口（服务端负责真正写 MySQL）
  static var memoryIngestEndpoint: String {
    let override = UserDefaults.standard.string(forKey: "mishu_memory_ingest_endpoint") ?? ""
    if !override.isEmpty { return override }
    return Bundle.main.object(forInfoDictionaryKey: "MemoryIngestEndpoint") as? String
      ?? "/v1/ai/memory/ingest"
  }

  static var doubaoChatBaseURL: String {
    let override = UserDefaults.standard.string(forKey: "mishu_doubao_chat_base_url") ?? ""
    if !override.isEmpty { return override }
    return Bundle.main.object(forInfoDictionaryKey: "DoubaoChatBaseURL") as? String
      ?? "https://ark.cn-beijing.volces.com/api/v3"
  }

  static var doubaoChatModel: String {
    let override = UserDefaults.standard.string(forKey: "mishu_doubao_chat_model") ?? ""
    if !override.isEmpty { return override }
    return Bundle.main.object(forInfoDictionaryKey: "DoubaoChatModel") as? String
      ?? "doubao-seed-2-0-lite"
  }

  /// static let gaoDeKey = "ffe3d26208fb8adb73ce6ff5c76f4462"
  static let gaoDeKey = "6a62c0d860ebc2050b23bf5055ab5431"

  @MainActor
  static var weChatServiceURL: String {
    buildWeChatServiceURL(userId: SelfStore.shared.selfUser?.userId, nickName: SelfStore.shared.selfUser?.nickname)
  }

  static func buildWeChatServiceURL(userId: String?, nickName: String?) -> String {
    var components = URLComponents(string: "https://ccc-v2.aliyun.com/v-chat")
    components?.queryItems = [
      URLQueryItem(name: "token", value: weChatServiceToken),
      URLQueryItem(name: "userId", value: userId ?? ""),
      URLQueryItem(name: "nickName", value: nickName ?? ""),
    ]
    return components?.url?.absoluteString ?? "https://ccc-v2.aliyun.com/v-chat?token=\(weChatServiceToken)&userId="
  }

  static var isHans: Bool {
    let preferred = Locale.preferredLanguages.first ?? ""
    return preferred.contains("Hans") || preferred.contains("zh-Hans") || preferred.contains("zh-CN")
  }

  static var userAgreementUrl: String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/luke/UserTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/luke/UserTerm_HK.html"
  }

  static var privacyPolicyUrl: String {
    isHans
      ? "https://wx-server.spreadwin.com/services/frontpage/html/luke/PrivateTerm.html"
      : "https://wx-server.spreadwin.com/services/frontpage/html/luke/PrivateTerm_HK.html"
  }
}
