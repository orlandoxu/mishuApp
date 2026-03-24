import Foundation

final class AlbumAPI {
  static let shared = AlbumAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  // // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  // func album() async throws -> AlbumData? {
  //   // Step 1. 组装相册首页请求参数
  //   let payload = Empty()
  //   // Step 2. 发起相册首页请求
  //   return try await client.request(.Post, "/v4/u/album", payload)
  // }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func carAlbumListV2() async -> AlbumCarAlbumListV2Data? {
    // Step 1. 组装车辆相册列表请求参数
    let payload = Empty()
    // Step 2. 发起车辆相册列表请求
    return await client.postRequest(
      "/v4/u/album/CarAlbumListV2", payload
    )
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func cloudCover(payload: AlbumCloudCoverPayload) async -> [AlbumCloudCoverItem]? {
    // Step 1. 组装云端封面请求参数
    // Step 2. 发起云端封面请求
    return await client.postRequest(
      "/v4/u/album/cloudCover", payload
    )
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func cloudDay(payload: AlbumCloudDayPayload) async -> [AlbumCloudDayItem]? {
    // Step 1. 组装云端日期列表请求参数
    // Step 2. 发起云端日期列表请求
    return await client.postRequest(
      "/v4/u/album/cloudDay", payload, true, false
    )
  }

  func dayCover(_ imei: String) async -> AlbumData? {
    return await client.postRequest(
      "/v4/u/album/dayCover", AnyParams(["imei": imei]), true, false
    )
  }

  func deleteResource(ids: [String]) async -> Empty? {
    return await client.postRequest("/v4/u/album/del", AnyParams(["id": ids]), true, true)
  }

  func deleteResourceById(_ id: String) async -> Empty? {
    await deleteResource(ids: [id])
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func detail(payload: AlbumYunPosesPayload) async -> [AlbumYunPosesItem]? {
    // Step 1. 组装相册详情请求参数
    // Step 2. 发起相册详情请求
    return await client.postRequest(
      "/v4/u/album/detail", payload, true, false
    )
  }

  func listV2(payload: AlbumListV2Payload) async -> [AlbumAsset]? {
    // Step 1. 组装相册列表 V2 请求参数
    // Step 2. 发起相册列表 V2 请求
    return await client.postRequest(
      "/v4/u/album/list", payload, true, true
    )
  }

  // DONE-AI: 已改为显式 payload 类型（对齐 flutter 请求字段）
  func updateCloudCover(payload: AlbumUpdateCloudCoverPayload) async -> Empty? {
    // Step 1. 组装更新云端封面请求参数
    // Step 2. 发起更新云端封面请求
    return await client.postRequest(
      "/v4/u/album/updateCloudCover", payload, true, false
    )
  }
}

// DONE-AI: 已对齐 flutter 相册相关返回结构，并移除空模型

private enum AlbumDecoding {
  static func decodePos<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> [Double]? {
    if let value = try? container.decodeIfPresent([Double].self, forKey: key) {
      return value
    }
    if let value = try? container.decodeIfPresent([Int].self, forKey: key) {
      return value.map { Double($0) }
    }
    return nil
  }
}

struct AlbumCloudCoverPayload: Encodable {
  let page: Int
  let limit: Int
}

struct AlbumCloudDayPayload: Encodable {
  let day: String
}

// struct AlbumDeletePayload: Encodable {
//   let ids: [String]

//   private enum CodingKeys: String, CodingKey {
//     case ids
//     case legacyIds = "_id"
//   }

//   func encode(to encoder: Encoder) throws {
//     var container = encoder.container(keyedBy: CodingKeys.self)
//     try container.encode(ids, forKey: .ids)
//     try container.encode(ids, forKey: .legacyIds)
//   }
// }

struct AlbumYunPosesPayload: Encodable {
  let id: String
}

struct AlbumListV2Payload: Encodable {
  let imei: String
  let limit: Int
  let page: Int
  let type: [Int]
}

struct AlbumUpdateCloudCoverPayload: Encodable {
  let day: String
}

struct AlbumData: Decodable {
  let liveHistory: AlbumCoverItem?
  let cloudRecord: AlbumCoverItem?
  let voicePhoto: AlbumCoverItem?
  let voiceVideo: AlbumCoverItem?
  let lockPhoto: AlbumCoverItem?
  let lockVideo: AlbumCoverItem?
  let realtimePhoto: AlbumCoverItem?
  let realtimeVideo: AlbumCoverItem?
  let parkPhoto: AlbumCoverItem?
  let parkVideo: AlbumCoverItem?
  let accOffPhoto: AlbumCoverItem?
  let accOffVideo: AlbumCoverItem?
  let sosPhoto: AlbumCoverItem?
  let sosVideo: AlbumCoverItem?
  let lockPhotoBanma: AlbumCoverItem?
  let lockVideoBanma: AlbumCoverItem?
  let accOffPhotoBanma: AlbumCoverItem?
  let accOffVideoBanma: AlbumCoverItem?
  let keyPressCaptureVideo: AlbumCoverItem?
  let keyPressCapturePhoto: AlbumCoverItem?

  private enum CodingKeys: String, CodingKey {
    case liveHistory
    case cloudRecord
    case voicePhoto
    case voiceVideo
    case lockPhoto
    case lockVideo
    case realtimePhoto
    case realtimeVideo
    case parkPhoto
    case parkVideo
    case accOffPhoto
    case accOffVideo
    case sosPhoto
    case sosVideo
    case lockPhotoBanma
    case lockVideoBanma
    case accOffPhotoBanma
    case accOffVideoBanma
    case keyPressCaptureVideo
    case keyPressCapturePhoto
  }
}

struct AlbumCoverItem: Decodable {
  let count: Int?

  private enum CodingKeys: String, CodingKey {
    case count
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    count = container.safeDecodeInt(.count, 0)
  }
}

struct AlbumCarAlbumListV2Data: Decodable {
  let data: AlbumCarAlbumListV2InnerData?
}

struct AlbumCarAlbumListV2InnerData: Decodable {
  let parkingAlarmList: [AlbumDetailItem]?
  let cardAlarmList: [AlbumDetailItem]?
  let collisionAlarmList: [AlbumDetailItem]?
  let parkingList: [AlbumStopCarItem]?

  private enum CodingKeys: String, CodingKey {
    case parkingAlarmList = "parking_alarm_list"
    case cardAlarmList = "card_alarm_list"
    case collisionAlarmList = "collision_alarm_list"
    case parkingList = "parking_list"
  }
}

struct AlbumCloudCoverItem: Decodable {
  let id: String?
  let cover: String?
  let num: Int?
  let location: String?
  let cycleStart: String?
  let cycleEnd: String?

  private enum CodingKeys: String, CodingKey {
    case id = "_id"
    case cover
    case num
    case location
    case cycleStart = "cycle_start"
    case cycleEnd = "cycle_end"
  }
}

struct AlbumCloudDayItem: Decodable {
  let pos: [Double]?
  let realBanma: Int?
  let uploadSpeed: Int?
  let id: String?
  let taskId: String?
  let url: String?
  let urlThumb: String?
  let camera: Int?
  let type: Int?
  let mtype: Int?
  let createTime: String?
  let location: String?
  let cloudDisk: Int?
  let cameraTemplate: String?
  let authTravelManage: Int?

  private enum CodingKeys: String, CodingKey {
    case pos
    case realBanma = "real_banma"
    case uploadSpeed
    case id = "_id"
    case taskId = "task_id"
    case url
    case urlThumb = "url_thumb"
    case camera
    case type
    case mtype
    case createTime = "create_time"
    case location
    case cloudDisk = "cloud_disk"
    case cameraTemplate
    case authTravelManage = "auth_travel_manage"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pos = AlbumDecoding.decodePos(container, key: .pos)
    realBanma = try? container.decodeIfPresent(Int.self, forKey: .realBanma)
    uploadSpeed = try? container.decodeIfPresent(Int.self, forKey: .uploadSpeed)
    id = try? container.decodeIfPresent(String.self, forKey: .id)
    taskId = try? container.decodeIfPresent(String.self, forKey: .taskId)
    url = try? container.decodeIfPresent(String.self, forKey: .url)
    urlThumb = try? container.decodeIfPresent(String.self, forKey: .urlThumb)
    camera = try? container.decodeIfPresent(Int.self, forKey: .camera)
    type = try? container.decodeIfPresent(Int.self, forKey: .type)
    mtype = try? container.decodeIfPresent(Int.self, forKey: .mtype)
    createTime = try? container.decodeIfPresent(String.self, forKey: .createTime)
    location = try? container.decodeIfPresent(String.self, forKey: .location)
    cloudDisk = try? container.decodeIfPresent(Int.self, forKey: .cloudDisk)
    cameraTemplate = try? container.decodeIfPresent(String.self, forKey: .cameraTemplate)
    authTravelManage = try? container.decodeIfPresent(Int.self, forKey: .authTravelManage)
  }
}

struct AlbumYunPosesItem: Decodable {
  let pos: [Double]?
  let status: Int?
  let realBanma: Int?
  let uploadSpeed: Int?
  let taskId: String?
  let imei: String?
  let url: String?
  let urlThumb: String?
  let camera: Int?
  let type: Int?
  let mtype: Int?
  let createTime: String?
  let location: String?
  let poses: String?
  let cloudDisk: Int?
  let cid: String?

  private enum CodingKeys: String, CodingKey {
    case pos
    case status
    case realBanma = "real_banma"
    case uploadSpeed
    case taskId = "task_id"
    case imei
    case url
    case urlThumb = "url_thumb"
    case camera
    case type
    case mtype
    case createTime = "create_time"
    case location
    case poses
    case cloudDisk = "cloud_disk"
    case cid
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    pos = AlbumDecoding.decodePos(container, key: .pos)
    status = try? container.decodeIfPresent(Int.self, forKey: .status)
    realBanma = try? container.decodeIfPresent(Int.self, forKey: .realBanma)
    uploadSpeed = try? container.decodeIfPresent(Int.self, forKey: .uploadSpeed)
    taskId = try? container.decodeIfPresent(String.self, forKey: .taskId)
    imei = try? container.decodeIfPresent(String.self, forKey: .imei)
    url = try? container.decodeIfPresent(String.self, forKey: .url)
    urlThumb = try? container.decodeIfPresent(String.self, forKey: .urlThumb)
    camera = try? container.decodeIfPresent(Int.self, forKey: .camera)
    type = try? container.decodeIfPresent(Int.self, forKey: .type)
    mtype = try? container.decodeIfPresent(Int.self, forKey: .mtype)
    createTime = try? container.decodeIfPresent(String.self, forKey: .createTime)
    location = try? container.decodeIfPresent(String.self, forKey: .location)
    poses = try? container.decodeIfPresent(String.self, forKey: .poses)
    cloudDisk = try? container.decodeIfPresent(Int.self, forKey: .cloudDisk)
    cid = try? container.decodeIfPresent(String.self, forKey: .cid)
  }
}

struct AlbumListV2Data: Decodable {
  let current: Int?
  let number: Int?
  let total: Int?
  let data: [AlbumDetailItem]?
}

struct AlbumDetailItem: Decodable {
  let id: String?
  let pos: [Double]?
  let uploadSpeed: Int?
  let taskId: String?
  let imei: String?
  let mobile: String?
  let url: String?
  let urlThumb: String?
  let camera: Int?
  let type: Int?
  let albumType: Int?
  let mtype: Int?
  let createTime: String?
  let location: String?
  let cloudDisk: Int?
  let cameraTemplate: String?
  let poses: String?
  let authTravelManage: Int?
  let authRemoteService: Int?
  let dayIndex: Int?

  private enum CodingKeys: String, CodingKey {
    case id = "_id"
    case pos
    case uploadSpeed
    case taskId = "task_id"
    case imei
    case mobile
    case url
    case urlThumb = "url_thumb"
    case camera
    case type
    case albumType = "album_type"
    case mtype
    case createTime = "create_time"
    case location
    case cloudDisk = "cloud_disk"
    case cameraTemplate
    case poses
    case authTravelManage = "auth_travel_manage"
    case authRemoteService = "auth_remote_service"
    case dayIndex
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try? container.decodeIfPresent(String.self, forKey: .id)
    pos = AlbumDecoding.decodePos(container, key: .pos)
    uploadSpeed = try? container.decodeIfPresent(Int.self, forKey: .uploadSpeed)
    taskId = try? container.decodeIfPresent(String.self, forKey: .taskId)
    imei = try? container.decodeIfPresent(String.self, forKey: .imei)
    mobile = try? container.decodeIfPresent(String.self, forKey: .mobile)
    url = try? container.decodeIfPresent(String.self, forKey: .url)
    urlThumb = try? container.decodeIfPresent(String.self, forKey: .urlThumb)
    camera = try? container.decodeIfPresent(Int.self, forKey: .camera)
    type = try? container.decodeIfPresent(Int.self, forKey: .type)
    albumType = try? container.decodeIfPresent(Int.self, forKey: .albumType)
    mtype = try? container.decodeIfPresent(Int.self, forKey: .mtype)
    createTime = try? container.decodeIfPresent(String.self, forKey: .createTime)
    location = try? container.decodeIfPresent(String.self, forKey: .location)
    cloudDisk = try? container.decodeIfPresent(Int.self, forKey: .cloudDisk)
    cameraTemplate = try? container.decodeIfPresent(String.self, forKey: .cameraTemplate)
    poses = try? container.decodeIfPresent(String.self, forKey: .poses)
    authTravelManage = try? container.decodeIfPresent(Int.self, forKey: .authTravelManage)
    authRemoteService = try? container.decodeIfPresent(Int.self, forKey: .authRemoteService)
    dayIndex = try? container.decodeIfPresent(Int.self, forKey: .dayIndex)
  }
}

struct AlbumStopCarItem: Decodable {
  let id: String?
  let attach: [String: String]?
  let pos: [Double]?
  let realBanma: Int?
  let uploadSpeed: Int?
  let triggerTime: String?
  let taskId: String?
  let imei: String?
  let mobile: String?
  let url: String?
  let urlThumb: String?
  let camera: Int?
  let type: Int?
  let albumType: Int?
  let mtype: Int?
  let createTime: String?
  let location: String?
  let cloudDisk: Int?
  let cid: String?
  let cameraTemplate: String?
  let authTravelManage: Int?
  let authRemoteService: Int?

  private enum CodingKeys: String, CodingKey {
    case id = "_id"
    case attach
    case pos
    case realBanma = "real_banma"
    case uploadSpeed
    case triggerTime = "trigger_time"
    case taskId = "task_id"
    case imei
    case mobile
    case url
    case urlThumb = "url_thumb"
    case camera
    case type
    case albumType = "album_type"
    case mtype
    case createTime = "create_time"
    case location
    case cloudDisk = "cloud_disk"
    case cid
    case cameraTemplate
    case authTravelManage = "auth_travel_manage"
    case authRemoteService = "auth_remote_service"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try? container.decodeIfPresent(String.self, forKey: .id)
    attach = try? container.decodeIfPresent([String: String].self, forKey: .attach)
    pos = AlbumDecoding.decodePos(container, key: .pos)
    realBanma = try? container.decodeIfPresent(Int.self, forKey: .realBanma)
    uploadSpeed = try? container.decodeIfPresent(Int.self, forKey: .uploadSpeed)
    triggerTime = try? container.decodeIfPresent(String.self, forKey: .triggerTime)
    taskId = try? container.decodeIfPresent(String.self, forKey: .taskId)
    imei = try? container.decodeIfPresent(String.self, forKey: .imei)
    mobile = try? container.decodeIfPresent(String.self, forKey: .mobile)
    url = try? container.decodeIfPresent(String.self, forKey: .url)
    urlThumb = try? container.decodeIfPresent(String.self, forKey: .urlThumb)
    camera = try? container.decodeIfPresent(Int.self, forKey: .camera)
    type = try? container.decodeIfPresent(Int.self, forKey: .type)
    albumType = try? container.decodeIfPresent(Int.self, forKey: .albumType)
    mtype = try? container.decodeIfPresent(Int.self, forKey: .mtype)
    createTime = try? container.decodeIfPresent(String.self, forKey: .createTime)
    location = try? container.decodeIfPresent(String.self, forKey: .location)
    cloudDisk = try? container.decodeIfPresent(Int.self, forKey: .cloudDisk)
    cid = try? container.decodeIfPresent(String.self, forKey: .cid)
    cameraTemplate = try? container.decodeIfPresent(String.self, forKey: .cameraTemplate)
    authTravelManage = try? container.decodeIfPresent(Int.self, forKey: .authTravelManage)
    authRemoteService = try? container.decodeIfPresent(Int.self, forKey: .authRemoteService)
  }
}
