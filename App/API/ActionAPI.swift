import Foundation

final class ActionAPI {
  static let shared = ActionAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func checkoutLive(commandId: String) async -> ActionStatusData? {
    // Step 1. 组装退出直播请求参数
    struct Payload: Encodable {
      let commandId: String
    }
    let payload = Payload(commandId: commandId)
    // Step 2. 发起退出直播请求
    return await client.postRequest(
      "/v4/u/action/checkoutLive", payload, true, true
    )
  }

  func getInfo() async -> ActionLiveInfoData? {
    // Step 1. 组装直播信息请求参数
    let payload = Empty()
    // Step 2. 发起直播信息请求
    return await client.postRequest(
      "/v4/u/action/getInfo", payload, true, false
    )
  }

  func getLiveId(
    camera: Int,
    aRtc: Bool,
    aliRtmp: Bool,
    webRtc: Bool,
    qiniuRtmp: Bool
  ) async -> ActionLiveIdData? {
    // Step 1. 组装获取直播 ID 请求参数
    struct Payload: Encodable {
      let camera: Int
      let aRtc: Bool
      let aliRtmp: Bool
      let webRtc: Bool
      let qiniuRtmp: Bool
    }
    let payload = Payload(
      camera: camera,
      aRtc: aRtc,
      aliRtmp: aliRtmp,
      webRtc: webRtc,
      qiniuRtmp: qiniuRtmp
    )
    // Step 2. 发起获取直播 ID 请求
    return await client.postRequest(
      "/v4/u/action/getLiveId", payload, true, false
    )
  }

  func getLiveTimeAndPackage() async -> ActionLiveTimePackageData? {
    // Step 1. 组装直播时长套餐请求参数
    let payload = Empty()
    // Step 2. 发起直播时长套餐请求
    return await client.postRequest(
      "/v4/u/action/getLiveTimeAndPackage", payload, true, false
    )
  }

  func getLiveUrl(commandId: String, proto: String) async -> ActionLiveUrlData? {
    // Step 1. 组装获取直播地址请求参数
    struct Payload: Encodable {
      let commandId: String
      let `protocol`: String
    }
    let payload = Payload(commandId: commandId, protocol: proto)
    // Step 2. 发起获取直播地址请求
    return await client.postRequest(
      "/v4/u/action/getLiveUrl", payload, true, false
    )
  }

  func getTCardCover(files: [String]) async -> ActionTCardCoverData? {
    // Step 1. 组装 T 卡封面请求参数
    struct Payload: Encodable {
      let files: [String]
    }
    let payload = Payload(files: files)
    // Step 2. 发起 T 卡封面请求
    return await client.postRequest(
      "/v4/u/action/getTCardCover", payload, true, false
    )
  }

  func getTCardCoverFiles() async -> ActionTCardCoverFilesData? {
    // Step 1. 组装 T 卡封面文件列表请求参数
    let payload = Empty()
    // Step 2. 发起 T 卡封面文件列表请求
    return await client.postRequest(
      "/v4/u/action/getTCardCoverFiles", payload, true, false
    )
  }

  func parkToSecurity() async -> ActionStatusData? {
    // Step 1. 组装驻车设防请求参数
    let payload = Empty()
    // Step 2. 发起驻车设防请求
    return await client.postRequest(
      "/v4/u/action/parkToSecurity", payload, true, true
    )
  }

  func queryLightStateQuery() async -> ActionLightStateData? {
    // Step 1. 组装查询灯光状态请求参数
    struct Payload: Encodable {
      let on_state: String
      let off_state: String
    }
    let payload = Payload(on_state: "query", off_state: "query")
    // Step 2. 发起查询灯光状态请求
    return await client.postRequest(
      "/v4/u/action/queryLightState", payload, true, false
    )
  }

  func queryLightStateSet(isLight: Bool) async -> ActionLightStateData? {
    // Step 1. 组装设置灯光状态请求参数
    struct Payload: Encodable {
      let on_state: String
      let off_state: String
    }
    let state = isLight ? "on" : "off"
    let payload = Payload(on_state: state, off_state: state)
    // Step 2. 发起设置灯光状态请求
    return await client.postRequest(
      "/v4/u/action/queryLightState", payload, true, true
    )
  }

  func realTimePhoto(imei: String, camera: Int, mode: String = "normal") async -> [ActionMediaItem]? {
    // Step 1. 组装实时拍照请求参数
    struct Payload: Encodable {
      let imei: String
      let camera: Int
      let mode: String // normal: 普通拍照，eagle: 鹰眼拍照
    }
      let payload = Payload(imei: imei, camera: camera, mode: mode)
    // Step 2. 发起实时拍照请求
    return await client.postRequest(
      "/v4/u/action/realTimePhoto", payload, true, true
    )
  }

  func realTimeVideo(imei: String, camera: Int, duration: Int = 15) async -> [ActionMediaItem]? {
    // Step 1. 组装实时录像请求参数
    struct Payload: Encodable {
      let imei: String
      let camera: Int
      let duration: Int
    }
    let payload = Payload(imei: imei, camera: camera, duration: duration)
    // Step 2. 发起实时录像请求
    return await client.postRequest(
      "/v4/u/action/realTimeVideo", payload, true, true
    )
  }

  func stopLive(camera: Int, commandId: String) async -> ActionStatusData? {
    // Step 1. 组装停止直播请求参数
    struct Payload: Encodable {
      let camera: Int
      let commandId: String
    }
    let payload = Payload(camera: camera, commandId: commandId)
    // Step 2. 发起停止直播请求
    return await client.postRequest(
      "/v4/u/action/stopLive", payload, true, true
    )
  }

  func weakUpDvr(duration: Int = 60) async -> ActionStatusData? {
    // Step 1. 组装唤醒设备请求参数
    struct Payload: Encodable {
      let duration: Int
    }
    let payload = Payload(duration: duration)
    // Step 2. 发起唤醒设备请求
    return await client.postRequest(
      "/v4/u/action/weakUpDvr", payload, true, true
    )
  }
}

struct ActionStatusData: Decodable {
  let success: Bool?
  let status: Int?
  let message: String?
}

struct ActionLiveInfoData: Decodable {
  let liveId: String?
  let status: Int?
  let startTime: String?
  let endTime: String?
}

struct ActionLiveIdData: Decodable {
  let liveId: String?
  let id: String?
}

struct ActionLiveTimePackageData: Decodable {
  let liveTime: Int?
  let packageId: String?
}

struct ActionLiveUrlData: Decodable {
  let url: String?
  let liveUrl: String?
}

struct ActionTCardCoverData: Decodable {
  let cover: String?
  let coverUrl: String?
}

struct ActionTCardCoverFilesData: Decodable {
  let files: [String]?
  let urls: [String]?
}

struct ActionLightStateData: Decodable {
  let state: Int?
  let isOn: Bool?
}

struct ActionMediaItem: Decodable {
  let id: String?
  let url: String?
  let urlThumb: String?
  let taskId: String?

  private enum CodingKeys: String, CodingKey {
    case id = "_id"
    case url
    case urlThumb = "url_thumb"
    case taskId = "task_id"
  }
}
