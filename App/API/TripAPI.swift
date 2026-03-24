import Foundation

/// Payload structs
struct TripListPayload: Encodable {
  let imei: String
  let page: Int
  let limit: Int
}

struct TripStatisticalDataPayload: Encodable {
  let imei: String?

  init(imei: String? = nil) {
    self.imei = imei
  }
}

struct TripSetTravelTypePayload: Encodable {
  let travelId: String
  let type: Int
}

struct TripSetRankTypePayload: Encodable {
  let rankId: String
  let type: Int
}

struct TripShareUrlPayload: Encodable {
  let travelId: String
}

struct TripShareUrlData: Decodable {
  let url: String
}

enum TripAPIError: Error {
  case serverMessage(String)
  case missingData
}

extension TripAPIError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .serverMessage(message):
      return message
    case .missingData:
      return "数据缺失"
    }
  }
}

struct TripEmptyData: Decodable {
  init(from decoder: Decoder) throws {
    // Step 1. 兼容后端 data 字段任意类型
    let container = try decoder.singleValueContainer()
    if container.decodeNil() { return }
    if (try? container.decode(Bool.self)) != nil { return }
    if (try? container.decode(Int.self)) != nil { return }
    if (try? container.decode(Double.self)) != nil { return }
    if (try? container.decode(String.self)) != nil { return }
    if (try? container.decode([Empty].self)) != nil { return }
    if (try? container.decode([String: Empty].self)) != nil { return }
  }
}

struct ReGeoResponse: Decodable {
  let startAddr: String
  let endAddr: String

  private enum CodingKeys: String, CodingKey {
    case startAddr
    case endAddr
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    startAddr = container.safeDecodeString(.startAddr, "")
    endAddr = container.safeDecodeString(.endAddr, "")
  }
}

final class TripAPI {
  static let shared = TripAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func list(payload: TripListPayload) async -> [TripData]? {
    return await client.postRequest("/v4/u/travel/list", payload, true, false)
  }

  /// 这个是查询某一个设备的行程统计数据
  func statisticalData(_ imei: String) async -> TripStatisticalData? {
    return await client.postRequest("/v4/u/travel/statisticalData", AnyParams(["imei": imei]), true, false)
  }

  // 某个用户的行程统计数据（包含所有设备）,目前只有：totalTimes / totalMiles / totalTimeUsing 三个字段返回
  // func allStatisticalData() async -> UserTripStatistical? {
  //   return await client.postRequest("/v4/u/travel/allStatisticalData", Empty(), true, false)
  // }

  /// 翻译行程报告里面的位置信息
  func travelReGeo(_ id: String) async -> ReGeoResponse? {
    return await client.postRequest("/v4/u/travelReGeo", AnyParams(["id": id]), true, true)
  }

  func setTravelType(payload: TripSetTravelTypePayload) async -> Empty? {
    return await client.postRequest("/v4/u/trip/setTravelType", payload, true, true)
  }

  func setRankType(payload: TripSetRankTypePayload) async -> Empty? {
    return await client.postRequest("/v4/u/trip/setRankType", payload, true, true)
  }

  func deleteTrip(_ ids: [String]) async -> Empty? {
    guard !ids.isEmpty else { return nil }
    let payload = AnyParams(["ids": ids])
    return await client.postRequest("/v4/u/travel/deleteHistory", payload, true, true)
  }

  func getShareUrl(payload: TripShareUrlPayload) async -> TripShareUrlData? {
    return await client.postRequest("/v4/u/trip/shareUrl", payload, true, true)
  }
}
