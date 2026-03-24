import Foundation

// DONE-AI: 已改为强类型返回

final class PayAPI {
  static let shared = PayAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func getPayType(payload: PayGetPayTypePayload = PayGetPayTypePayload()) async
    -> PayTypeData?
  {
    return await client.postRequest(
      "/v4/u/getPayType", payload, true, false
    )
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func getWechatPayParams(payload: PayGetWechatPayParamsPayload) async
    -> WechatPayParamsData?
  {
    return await client.postRequest(
      "/v4/u/getWechatPayParams", payload, true, true
    )
  }
}

struct PayGetPayTypePayload: Encodable {
  init() {}
}

struct PayGetWechatPayParamsPayload: Encodable {
  let orderId: String
}

struct PayTypeData: Decodable {
  let payType: Int?
  let type: Int?
}

// DONE-AI: 已改为强类型返回，直接按后端返回解析
struct WechatPayParamsData: Decodable {
  let appId: String
  let partnerId: String
  let prepayId: String
  let nonceStr: String
  let timeStamp: UInt32
  let package: String
  let signType: String
  let sign: String
  let orderId: String

  private enum CodingKeys: String, CodingKey {
    case appId
    case partnerId = "partnerid"
    case prepayId = "prepayid"
    case nonceStr
    case timeStamp
    case package
    case signType
    case sign
    case orderId
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    appId = try container.decode(String.self, forKey: .appId)
    partnerId = try container.decode(String.self, forKey: .partnerId)
    prepayId = try container.decode(String.self, forKey: .prepayId)
    nonceStr = try container.decode(String.self, forKey: .nonceStr)
    package = try container.decode(String.self, forKey: .package)
    signType = try container.decode(String.self, forKey: .signType)
    sign = try container.decode(String.self, forKey: .sign)
    orderId = try container.decode(String.self, forKey: .orderId)

    if let value = try? container.decode(String.self, forKey: .timeStamp),
       let parsed = UInt32(value)
    {
      timeStamp = parsed
    } else if let value = try? container.decode(Int.self, forKey: .timeStamp) {
      timeStamp = UInt32(value)
    } else if let value = try? container.decode(Int64.self, forKey: .timeStamp) {
      timeStamp = UInt32(value)
    } else {
      throw DecodingError.dataCorruptedError(
        forKey: .timeStamp,
        in: container,
        debugDescription: "Invalid timeStamp value"
      )
    }
  }
}
