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
    await client.getRequest("/health", Empty(), false, false)
  }

  func getInfo() async -> UserModel? {
    await client.postRequest("/user/getInfo", Empty(), true, true)
  }

  func logout() async -> Empty? {
    await client.postRequest("/user/logout", Empty(), true, true)
  }

  func validateCode(mobile: String) async -> Empty? {
    await client.postRequest(
      "/user/getCode", AnyParams(["mobile": mobile]), false, true
    )
  }

  func login(mobile: String, code: String) async -> LoginData? {
    let payload = AnyParams(["phoneImei": deviceUUID(), "mobile": mobile, "code": code])

    guard let data: LoginData = await client.postRequest(
      "/user/appVerifyCode", payload, false, true
    ) else {
      return nil
    }

    return data.token.isEmpty ? nil : data
  }

  private func deviceUUID() -> String {
    UIDevice.current.identifierForVendor?.uuidString ?? ""
  }
}
