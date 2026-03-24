import Foundation

struct TripData: Decodable, Identifiable {
  let id: String
  let imei: String
  let travelId: String
  let startTime: Int64
  let finishTime: Int64
  let startAddr: String
  let endAddr: String
  let space: Double
  let avgSpeed: Double
  let fuelPrice: Int
  let time: Int
  let startCity: String
  let endCity: String
  let score: Double
  let trackUrl: String
  let obd: Int
  let fuelUsage: Double
  let fuelAvg: Double
  let maxSpeed: Double

  var durationText: String {
    guard time > 0 else { return "-" }
    let minutes = (time + 59) / 60
    return "\(minutes)分"
  }

  enum CodingKeys: String, CodingKey {
    case id
    case imei
    case travelId
    case startTime
    case finishTime
    case startAddr
    case endAddr
    case space
    case avgSpeed
    case fuelPrice
    case time
    case startCity
    case endCity
    case score
    case trackUrl
    case obd
    case fuelUsage
    case fuelAvg
    case maxSpeed
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = container.safeDecodeString(.id, "")
    imei = container.safeDecodeString(.imei, "")
    travelId = container.safeDecodeString(.travelId, "")
    startTime = container.safeDecodeInt64(.startTime, 0)
    finishTime = container.safeDecodeInt64(.finishTime, 0)
    startAddr = container.safeDecodeString(.startAddr, "")
    endAddr = container.safeDecodeString(.endAddr, "")
    space = container.safeDecodeDouble(.space, 0)
    avgSpeed = container.safeDecodeDouble(.avgSpeed, 0)
    fuelPrice = container.safeDecodeInt(.fuelPrice, 0)
    time = container.safeDecodeInt(.time, 0)
    startCity = container.safeDecodeString(.startCity, "").removingSuffix(["市"])
    endCity = container.safeDecodeString(.endCity, "").removingSuffix(["市"])
    score = container.safeDecodeDouble(.score, 0)
    trackUrl = container.safeDecodeString(.trackUrl, "")
    obd = container.safeDecodeInt(.obd, 0)
    fuelUsage = container.safeDecodeDouble(.fuelUsage, 0)
    fuelAvg = container.safeDecodeDouble(.fuelAvg, 0)
    maxSpeed = container.safeDecodeDouble(.maxSpeed, 0)
  }
}

/// 这个是某个设备的统计（不是某个人的统计）
struct TripStatisticalData: Decodable {
  let avgSpeed: Double
  let createTime: String
  let scoreAccAvg: Double
  let scoreAvg: Double
  let totalDelTimes: Int
  let scorePeopleAvg: Double
  let increaseRate: Double
  let rankRate: Double
  let scoreAvgLast: Double
  let scoreBrakeAvg: Double
  let scoreEnvAvg: Double
  let scoreSpeedAvg: Double
  let scoreTurnAvg: Double
  let totalMiles: Double
  let totalTimeUsing: Int
  let totalTimes: Int
  let maxSpeed: Double
  let maxMiles: Double

  private enum CodingKeys: String, CodingKey {
    case avgSpeed
    case createTime
    case scoreAccAvg
    case scoreAvg
    case totalDelTimes
    case scorePeopleAvg
    case increaseRate
    case rankRate
    case scoreAvgLast
    case scoreBrakeAvg
    case scoreEnvAvg
    case scoreSpeedAvg
    case scoreTurnAvg
    case totalMiles
    case totalTimeUsing
    case totalTimes
    case maxSpeed
    case maxMiles
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    avgSpeed = container.safeDecodeDouble(.avgSpeed, 0)
    createTime = container.safeDecodeString(.createTime, "")
    scoreAccAvg = container.safeDecodeDouble(.scoreAccAvg, 0)
    scoreAvg = container.safeDecodeDouble(.scoreAvg, 0)
    totalDelTimes = container.safeDecodeInt(.totalDelTimes, 0)
    scorePeopleAvg = container.safeDecodeDouble(.scorePeopleAvg, 0)
    increaseRate = container.safeDecodeDouble(.increaseRate, 0)
    rankRate = container.safeDecodeDouble(.rankRate, 0)
    scoreAvgLast = container.safeDecodeDouble(.scoreAvgLast, 0)
    scoreBrakeAvg = container.safeDecodeDouble(.scoreBrakeAvg, 0)
    scoreEnvAvg = container.safeDecodeDouble(.scoreEnvAvg, 0)
    scoreSpeedAvg = container.safeDecodeDouble(.scoreSpeedAvg, 0)
    scoreTurnAvg = container.safeDecodeDouble(.scoreTurnAvg, 0)
    totalMiles = container.safeDecodeDouble(.totalMiles, 0)
    totalTimeUsing = container.safeDecodeInt(.totalTimeUsing, 0)
    totalTimes = container.safeDecodeInt(.totalTimes, 0)
    maxSpeed = container.safeDecodeDouble(.maxSpeed, 0)
    maxMiles = container.safeDecodeDouble(.maxMiles, 0)
  }
}

/// 这个是某个某个人的统计
struct UserTripStatistical: Codable {
  let totalMiles: Double // 累计里程
  let totalTimeUsing: Double // 累计时长
  let totalTimes: Int // 累计次数

  /// 计算属性，平均速度
  var avgSpeed: Double {
    totalTimeUsing > 0 ? totalMiles / totalTimeUsing : 0
  }
}
