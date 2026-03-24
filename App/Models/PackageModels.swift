import Foundation

struct PackageInitInfoData: Decodable {}

struct PackageResourceItem: Decodable, Hashable {
  let resType: String
  let resCycle: Int
  let resCycleType: Int
  let total: Int

  private enum CodingKeys: String, CodingKey {
    case resType
    case resCycle
    case resCycleType
    case total
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    resType = container.safeDecodeString(.resType, "")
    resCycle = container.safeDecodeInt(.resCycle, 0)
    resCycleType = container.safeDecodeInt(.resCycleType, 0)
    total = container.safeDecodeInt(.total, 0)
  }

  var displayTitle: String {
    switch resType {
    case "sim", "flow":
      return "SIM卡流量包"
    case "spaceCycle", "space":
      return "云端存储"
    case "live":
      return "远程播放"
    case "device":
      return "设备授权"
    case "time":
      return "云记录"
    default:
      return "服务权益"
    }
  }

  var displaySubtitle: String {
    switch resType {
    case "sim", "flow":
      return "\(total) GB/月流量"
    case "spaceCycle":
      return "\(total)天循环"
    case "space":
      return Self.formatBytes(total)
    case "time", "live":
      return "\(total)分钟"
    case "device":
      return "\(total)台"
    default:
      return "\(total)"
    }
  }

  var displayDesc: String {
    if cycleText.isEmpty { return "" }
    return "\(cycleText)有效"
  }

  var displayIconName: String {
    switch resType {
    case "sim", "flow":
      return "simcard"
    case "space", "spaceCycle":
      return "cloud"
    case "time", "live":
      return "video.bubble"
    case "device":
      return "car"
    default:
      return "checkmark.seal"
    }
  }

  var displayIsSmall: Bool {
    true
  }

  var cycleText: String {
    if resCycle <= 0 { return "" }
    switch resCycleType {
    case 0:
      return "\(resCycle)月"
    case 1:
      return "\(resCycle)年"
    default:
      return "\(resCycle)周期"
    }
  }

  private static func formatBytes(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB, .useTB]
    formatter.countStyle = .binary
    return formatter.string(fromByteCount: Int64(bytes))
  }
}

struct PackageItem: Decodable, Hashable {
  let id: String
  let productId: String
  let title: String
  let note: String
  let resList: [PackageResourceItem]
  let status: Int
  let type: String
  let sign: Int
  let wid: String
  let price: Int
  let iosPrice: Int
  let activePrice: Int
  let iosActivePrice: Int
  let cost: Int
  let activeStartTime: Int64
  let activeEndTime: Int64
  let priority: Int
  let updateTime: Int64
  let createTime: Int64

  var priceYuanString: String {
    Self.formatYuan(fromFen: price).dropTailZero
  }

  var iosPriceYuanString: String {
    Self.formatYuan(fromFen: iosPrice).dropTailZero
  }

  var activePriceYuanString: String {
    Self.formatYuan(fromFen: activePrice).dropTailZero
  }

  var iosActivePriceYuanString: String {
    Self.formatYuan(fromFen: iosActivePrice).dropTailZero
  }

  var costYuanString: String {
    Self.formatYuan(fromFen: cost).dropTailZero
  }

  /// 目前只有微信支付，没那么复杂，全部都显示price的价格
  /// 除非有了iap支付，其他才有意义
  var displayPriceYuanString: String {
    // if iosActivePrice > 0 { return iosActivePriceYuanString }
    // if activePrice > 0 { return activePriceYuanString }
    // if iosPrice > 0 { return iosPriceYuanString }
    return priceYuanString
  }

  var originalPriceYuanString: String {
    if iosPrice > 0 { return iosPriceYuanString }
    return priceYuanString
  }

  var displayTitle: String {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "基础服务套餐" : trimmed
  }

  var displayDuration: String {
    note.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var coreResources: [PackageResourceItem] {
    var result: [PackageResourceItem] = []
    if let sim = coreSimResource {
      result.append(sim)
    }
    if let space = coreSpaceResource {
      result.append(space)
    }
    if let time = coreTimeResource {
      result.append(time)
    }
    return result
  }

  var guardResources: [PackageResourceItem] {
    resList.filter { $0.resType == "obd" }
  }

  var serviceResources: [PackageResourceItem] {
    resList.filter { $0.resType == "device" }
  }

  var coreSimResource: PackageResourceItem? {
    firstResource(of: "sim") ?? firstResource(of: "flow")
  }

  var coreSpaceResource: PackageResourceItem? {
    firstResource(of: "spaceCycle") ?? firstResource(of: "space")
  }

  var coreTimeResource: PackageResourceItem? {
    firstResource(of: "time") ?? firstResource(of: "live")
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case productId
    case title
    case note
    case resList
    case status
    case type
    case sign
    case wid
    case price
    case iosPrice
    case activePrice
    case iosActivePrice
    case cost
    case activeStartTime
    case activeEndTime
    case priority
    case updateTime
    case createTime
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = container.safeDecodeString(.id, "")
    productId = container.safeDecodeString(.productId, "")
    title = container.safeDecodeString(.title, "")
    note = container.safeDecodeString(.note, "")
    resList = container.safeDecodeArray(.resList, [])
    status = container.safeDecodeInt(.status, 0)
    type = container.safeDecodeString(.type, "")
    sign = container.safeDecodeInt(.sign, 0)
    wid = container.safeDecodeString(.wid, "")
    price = container.safeDecodeInt(.price, 0)
    iosPrice = container.safeDecodeInt(.iosPrice, 0)
    activePrice = container.safeDecodeInt(.activePrice, 0)
    iosActivePrice = container.safeDecodeInt(.iosActivePrice, 0)
    cost = container.safeDecodeInt(.cost, 0)
    activeStartTime = container.safeDecodeInt64(.activeStartTime, 0)
    activeEndTime = container.safeDecodeInt64(.activeEndTime, 0)
    priority = container.safeDecodeInt(.priority, 0)
    updateTime = container.safeDecodeInt64(.updateTime, 0)
    createTime = container.safeDecodeInt64(.createTime, 0)
  }

  private static func formatYuan(fromFen fen: Int) -> String {
    let number = NSDecimalNumber(value: fen).dividing(by: 100)
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ""
    return formatter.string(from: number) ?? number.stringValue
  }

  private func firstResource(of type: String) -> PackageResourceItem? {
    resList.first { $0.resType == type }
  }
}

struct PackageOrderData: Decodable {
  let orderId: String
  let id: String

  private enum CodingKeys: String, CodingKey {
    case orderId
    case id
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    orderId = container.safeDecodeString(.orderId, "")
    id = container.safeDecodeString(.id, "")
  }
}

struct PackageReceiveData: Decodable {}

struct PackageUserInfoData: Decodable {}

struct PackageUserUsingData: Decodable {}

// DONE-AI: 已使用safeDecodeXXX并为字段设置默认值
// DONE-AI: 已确保服务端字段无可选值
