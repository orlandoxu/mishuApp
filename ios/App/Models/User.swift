import Foundation

struct UserInfoXC: Codable, Equatable {
  let accessTokenXC: String
  let expiresInXC: Int
  let userIdXC: String
  let passwordXC: String
  let clientId: String
  let iotgw: String
  let glbs: String
  let clientSecret: String
}

// User这个模型不需要改了，因为服务器返回字段我核对过了
// 返回值：{"id":"6835669e560bec73312295bc","mobile":"13175364979","nickname":"","headImg":"","preferredLanguage":"zh-CN","email":"","totalMiles":0,"travelNotify":false,"alarmNotify":false,"snapshotNotify":false}
struct UserModel: Codable, Equatable {
  let userId: String
  let mobile: String
  let nickname: String
  let headImg: String
  let preferredLanguage: String // 用户设置的语言
  let email: String // 用户绑定的邮箱
  let avgSpeed: Double // 用户平均速度，单位：km/h
  let totalMiles: Double // 用户跑的总行程
  let totalTimeUsing: Double // 总使用时间，单位：秒
  let isTester: Bool // 是否是测试人员
  let isSetPassword: Bool // 是否设置了密码
  let userInfoXC: UserInfoXC? // 登录凭证
  // 下面这3个服务器有返回，但是暂时没用到，就不解析了
  // let travelNotify: Bool // 是否开启旅行通知
  // let alarmNotify: Bool // 是否开启报警通知
  // let snapshotNotify: Bool // 是否开启快照通知

  private enum CodingKeys: String, CodingKey {
    case userId
    case mobile
    case nickname
    case headImg
    case preferredLanguage
    case email
    case avgSpeed
    case totalMiles
    case totalTimeUsing
    case isTester
    case isSetPassword
    case userInfoXC
  }

  /// 手动解析，主要是保证无论如何都要解析成功
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userId = try container.decode(String.self, forKey: .userId)
    mobile = container.safeDecodeString(.mobile, "")
    nickname = container.safeDecodeString(.nickname, "")
    headImg = container.safeDecodeString(.headImg, "")
    preferredLanguage = container.safeDecodeString(.preferredLanguage, "zh-CN")
    email = container.safeDecodeString(.email, "")
    avgSpeed = container.safeDecodeDouble(.avgSpeed, 0)
    totalMiles = container.safeDecodeDouble(.totalMiles, 0)
    totalTimeUsing = container.safeDecodeDouble(.totalTimeUsing, 0)
    isTester = container.safeDecodeBool(.isTester, false)
    isSetPassword = container.safeDecodeBool(.isSetPassword, false)
    userInfoXC = try? container.decode(UserInfoXC.self, forKey: .userInfoXC)
  }
}
