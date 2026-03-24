import Foundation

struct UploadTokenData: Decodable {
  let token: String
  let url: String
  let baseUrl: String
  let endPoint: String
}

struct DeviceResource: Decodable {
  let resType: String // 资源类型：spaceCycle/time/live/device/sim/obdCar/space
  // spaceCycle 云存储循环时长
  // time-云记录时间
  // live-远程直播时间
  // device-设备服务（车联服务，基础服务）
  // sim-免流套餐
  // obdCar-爱车守护
  // space 云存储容量（目前我们app没有这个资源）
  let total: Int64 // Total 资源总量
  let used: Int64 // 已使用量
  let left: Int64 // 剩余量
  let startTime: Int64 // 开始时间（毫秒时间戳）
  let endTime: Int64 // 结束时间（毫秒时间戳）
  let effectiveStatus: Int64 // 1-生效中, 2-已失效, 3-未生效

  private enum CodingKeys: String, CodingKey {
    case resType
    case type
    case total
    case used
    case left
    case startTime
    case endTime
    case effectiveStatus
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let safeResType = container.safeDecodeString(.resType, "")
    resType = safeResType.isEmpty ? container.safeDecodeString(.type, "") : safeResType
    total = container.safeDecodeInt64(.total, 0)
    used = container.safeDecodeInt64(.used, 0)
    left = container.safeDecodeInt64(.left, 0)
    startTime = container.safeDecodeInt64(.startTime, 0)
    endTime = container.safeDecodeInt64(.endTime, 0)
    effectiveStatus = container.safeDecodeInt64(.effectiveStatus, 0)
  }
}

struct SpacingResUsing: Decodable {
  let date: String // 日期
  let fileCount: Int // 文件数量
  let totalSize: Int64 // 文件总大小，单位字节
}

struct DeviceResourceListData: Decodable {
  let imei: String
  let resources: [DeviceResource]

  private enum CodingKeys: String, CodingKey {
    case imei
    case resources
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    imei = container.safeDecodeString(.imei, "")
    resources = container.safeDecodeArray(.resources, [])
  }
}

final class ResourceAPI {
  static let shared = ResourceAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func checkPlay(commandId: String) async -> ResourceCheckPlayData? {
    let payload = AnyParams(["commandId": commandId])
    return await client.postRequest(
      "/v4/u/resource/checkPlay", payload, true, true
    )
  }

  /// 获取T卡视频的轨迹文件
  func getKml(payload: Empty = Empty()) async -> ResourceKmlData? {
    return await client.postRequest(
      "/v4/u/resource/getKml", payload, true, true
    )
  }

  func getTCard(payload: Empty = Empty()) async -> ResourceTCardData? {
    return await client.postRequest(
      "/v4/u/resource/getTCard", payload, true, true
    )
  }

  /// 获取vin的token，因为接口表复杂，我们的应用场景简单，直接用固定值
  func getVinSignToken() async -> UploadTokenData? {
    return await client.postRequest(
      "/v4/u/resource/getUploadTokenByUser",
      AnyParams(["type": "jpg", "channel": "vin"]), true, true
    )
  }

  func getAvatarToken() async -> UploadTokenData? {
    return await client.postRequest(
      "/v4/u/resource/getUploadTokenByUser",
      AnyParams(["type": "jpg", "channel": "avatar"]), true, true
    )
  }

  func getLogUploadToken() async -> UploadTokenData? {
    return await client.postRequest(
      "/v4/u/resource/getUploadTokenByUser",
      AnyParams(["type": "log", "channel": "obdLog"]), true, true
    )
  }

  func playCard(payload: Empty = Empty()) async -> Empty? {
    return await client.postRequest(
      "/v4/u/resource/playCard", payload, true, true
    )
  }

  func stopPlay(payload: Empty = Empty()) async -> Empty? {
    return await client.postRequest(
      "/v4/u/resource/stopPlay", payload, true, true
    )
  }

  func getDeviceResource(imei: String) async -> [DeviceResource]? {
    let payload = AnyParams(["imei": imei])
    let response: DeviceResourceListData? = await client.postRequest(
      "/v4/u/order/getDeviceEffectiveResources", payload, true, true
    )
    return response?.resources
  }

  func getSpaceUsage(imei: String, startTime: String, endTime: String) async -> [SpacingResUsing]? {
    let payload = AnyParams(["imei": imei, "startDate": startTime, "endDate": endTime])
    return await client.postRequest(
      "/v4/u/user/getSpaceUsage", payload, true, true
    )
  }
}

struct ResourceCheckPlayData: Decodable {
  let canPlay: Bool?
  let status: Int?
  let message: String?
}

struct ResourceKmlData: Decodable {
  let url: String?
  let kmlUrl: String?
}

struct ResourceTCardData: Decodable {
  let id: String?
  let url: String?
}
