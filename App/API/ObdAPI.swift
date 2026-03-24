import Foundation

final class OBDAPI {
  static let shared = OBDAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  /// DONE-AI: 如果真的不需要传入参数，那直接就不要定义 payload 参数了！所有的接口都是这样！全部都要改
  func appGet() async -> OBDAppGetData? {
    // Step 1. 组装获取 OBD 信息请求参数
    // Step 2. 发起获取 OBD 信息请求
    return await client.postRequest(
      "/v4/u/obd/appGet", Empty(), true, true
    )
  }

  func clearAlert() async -> OBDStatusData? {
    // Step 1. 组装清除告警请求参数
    // Step 2. 发起清除告警请求
    return await client.postRequest(
      "/v4/u/obd/clearAlert", Empty(), true, true
    )
  }

  func clearCode() async -> OBDStatusData? {
    // Step 1. 组装清除故障码请求参数
    // Step 2. 发起清除故障码请求
    return await client.postRequest(
      "/v4/u/obd/clearCode", Empty(), true, true
    )
  }

  func getAccOnVoltage() async -> OBDVoltageData? {
    // Step 1. 组装获取电压请求参数
    // Step 2. 发起获取电压请求
    return await client.postRequest(
      "/v4/u/obd/getAccOnVoltage", Empty(), true, false
    )
  }

  func getAlertCode() async -> OBDAlertCodeData? {
    // Step 1. 组装获取告警码请求参数
    // Step 2. 发起获取告警码请求
    return await client.postRequest(
      "/v4/u/obd/getAlertCode", Empty(), true, false
    )
  }

  func getDeviceStatusInfo(payload: OBDDeviceStatusPayload) async -> OBDDeviceStatusData? {
    // Step 1. 组装获取设备状态请求参数
    // Step 2. 发起获取设备状态请求
    return await client.postRequest(
      "/v4/u/obd/getDeviceStatusInfo", payload, true, false
    )
  }

  func getObdInfo() async -> OBDInfoData? {
    // Step 1. 组装获取 OBD 详情请求参数
    // Step 2. 发起获取 OBD 详情请求
    return await client.postRequest(
      "/v4/u/obd/getObdInfo", Empty(), true, false
    )
  }

  func getObdUserInfo() async -> OBDUserInfoData? {
    // Step 1. 组装获取 OBD 用户信息请求参数
    // Step 2. 发起获取 OBD 用户信息请求
    return await client.postRequest(
      "/v4/u/obd/getObdUserInfo", Empty(), true, false
    )
  }

  func getReportDetail() async -> OBDReportDetailData? {
    // Step 1. 组装获取报告详情请求参数
    // Step 2. 发起获取报告详情请求
    return await client.postRequest(
      "/v4/u/obd/getReportDetail", Empty(), true, false
    )
  }

  func getReportList() async -> OBDReportListData? {
    // Step 1. 组装获取报告列表请求参数
    // Step 2. 发起获取报告列表请求
    return await client.postRequest(
      "/v4/u/obd/getReportList", Empty(), true, false
    )
  }

  func goloApplyTest() async -> OBDStatusData? {
    // Step 1. 组装申请测试请求参数
    // Step 2. 发起申请测试请求
    return await client.postRequest(
      "/v4/u/obd/golo/applyTest", Empty(), true, true
    )
  }

  func goloIosStore() async -> OBDStatusData? {
    // Step 1. 组装 iOS 商店请求参数
    // Step 2. 发起 iOS 商店请求
    return await client.postRequest(
      "/v4/u/obd/golo/iosStore"
    )
  }

  func goloLatestApk() async -> OBDLatestApkData? {
    // Step 1. 组装获取最新 APK 请求参数
    // Step 2. 发起获取最新 APK 请求
    return await client.postRequest(
      "/v4/u/obd/golo/latestApk"
    )
  }

  func goloReportList() async -> OBDReportListData? {
    // Step 1. 组装获取 Golo 报告列表请求参数
    // Step 2. 发起获取 Golo 报告列表请求
    return await client.postRequest(
      "/v4/u/obd/golo/reportList"
    )
  }

  func goloTestStatus() async -> OBDTestStatusData? {
    // Step 1. 组装获取测试状态请求参数
    // Step 2. 发起获取测试状态请求
    return await client.postRequest(
      "/v4/u/obd/golo/testStatus"
    )
  }

  func goloUserInfo() async -> OBDGoloUserInfoData? {
    // Step 1. 组装获取 Golo 用户信息请求参数
    // Step 2. 发起获取 Golo 用户信息请求
    return await client.postRequest(
      "/v4/u/obd/golo/userInfo"
    )
  }

  func setAlertCodeRead() async -> OBDStatusData? {
    // Step 1. 组装告警码已读请求参数
    // Step 2. 发起告警码已读请求
    return await client.postRequest(
      "/v4/u/obd/setAlertCodeRead"
    )
  }

  func uploadReport() async -> OBDStatusData? {
    // Step 1. 组装上传报告请求参数
    // Step 2. 发起上传报告请求
    return await client.postRequest(
      "/v4/u/obd/uploadReport"
    )
  }

  func getShopInfo() async -> ShopInfoData? {
    // Step 1. 组装获取门店信息请求参数
    // Step 2. 发起获取门店信息请求
    return await client.postRequest(
      "/v4/u/shop/getShopInfo"
    )
  }
}

struct OBDStatusData: Decodable {
  let success: Bool?
  let status: Int?
  let message: String?
}

struct OBDAppGetData: Decodable {}

struct OBDVoltageData: Decodable {
  let voltage: Double?
  let value: Double?
}

struct OBDAlertCodeData: Decodable {
  let list: [OBDAlertCodeItem]?
}

struct OBDAlertCodeItem: Decodable {
  let code: String?
  let desc: String?
  let level: Int?
}

struct OBDDeviceStatusPayload: Encodable {
  var imei: String?
}

struct OBDDeviceStatusData: Decodable {
  let status: Int?
  let averageFuelUsage: Double?
  let remainMileage: Int?
  let voltage: Int?
  let totalMiles: Int?
  let remainFuel: Int?
  let tCard: Bool?
  let oilLife: Int?
  let temperature: Int?
  let maxTemperature: Int?
  let maxRpm: Int?
  let maxInstantFuel: Int?
  let obdSn: String?
  let obdVersion: String?
}

struct OBDInfoData: Decodable {}

struct OBDUserInfoData: Decodable {}

struct OBDReportDetailData: Decodable {}

struct OBDReportListData: Decodable {
  let list: [OBDReportItem]?
}

struct OBDReportItem: Decodable {
  let id: String?
  let title: String?
  let createdAt: String?
}

struct OBDLatestApkData: Decodable {
  let url: String?
  let version: String?
}

struct OBDTestStatusData: Decodable {
  let status: Int?
  let message: String?
}

struct OBDGoloUserInfoData: Decodable {}

struct ShopInfoData: Decodable {
  let id: String?
  let name: String?
  let phone: String?
  let address: String?
}
