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
  let userId: String?
  let mobile: String?
}

final class UserAPI {
  static let shared = UserAPI()

  private let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  func ping() async -> Empty? {
    await client.getRequest("/v4/common/ping", Empty(), false, false)
  }

  func getInfo() async -> UserModel? {
    await client.postRequest("/v4/u/user/getInfo", Empty(), true, true)
  }

  func logout() async -> Empty? {
    await client.postRequest("/v4/u/user/logout", Empty(), true, true)
  }

  func validateCode(mobile: String) async -> Empty? {
    await client.postRequest(
      "/v4/u/user/getCode",
      AnyParams(["mobile": mobile]),
      false,
      true
    )
  }

  func login(mobile: String, code: String) async -> LoginData? {
    struct AppVerifyCodePayload: Encodable {
      let phoneImei: String
      let mobile: String
      let code: String
      let new_version: Bool
      let agreement: String
    }

    let payload = AppVerifyCodePayload(
      phoneImei: deviceUUID(),
      mobile: mobile,
      code: code,
      new_version: true,
      agreement: "allow"
    )

    guard let data: LoginData = await client.postRequest(
      "/v4/u/user/appVerifyCode",
      payload,
      false,
      true
    ) else {
      return nil
    }

    return data.token.isEmpty ? nil : data
  }

  func loginByPassword(mobile: String, password: String) async -> LoginData? {
    guard let data: LoginData = await client.postRequest(
      "/v4/u/user/loginByAcountAndPwd",
      AnyParams(["mobile": mobile, "password": password, "phoneImei": deviceUUID()]),
      false,
      true
    ) else {
      return nil
    }

    return data.token.isEmpty ? nil : data
  }

  func registerByPassword(mobile: String, password: String) async -> LoginData? {
    guard let data: LoginData = await client.postRequest(
      "/v4/u/user/registerByAcountAndPwd",
      AnyParams([
        "mobile": mobile,
        "password": password,
        "nickname": "用户\(mobile.suffix(4))",
      ]),
      false,
      true
    ) else {
      return nil
    }

    return data.token.isEmpty ? nil : data
  }

  private func deviceUUID() -> String {
    UIDevice.current.identifierForVendor?.uuidString ?? ""
  }
}
