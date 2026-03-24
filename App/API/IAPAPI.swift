import Foundation

final class IAPAPI {
  static let shared = IAPAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func buy(payload: IAPBuyPayload) async -> IAPBuyData? {
    // Step 1. 组装内购回执请求参数
    // Step 2. 发起内购回执请求
    return await client.postRequest("/v4/u/iap/buy", payload, true, true)
  }
}

struct IAPBuyPayload: Encodable {
  let originalTransactionId: String
  let transactionId: String
  let purchaseDate: Int64
  let packageId: String
  let imei: String?
  let environment: String
  let appPlatform: String
  let appVersion: String
}

struct IAPBuyData: Decodable {}
