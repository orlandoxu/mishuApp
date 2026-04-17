import Foundation

enum LoginFlowError: Error {
  case invalidPhone
  case invalidCode
  case agreementNotAccepted
  case serverMessage(String)
  case missingToken
}

extension LoginFlowError {
  var userMessage: String {
    switch self {
    case .invalidPhone:
      return "请输入正确的手机号"
    case .invalidCode:
      return "请输入6位验证码"
    case .agreementNotAccepted:
      return "请先阅读并同意协议"
    case let .serverMessage(message):
      return message
    case .missingToken:
      return "登录失败，请稍后重试"
    }
  }
}

struct LoginViewModel {
  func normalizedMobile(phoneText: String, zoneCode _: String) -> String? {
    var digits = phoneText.filter { $0.isNumber }

    if digits.hasPrefix("0086"), digits.count > 11 {
      digits = String(digits.dropFirst(4))
    } else if digits.hasPrefix("86"), digits.count > 11 {
      digits = String(digits.dropFirst(2))
    }

    guard digits.count == 11 else { return nil }
    let pattern = #"^1[3-9]\d{9}$"#
    return digits.range(of: pattern, options: .regularExpression) != nil ? digits : nil
  }

  func canRequestCode(phoneText: String, zoneCode: String) -> Bool {
    normalizedMobile(phoneText: phoneText, zoneCode: zoneCode) != nil
  }

  func requestValidateCode(phoneText: String, zoneCode: String) async -> Result<Void, LoginFlowError> {
    // Step 1. 校验手机号
    guard let mobile = normalizedMobile(phoneText: phoneText, zoneCode: zoneCode), !mobile.isEmpty else {
      return .failure(.invalidPhone)
    }

    // Step 2. 发起 getCode 请求
    guard await UserAPI.shared.validateCode(mobile: mobile) != nil else {
      return .failure(.serverMessage("验证码发送失败，请稍后再试"))
    }
    return .success(())
  }

  func requestLogin(
    phoneText: String,
    codeText: String,
    zoneCode: String,
    agreementAccepted: Bool
  ) async -> Result<LoginData, LoginFlowError> {
    // Step 1. 校验输入
    guard agreementAccepted else { return .failure(.agreementNotAccepted) }
    guard let mobile = normalizedMobile(phoneText: phoneText, zoneCode: zoneCode), !mobile.isEmpty else {
      return .failure(.invalidPhone)
    }
    let code = codeText.filter { $0.isNumber }
    guard code.count == 6 else { return .failure(.invalidCode) }

    // Step 2. 发起登录请求
    guard let data = await UserAPI.shared.login(mobile: mobile, code: code) else {
      return .failure(.missingToken)
    }
    return .success(data)
  }
}
