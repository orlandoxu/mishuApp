import Foundation

struct OBDStatusModel: Decodable {
  let averageFuelUsage: Int?
  let maxInstantFuel: Int?
  let maxRpm: Int?
  let obdSn: String?
  let obdUpdateTime: String?
  let obdVersion: String?
  let obdVoltage: Int?
  let oilLife: Int?
  let remainFuel: Int?
  let remainMileage: Int?
  let status: Int?
  let tCard: Bool?
  let temperature: Int?
  let totalMiles: Int?
  let voltage: Int?
  let voltageUpdateTime: String?
}

struct OBDFuelModel: Decodable {
  let averageFuel: Int? // 平均燃油消耗
  let instantFuel: Int? // 瞬时燃油消耗
  let remainFuel: Int? // 剩余燃油量
  let remainingFuel: Int? // 剩余燃油量
  let remainingMileage: Int? // 剩余里程
  let totalFuel: Int? // 总燃油量
}

/// 车辆 OBD 模型
struct OBDModel: Decodable {
  let alert: Int?
  let commandId: String?
  let door: Int?
  let drive: Int?
  let fuel: OBDFuelModel?
  let light: Int?
  let lock: Int?
  let source: String?
  let tirePressure: String?
  let window: Int?

  // 没用到的先不要
  // let alertInfo: [VehicleOBDAlertInfoItem]?
}
