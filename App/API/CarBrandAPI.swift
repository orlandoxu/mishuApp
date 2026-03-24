import Foundation

final class CarBrandAPI {
  static let shared = CarBrandAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getCarSeriesInfoByVin(vin: String, newImei: String? = nil, newSn: String? = nil) async
    -> CarSeriesModel?
  {
    // Step 1. 组装 VIN 车系请求参数
    struct Payload: Encodable {
      let vin: String
      let newImei: String?
      let newSn: String?
    }
    let payload = Payload(vin: vin, newImei: newImei, newSn: newSn)
    // Step 2. 发起 VIN 车系请求
    return await client.postRequest(
      "/v4/u/carBrand/GetCarSeriesInfoByVin", payload, true, true
    )
  }

  func allBrand() async -> [CarBrandModel]? {
    // Step 1. 组装品牌列表请求参数
    // Step 2. 发起品牌列表请求
    return await client.postRequest("/v4/u/carBrand/allBrand", Empty(), true, true)
  }

  func searchByBrandType(brandId: Int) async -> [CarSeriesModel]? {
    return await client.postRequest(
      "/v4/u/carBrand/searchBrandType", AnyParams(["brandId": brandId]), true, true
    )
  }
}
