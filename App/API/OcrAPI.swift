import Foundation

final class OCRAPI {
  static let shared = OCRAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func vin(vinUrl: String) async -> OcrVinData? {
    // Step 1. 组装识别 VIN 请求参数
    let payload = AnyParams(["vinUrl": vinUrl])
    // Step 2. 发起识别 VIN 请求
    return await client.postRequest("/v4/u/ocr/vin", payload, true, true)
  }
}

// DONE-AI: 已对齐 flutter（data['data']['vin']）补全返回结构
struct OcrVinData: Decodable {
  let vin: String?
}
