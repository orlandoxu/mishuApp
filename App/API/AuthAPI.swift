import Foundation

final class AuthAPI {
  private let client: APIClient
  private let storage: KeyValueStorage

  init(client: APIClient = APIClient(), storage: KeyValueStorage = UserDefaultsStorage()) {
    self.client = client
    self.storage = storage
  }

  struct AuthUser: Codable {
    let id: String
    let phone: String?
    let nickname: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
      case id = "_id"
      case phone
      case nickname
      case avatar
    }
  }

  // struct LoginResponse: Decodable {
  //   let token: String
  //   let user: AuthUser
  // }

  // // func sendSms(phone: String) async -> Empty? {
  //   // Step 1. 组装发送短信请求参数
  //   let payload = AnyParams(["phone": phone])
  //   // Step 2. 发起发送短信请求
  //   return await client.postRequest(
  //     "/api/user/auth/send-sms",
  //     payload,
  //     false
  //   )
  // }

  // func login(phone: String, code: String) async -> LoginResponse? {
  //   // Step 1. 组装登录请求参数
  //   // Step 2. 发起登录请求并缓存凭证
  //   let response: LoginResponse? = await client.postRequest(
  //     "/api/user/auth/login",
  //     AnyParams(["phone": phone, "code": code]),
  //     false
  //   )
  //   if let response {
  //     await storage.setString(response.token, forKey: "token")
  //     if let data = try? JSONEncoder().encode(response.user) {
  //       await storage.setData(data, forKey: "user")
  //     }
  //   }
  //   return response
  // }
}
