import Foundation

final class ConfigAPI {
  static let shared = ConfigAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getConfig() async -> AppConfigModel? {
    // Step 1. 组装配置请求参数
    let payload = Empty()
    // Step 2. 发起配置请求
    return await client.postRequest("/v4/u/config", payload, true, false)
  }
}

// DONE-AI: 返回值字段补齐
// "gaodeKey": "ffe3d26208fb8adb73ce6ff5c76f4462"    // 高德key
// "hotLine": bool     // 是否展示服务热线
// "liveType" : string // qiniu-七牛 ali-阿里    直播
// "tcardType" : string // qiniu-七牛 ali-阿里    T卡
struct AppConfigModel: Decodable {
  let gaodeKey: String?
  let hotLine: Bool?
  let liveType: String?
  let tcardType: String?
}
