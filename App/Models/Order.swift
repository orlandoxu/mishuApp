import Foundation

struct OrderResourceModel: Decodable, Hashable {
  /// 资源类型：spaceCycle-云存储周期(天), time-服务时长, device-基础服务, live-直播时长, flow/sim-流量, space-旧版云存储
  let resType: String
  /// 总量（flow/sim 按字节；spaceCycle/time/live/device 按业务数值）
  let total: Int64
  /// 已使用量
  let used: Int64
  /// 剩余量
  let left: Int64
  /// 开始时间（毫秒时间戳）
  let startTime: Int64
  /// 结束时间（毫秒时间戳）
  let endTime: Int64
  /// 生效状态：1-生效中
  let effectiveStatus: Int

  private enum CodingKeys: String, CodingKey {
    case resType
    case total
    case used
    case left
    case startTime
    case endTime
    case effectiveStatus
  }

  init(
    resType: String,
    total: Int64,
    used: Int64,
    left: Int64,
    startTime: Int64,
    endTime: Int64,
    effectiveStatus: Int
  ) {
    self.resType = resType
    self.total = total
    self.used = used
    self.left = left
    self.startTime = startTime
    self.endTime = endTime
    self.effectiveStatus = effectiveStatus
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    resType = container.safeDecodeString(.resType, "")
    total = container.safeDecodeInt64(.total, 0)
    used = container.safeDecodeInt64(.used, 0)
    left = container.safeDecodeInt64(.left, 0)
    startTime = container.safeDecodeInt64(.startTime, 0)
    endTime = container.safeDecodeInt64(.endTime, 0)
    effectiveStatus = container.safeDecodeInt(.effectiveStatus, 0)
  }

  static func empty(resType: String) -> OrderResourceModel {
    OrderResourceModel(
      resType: resType,
      total: 0,
      used: 0,
      left: 0,
      startTime: 0,
      endTime: 0,
      effectiveStatus: 0
    )
  }
}

struct OrderModel: Decodable, Identifiable {
  /// 订单ID
  let id: String
  /// 套餐ID
  let packageId: String
  /// 套餐标题（显示在卡片顶部）
  let packageTitle: String
  /// 套餐描述
  let packageDesc: String
  /// 订单类型：init-初始订单？
  let type: String
  /// 来源：app
  let source: String
  /// Status 订单支付状态 枚举值: 0-已完成, 1-创建(未支付), 2-已退单, 3-允许用户自主退单, 4-退款中, 5-只退了资源未退款, 6-退了资源又在线上退了款
  let status: Int
  /// 生效状态：1-生效中
  let effectiveStatus: Int
  /// 是否过期
  let isExpired: Bool
  /// 订单开始时间（毫秒时间戳）
  let startTime: Int64
  /// 订单结束时间（毫秒时间戳）
  let endTime: Int64
  /// 价格（单位：分？）
  let price: Int64
  /// 原价（单位：分？）
  let originalPrice: Int64
  /// 包含的资源列表
  let resources: [OrderResourceModel]
  /// 设备IMEI
  let imei: String
  /// SIM卡ICCID
  let iccId: String
  /// SIM卡信息
  let simInfo: String
  /// 是否是我们自己的卡(xj是我们公司名称)
  let isXjCard: Bool
  /// 产品ID
  let productId: String
  /// 手机号
  let mobile: String

  var spaceCycleResource: OrderResourceModel {
    resources.first(where: { $0.resType == "spaceCycle" }) ?? .empty(resType: "spaceCycle")
  }

  /// 兼容旧字段（老数据可能是 space）
  var legacySpaceResource: OrderResourceModel {
    resources.first(where: { $0.resType == "space" }) ?? .empty(resType: "space")
  }

  var timeResource: OrderResourceModel {
    resources.first(where: { $0.resType == "time" }) ?? .empty(resType: "time")
  }

  var deviceResource: OrderResourceModel {
    resources.first(where: { $0.resType == "device" }) ?? .empty(resType: "device")
  }

  var liveResource: OrderResourceModel {
    resources.first(where: { $0.resType == "live" }) ?? .empty(resType: "live")
  }

  var flowResource: OrderResourceModel {
    resources.first(where: { $0.resType == "flow" || $0.resType == "sim" }) ?? .empty(resType: "flow")
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case packageId
    case packageTitle
    case packageDesc
    case type
    case source
    case status
    case effectiveStatus
    case isExpired
    case startTime
    case endTime
    case price
    case originalPrice
    case resources
    case imei
    case iccId
    case simInfo
    case isXjCard
    case productId
    case mobile
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = container.safeDecodeString(.id, "")
    packageId = container.safeDecodeString(.packageId, "")
    packageTitle = container.safeDecodeString(.packageTitle, "")
    packageDesc = container.safeDecodeString(.packageDesc, "")
    type = container.safeDecodeString(.type, "")
    source = container.safeDecodeString(.source, "")
    status = container.safeDecodeInt(.status, 0)
    effectiveStatus = container.safeDecodeInt(.effectiveStatus, 0)
    isExpired = container.safeDecodeBool(.isExpired, false)
    startTime = container.safeDecodeInt64(.startTime, 0)
    endTime = container.safeDecodeInt64(.endTime, 0)
    price = container.safeDecodeInt64(.price, 0)
    originalPrice = container.safeDecodeInt64(.originalPrice, 0)
    resources = container.safeDecodeArray(.resources, [])
    imei = container.safeDecodeString(.imei, "")
    iccId = container.safeDecodeString(.iccId, "")
    simInfo = container.safeDecodeString(.simInfo, "")
    isXjCard = container.safeDecodeBool(.isXjCard, false)
    productId = container.safeDecodeString(.productId, "")
    mobile = container.safeDecodeString(.mobile, "")
  }
}
