import Foundation
import UIKit

enum UserAPIError: Error {
  case serverMessage(String)
  case missingData
}

extension UserAPIError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case let .serverMessage(message):
      return message
    case .missingData:
      return "数据缺失"
    }
  }
}

struct LoginData: Codable {
  let token: String
  let mobile: String
}

/// 预测数据
struct CanBindVehiclePredictCarInfo: Decodable, Hashable {
  let vin: String
  let vinImgUrl: String
  let carSeriesId: Int
  let carSeriesSpecId: Int
  let powerType: Int
  let engineAutoStart: Int
  let carBrand: String
  let carModel: String
  let carType: String
  let carIcon: String
  let totalMiles: Double
  let carLicense: String

  private enum CodingKeys: String, CodingKey {
    case vin
    case vinImgUrl
    case carSeriesId
    case carSeriesSpecId
    case powerType
    case engineAutoStart
    case carBrand
    case carModel
    case carType
    case carIcon
    case totalMiles
    case carLicense
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    vin = container.safeDecodeString(.vin, "")
    vinImgUrl = container.safeDecodeString(.vinImgUrl, "")
    carSeriesId = container.safeDecodeInt(.carSeriesId, 0)
    carSeriesSpecId = container.safeDecodeInt(.carSeriesSpecId, 0)
    powerType = container.safeDecodeInt(.powerType, 0)
    engineAutoStart = container.safeDecodeInt(.engineAutoStart, 0)
    carBrand = container.safeDecodeString(.carBrand, "")
    carModel = container.safeDecodeString(.carModel, "")
    carType = container.safeDecodeString(.carType, "")
    carIcon = container.safeDecodeString(.carIcon, "")
    totalMiles = container.safeDecodeDouble(.totalMiles, 0)
    carLicense = container.safeDecodeString(.carLicense, "")
  }
}

struct CanBindVehicleData: Decodable {
  let imei: String
  let sn: String
  let plateRegion: String // 车牌区域(如果是CHN，就是中国车牌。如果是HK，就是香港车牌)
  let isObdDevice: Int // isObdDevice 如果是1，那么必须要检测是否是wifi绑定。OBD设备必须wifi绑定。而且OBD设备，必须要有第四步！其他设备，都没有第四步。
  let needVinPhoto: Bool // 如果是真，vin这一步就不需要拍照上传到七牛云。否则的话，vin这一步之需要输入正确的vin就行了（注意，vin是否正确，输入完了的时候，需要调用后台验证。）
  let predictCarInfo: CanBindVehiclePredictCarInfo?

  private enum CodingKeys: String, CodingKey {
    case imei
    case sn
    case plateRegion
    case isObdDevice
    case needVinPhoto
    case predictCarInfo
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    imei = container.safeDecodeString(.imei, "")
    sn = container.safeDecodeString(.sn, "")
    plateRegion = container.safeDecodeString(.plateRegion, "")
    isObdDevice = container.safeDecodeInt(.isObdDevice, 0)

    if let raw = try? container.decodeIfPresent(Bool.self, forKey: .needVinPhoto) {
      needVinPhoto = raw
    } else {
      needVinPhoto = container.safeDecodeInt(.needVinPhoto, 0) == 1
    }

    predictCarInfo = try? container.decodeIfPresent(CanBindVehiclePredictCarInfo.self, forKey: .predictCarInfo)
  }
}

final class UserAPI {
  static let shared = UserAPI()

  private let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func getInfo() async -> UserModel? {
    // Step 1. 发起用户信息请求
    // Step 2. 解码并返回用户信息
    return await client.postRequest(
      "/v4/u/user/getInfo", Empty(), true, true
    )
  }

  func logout() async -> Empty? {
    // Step 1. 发起退出登录请求
    // Step 2. 忽略空返回
    return await client.postRequest(
      "/v4/u/user/logout", Empty(), true, true
    )
  }

  /// 验证码验证
  func validateCode(mobile: String) async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/getCode", AnyParams(["mobile": mobile]), true, true
    )
  }

  func login(mobile: String, code: String) async -> LoginData? {
    // Step 1. 组装验证码登录参数
    // Step 2. 发起登录请求并校验 token
    struct AppVerifyCodePayload: Encodable {
      // let registrationID: String
      let phoneImei: String
      let mobile: String
      let code: String
      let new_version: Bool
      let agreement: String
    }

    let payload = AppVerifyCodePayload(
      // registrationID: UserDefaults.standard.string(forKey: "mishu_registration_id") ?? "",
      phoneImei: deviceUUID(),
      mobile: mobile,
      code: code,
      new_version: true,
      agreement: "allow"
    )

    guard let data: LoginData = await client.postRequest(
      "/v4/u/user/appVerifyCode", payload, true, true
    ) else {
      return nil
    }

    guard !data.token.isEmpty else { return nil }

    return data
  }

  func loginByPassword(mobile: String, password: String) async -> LoginData? {
    // Step 1. 组装密码登录参数
    // Step 2. 发起登录请求并校验 token
    guard let data: LoginData = await client.postRequest(
      "/v4/u/user/loginByAcountAndPwd",
      AnyParams(["mobile": mobile, "password": password, "phoneImei": deviceUUID()]),
      true,
      true
    ) else {
      return nil
    }
    guard !data.token.isEmpty else { return nil }
    return data
  }

  func updateAvatar(_ avatar: String) async -> UserModel? {
    // Step 1. 发起用户资料更新请求
    // Step 2. 解码并返回更新结果
    return await client.postRequest(
      "/v4/u/user/updateInfo", AnyParams(["headImg": avatar]), true, true
    )
  }

  func updateNickname(_ nickname: String) async -> UserModel? {
    return await client.postRequest(
      "/v4/u/user/updateInfo", AnyParams(["nickName": nickname]), true, true
    )
  }

  func updateIosDeviceToken(_ deviceToken: String) async -> UserModel? {
    struct UpdateIosDeviceTokenPayload: Encodable {
      let iosDeviceToken: String
      let iosIsDebug: Bool
    }

    print("[UserAPI] Updating iOS device token: \(deviceToken) with debug flag: \(AppConst.iosIsDebug)")

    return await client.postRequest(
      "/v4/u/user/updateInfo",
      UpdateIosDeviceTokenPayload(
        iosDeviceToken: deviceToken,
        iosIsDebug: AppConst.iosIsDebug
      ),
      true,
      false
    )
  }

  func updatePassword(_ password: String, _ oldPassword: String = "") async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/changePwd", AnyParams(["newPassword": password, "oldPassword": oldPassword]), true, true
    )
  }

  func updateInfo(payload: UserUpdateInfoPayload) async -> UserModel? {
    // Step 1. 发起用户资料更新请求
    // Step 2. 解码并返回更新结果
    return await client.postRequest(
      "/v4/u/user/updateInfo", payload, true, true
    )
  }

  func bindMobile(mobile: String, code: String) async -> UserBindMobileData? {
    struct UserBindMobilePayload: Encodable {
      let mobile: String
      let code: String
    }

    // Step 1. 发起绑定手机号请求
    // Step 2. 解码并返回绑定结果
    return await client.postRequest(
      "/v4/u/user/bindMobile", UserBindMobilePayload(mobile: mobile, code: code), true, true
    )
  }

  func getMobile(payload: Empty = Empty()) async -> UserGetMobileData? {
    // Step 1. 发起获取手机号请求
    // Step 2. 解码并返回手机号信息
    return await client.postRequest(
      "/v4/u/user/getMobile", payload, true, false
    )
  }

  func isNeedWifiMode(payload: Empty = Empty()) async -> UserIsNeedWifiModeData? {
    // Step 1. 发起是否需要 WiFi 模式请求
    // Step 2. 解码并返回判断结果
    return await client.postRequest(
      "/v4/u/user/isNeedWifiMode", payload, true, false
    )
  }

  func initPackageStatus(payload: Empty = Empty()) async -> UserInitPackageStatusData? {
    // Step 1. 发起初始化套餐状态请求
    // Step 2. 解码并返回状态结果
    return await client.postRequest(
      "/v4/u/user/initPackageStatus", payload, true, false
    )
  }

  func isNeedSupplementCarInfo(payload: Empty = Empty()) async
    -> UserIsNeedSupplementCarInfoData?
  {
    // Step 1. 发起是否需要补充车辆信息请求
    // Step 2. 解码并返回判断结果
    return await client.postRequest(
      "/v4/u/user/isNeedSupplementCarInfo", payload, true, false
    )
  }

  func getPredictCarInfo(payload: Empty = Empty()) async -> UserGetPredictCarInfoData? {
    // Step 1. 发起获取预测车辆信息请求
    // Step 2. 解码并返回预测信息
    return await client.postRequest(
      "/v4/u/user/getPredictCarInfo", payload, true, false
    )
  }

  func getAllVehicle() async -> [VehicleModel]? {
    await getAllVehicleWithRaw()?.vehicles
  }

  /// 返回设备列表 + 原始列表JSON数据（用于本地缓存）
  func getAllVehicleWithRaw() async -> (vehicles: [VehicleModel], rawData: Data)? {
    // Step 1. 发起获取全部车辆请求（先按原始JSON接收，便于持久化缓存）
    guard let rawList: [JSONValue] = await client.postRequest(
      "/v4/u/user/getAllVehicle", Empty(), true, false
    ) else {
      return nil
    }

    // Step 2. 原始JSON转Data并解码成业务模型
    guard let rawData = try? JSONEncoder().encode(rawList),
          let vehicles = decodeAllVehicleRawData(rawData)
    else {
      return nil
    }

    return (vehicles, rawData)
  }

  func decodeAllVehicleRawData(_ rawData: Data) -> [VehicleModel]? {
    guard var vehicles = try? JSONDecoder().decode([VehicleModel].self, from: rawData) else {
      return nil
    }
    // 无论来源于云端还是本地缓存，统一按绑定时间倒序，避免展示顺序不一致
    vehicles.sort { $0.bindAt > $1.bindAt }
    return vehicles
  }

  func unbindVehicle(imei: String) async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/unbindVehicle", AnyParams(["imei": imei]), true, true
    )
  }

  func setFavoriteVehicle(payload: UserSetFavoriteVehiclePayload) async
    -> UserSetFavoriteVehicleData?
  {
    // Step 1. 发起设置默认车辆请求
    // Step 2. 解码并返回设置结果
    return await client.postRequest(
      "/v4/u/user/setFavoriteVehicle", payload, true, true
    )
  }

  func canBindVehicle(imei: String, sn: String) async -> CanBindVehicleData? {
    return await client.postRequest(
      "/v4/u/user/canBindVehicle", AnyParams(["imei": imei, "sn": sn]), true, true
    )
  }

  func canBindVehicle(_ qrCode: String) async -> CanBindVehicleData? {
    return await client.postRequest(
      "/v4/u/user/canBindVehicle", AnyParams(["qrCode": qrCode]), true, true
    )
  }

  /// 这个传入的参数要改改，我把文档给你：
  func bindVehicle(payload: UserBindVehiclePayload) async
    -> UserBindVehicleBySnData?
  {
    return await client.postRequest(
      "/v4/u/user/newBindVehicle", payload, true, true
    )
  }

  // TODO: 后需要删除这个，没有QR绑定这么一说
  // func bindVehicleByQr(payload: UserBindVehicleByQrPayload) async throws
  //   -> UserBindVehicleByQrData?
  // {
  //   // Step 1. 发起二维码绑定车辆请求
  //   // Step 2. 解码并返回绑定结果
  //   try await client.request(
  //     .Post, "/v4/u/user/bindVehicleByQr", payload
  //   )
  // }

  func getNoticeConfiguration(payload: Empty = Empty()) async
    -> UserGetNoticeConfigurationData?
  {
    // Step 1. 发起获取消息通知配置请求
    // Step 2. 解码并返回配置结果
    return await client.postRequest(
      "/v4/u/user/getNoticeConfiguration", payload, true, false
    )
  }

  func setNoticeConfiguration(payload: UserSetNoticeConfigurationPayload) async
    -> UserSetNoticeConfigurationData?
  {
    // Step 1. 发起设置消息通知配置请求
    // Step 2. 解码并返回设置结果
    return await client.postRequest(
      "/v4/u/user/setNoticeConfiguration", payload, true, true
    )
  }

  func deregister(payload: Empty = Empty()) async -> UserDeregisterData? {
    // Step 1. 发起注销账号请求
    // Step 2. 解码并返回注销结果
    return await client.postRequest(
      "/v4/u/user/deregister", payload, true, true
    )
  }

  func isValidVin(_ vin: String) async -> UserIsValidVinData? {
    // Step 1. 发起校验 VIN 请求
    // Step 2. 解码并返回校验结果
    return await client.postRequest(
      "/v4/u/user/isValidVin", AnyParams(["vin": vin]), true, true
    )
  }

  func phoneInfo(payload: Empty = Empty()) async -> UserPhoneInfoData? {
    // Step 1. 发起手机信息请求
    // Step 2. 解码并返回信息结果
    return await client.postRequest(
      "/v4/u/user/phoneInfo", payload, true, false
    )
  }

  /// 主要作用，是让app在启动时候，预热app
  func ping() async -> Empty? {
    return await client.getRequest(
      "/ping", nil, false, false
    )
  }

  private func deviceUUID() -> String {
    // Step 1. 获取系统标识符
    // Step 2. 标识符为空时生成随机 UUID
    UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
  }
}

struct UserUpdateInfoPayload: Encodable {
  let headImg: String?
  let nickName: String?

  init(headImg: String? = nil, nickName: String? = nil) {
    self.headImg = headImg
    self.nickName = nickName
  }
}

struct UserOneClickLoginPayload: Encodable {
  let token: String
  let mobile: String? = nil
}

struct UserSetFavoriteVehiclePayload: Encodable {
  let imei: String
}

struct UserBindVehicleByQrPayload: Encodable {
  let qrcode: String
}

struct UserSetNoticeConfigurationPayload: Encodable {
  let config: [String: Int]
}

struct UserIsValidVinPayload: Encodable {
  let vin: String
}

// {
//   "newImei": string,
//   "newSn": string,
//   "appPlatform": string,
//   "car_license": string,    // 车牌号        如果跳过填 skip
//   "vin": string,    // vin号
//   "vin_img": string,     // vin图片
//   "car_brand": string,    // 车系名称
//   "car_model": string,    // 品牌名称
//   "car_icon": string,    // 品牌logo的url
//   "car_type": string,    // 汽车类型 -- 目前只有公众号在用
//   "series_id": int,        // 车系id
//   "total_miles": float，    // 设备总里程
//   "engine_auto_start": int // 1-支持 0-不支持
//   "power_type":int // 动力类型 0-未填 1-电动，2-燃油，3-混动
//   "isObdDevice":int // 1-是 2-否 0-未填
//   "chiPId": string
//   "obdSn": string  // obdsn
//   "isCouldRecivePackage": int        // 1-可以领取，其他都为不可领取
//   "widWithArea": "CHN",             //根据渠道区别不同地区的车牌  CHN/HKG/USA/JPN
// }
struct UserBindVehiclePayload: Encodable {
  let imei: String
  let sn: String
  let appPlatform: String
  let carLicense: String // 车牌
  // VIN信息
  let vin: String
  let vinImg: String
  /// 车型信息
  let seriesId: Int
  // 车况信息
  let totalMiles: Float
  let engineAutoStart: Int
  let powerType: Int
  let isObdDevice: Int
  let chipId: String
  let obdSn: String
}

struct UserWechatLoginData: Decodable {}
struct UserBindMobileData: Decodable {}
struct UserGetMobileData: Decodable {}
struct UserOneClickLoginData: Decodable {}
struct UserIsNeedWifiModeData: Decodable {}
struct UserInitPackageStatusData: Decodable {}
struct UserIsNeedSupplementCarInfoData: Decodable {}
struct UserGetPredictCarInfoData: Decodable {}
struct UserSetFavoriteVehicleData: Decodable {}
struct UserBindVehicleByQrData: Decodable {}
struct UserBindVehicleBySnData: Decodable {}
struct UserGetNoticeConfigurationData: Decodable {}
struct UserSetNoticeConfigurationData: Decodable {}
struct UserDeregisterData: Decodable {}

struct UserIsValidVinData: Decodable {
  let isValidVin: Bool
}

struct UserPhoneInfoData: Decodable {}
