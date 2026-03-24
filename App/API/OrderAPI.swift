import Foundation

// DONE-AI: 已改为强类型返回

final class OrderAPI {
  static let shared = OrderAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func create(payload: OrderCreatePayload) async -> WechatPayParamsData? {
    return await client.postRequest(
      "/v4/u/order/create", payload, true, true
    )
  }

  func getAppOrderList() async -> [OrderModel]? {
    return await client.postRequest(
      "/v4/u/order/getAppOrderList", AnyParams(["limit": 200, "page": 1]), true, false
    )
  }

  // // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  // func orderEffective(payload: OrderEffectivePayload) async throws -> Empty? {
  //   try await client.request(
  //     .Post, "/v4/u/order/orderEffective", payload
  //   )
  // }
}

struct OrderCreatePayload: Encodable {
  let mobile: String
  let packageId: String
  let payType: String
  let appid: String
  let merchantName: String
  let imei: String
  let appPlatform: String
  let appVersion: String
  let test: Bool?

  init(
    mobile: String,
    packageId: String,
    payType: String = "app",
    appid: String,
    merchantName: String = "TuYunHuLian",
    imei: String,
    appPlatform: String = "ios",
    appVersion: String = OrderCreatePayload.resolveAppVersion(),
    test: Bool? = nil
  ) {
    self.mobile = mobile
    self.packageId = packageId
    self.payType = payType
    self.appid = appid
    self.merchantName = merchantName
    self.imei = imei
    self.appPlatform = appPlatform
    self.appVersion = appVersion
    self.test = test
  }

  private static func resolveAppVersion() -> String {
    if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
      return value
    }
    return ""
  }
}

struct OrderEffectivePayload: Encodable {
  let orderId: String
  let imei: String?
}
