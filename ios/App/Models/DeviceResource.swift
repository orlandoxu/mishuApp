import Foundation

struct DeviceResource: Decodable {
  let resType: String // 资源类型：spaceCycle/time/live/device/sim/obdCar/space
  let total: Int64 // 资源总量
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
