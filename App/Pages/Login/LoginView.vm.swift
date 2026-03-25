import Foundation

enum LoginFlowError: Error {
  case invalidPhone
  case invalidCode
  case agreementNotAccepted
  case serverMessage(String)
  case missingToken
}

struct LoginViewModel {
  private func digitsOnly(_ value: String) -> String {
    value.filter { $0.isNumber }
  }

  private func normalizedLocalPhone(phoneText: String, zoneCode: String) -> String? {
    // Step 1. 统一过滤掉自动填充中的空格、+、- 等非数字字符
    var digits = digitsOnly(phoneText)
    if digits.isEmpty { return nil }

    // Step 2. 处理常见国际前缀（00）与区号前缀
    let zoneDigits = digitsOnly(zoneCode)
    if digits.hasPrefix("00") {
      digits = String(digits.dropFirst(2))
    }
    if !zoneDigits.isEmpty, digits.hasPrefix(zoneDigits), digits.count > zoneDigits.count {
      digits = String(digits.dropFirst(zoneDigits.count))
    }

    return digits.isEmpty ? nil : digits
  }

  func normalizedMobile(phoneText: String, zoneCode: String) -> String? {
    // Step 1. 先规范化本地手机号（兼容 iOS 自动填充带区号场景）
    guard let localPhone = normalizedLocalPhone(phoneText: phoneText, zoneCode: zoneCode) else { return nil }

    // Step 2. 统一输出完整国际格式（例如：+8615655438839）
    let zoneDigits = digitsOnly(zoneCode)
    guard !zoneDigits.isEmpty else { return nil }
    return "+\(zoneDigits)\(localPhone)"
  }

  func canRequestCode(phoneText: String, zoneCode: String) -> Bool {
    // Step 1. 简单校验手机号是否可请求验证码（对齐 flutter：+86 严格校验，其它区号放宽）
    guard normalizedMobile(phoneText: phoneText, zoneCode: zoneCode) != nil else { return false }
    if zoneCode != "+86" { return true }
    guard let localPhone = normalizedLocalPhone(phoneText: phoneText, zoneCode: zoneCode) else { return false }
    let pattern = #"^1[3-9]\d{9}$"#
    return localPhone.range(of: pattern, options: .regularExpression) != nil
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
    guard !code.isEmpty else { return .failure(.invalidCode) }

    // Step 2. 发起登录请求
    guard let data = await UserAPI.shared.login(mobile: mobile, code: code) else {
      return .failure(.missingToken)
    }
    return .success(data)
  }

  func requestLoginByPassword(
    phoneText: String,
    passwordText: String,
    zoneCode: String,
    agreementAccepted: Bool
  ) async -> Result<LoginData, LoginFlowError> {
    // Step 1. 校验输入
    guard agreementAccepted else { return .failure(.agreementNotAccepted) }
    guard let mobile = normalizedMobile(phoneText: phoneText, zoneCode: zoneCode), !mobile.isEmpty else {
      return .failure(.invalidPhone)
    }
    guard !passwordText.isEmpty else { return .failure(.invalidCode) }

    // Step 2. 发起登录请求
    guard let data = await UserAPI.shared.loginByPassword(mobile: mobile, password: passwordText) else {
      return .failure(.missingToken)
    }
    return .success(data)
  }
}
