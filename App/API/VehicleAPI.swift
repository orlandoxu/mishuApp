import Foundation

final class VehicleAPI {
  static let shared = VehicleAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getBindQRCode(payload: Empty = Empty()) async -> VehicleBindQRCodeData? {
    return await client.postRequest(
      "/v4/u/getBindQRCode", payload, true, true
    )
  }

  func baseInfo(payload: VehicleImeiPayload) async -> VehicleBaseInfoData? {
    return await client.postRequest(
      "/v4/u/vehicle/baseInfo", payload, true, false
    )
  }

  func getWifiBaseInfo(payload: VehicleImeiPayload) async -> VehicleWifiBaseInfoData? {
    return await client.postRequest(
      "/v4/u/vehicle/getWifiBaseInfo", payload, true, false
    )
  }

  func offlineTips(payload: VehicleImeiPayload) async -> VehicleOfflineTipsData? {
    return await client.postRequest(
      "/v4/u/vehicle/offlineTips", payload, true, false
    )
  }

  func realTimeInfo(payload: VehicleImeiPayload) async -> VehicleRealTimeInfoData? {
    return await client.postRequest(
      "/v4/u/vehicle/realTimeInfo", payload, true, false
    )
  }

  func resolution(payload: VehicleImeiPayload) async -> VehicleResolutionData? {
    return await client.postRequest(
      "/v4/u/vehicle/resolution", payload, true, false
    )
  }

  func setCarInfo(payload: VehicleSetCarInfoPayload) async -> Empty? {
    // Step 1. 组装车辆信息更新参数
    // Step 2. 发起车辆信息更新请求
    return await client.postRequest(
      "/v4/u/vehicle/setCarInfo", payload, true, true
    )
  }

  func tcard(payload: VehicleImeiPayload) async -> VehicleTCardData? {
    return await client.postRequest(
      "/v4/u/vehicle/tcard", payload, true, false
    )
  }

  /// 激活设备
  func activeDevice(imei: String) async -> Empty? {
    return await client.postRequest(
      "/v4/u/package/receivePackage", AnyParams(["imei": imei]), true, true
    )
  }
}

struct VehicleImeiPayload: Encodable {
  let imei: String
}

struct VehicleSetCarInfoPayload: Encodable {
  let imei: String
  let carLicense: String?
  let brand: String?
  let model: String?
  let seriesId: Int?
  let vin: String?
  let totalMiles: Int?
  let tank: Int?
  let nickname: String?

  // DONE-AI: 你提供了这个init，那接口传入这个东西的时候，你也要用这个啊。可以减少代码呢
  init(
    imei: String,
    carLicense: String? = nil,
    brand: String? = nil,
    model: String? = nil,
    seriesId: Int? = nil,
    vin: String? = nil,
    totalMiles: Int? = nil,
    tank: Int? = nil,
    nickname: String? = nil
  ) {
    self.imei = imei
    self.carLicense = carLicense
    self.brand = brand
    self.model = model
    self.seriesId = seriesId
    self.vin = vin
    self.totalMiles = totalMiles
    self.tank = tank
    self.nickname = nickname
  }

  private enum CodingKeys: String, CodingKey {
    case imei
    case carLicense
    case brand
    case model
    case seriesId
    case vin
    case totalMiles
    case tank
    case nickname
  }
}

struct VehicleBindQRCodeData: Decodable {
  let qrcode: String?
  let qrCode: String?
  let url: String?
}

struct VehicleBaseInfoData: Decodable {
  let imei: String?
  let vin: String?
  let plateNo: String?
}

struct VehicleWifiBaseInfoData: Decodable {
  let ssid: String?
  let password: String?
}

struct VehicleOfflineTipsData: Decodable {
  let tips: String?
  let message: String?
}

struct VehicleRealTimeInfoData: Decodable {}

struct VehicleResolutionData: Decodable {
  let width: Int?
  let height: Int?
  let resolution: String?
}

struct VehicleTCardData: Decodable {
  let id: String?
  let url: String?
}
