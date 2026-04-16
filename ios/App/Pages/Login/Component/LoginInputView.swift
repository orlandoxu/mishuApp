import SwiftUI

struct LoginInputView: View {
  @Binding var zoneCode: String
  @Binding var phoneText: String
  @Binding var codeText: String
  @Binding var passwordText: String
  var isPasswordLogin: Bool
  var countdownSeconds: Int
  var canGetCode: Bool
  var isWorking: Bool
  var onTapGetCode: () -> Void

  @State private var isPasswordVisible: Bool = false
  private let zoneList = ["+852", "+853", "+886", "+86"]

  /// 当前是否可以发送验证码
  var canSendCode: Bool {
    canGetCode && countdownSeconds == 0 && !isWorking
  }

  private let activeBlue = ThemeColor.brand500

  /// 改变一次，验证码输入框聚焦一次
  @State private var focusOneTime: Int = 0

  // DONE-AI: 改出问题了，你这个界面输入框少了边框，UI是有边框的
  var body: some View {
    VStack(spacing: 16) {
      inputContainer {
        HStack(spacing: 6) {
          Image("icon_login_mobile")
            .renderingMode(.template)
            .foregroundColor(Color(hex: "374151"))
            .frame(width: 24, height: 24)

          HStack(spacing: 8) {
            Menu {
              Button("+86") { zoneCode = "+86" }
              Button("+852") { zoneCode = "+852" }
              Button("+853") { zoneCode = "+853" }
              Button("+886") { zoneCode = "+886" }
            } label: {
              Text(zoneCode)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "111827"))
                .frame(width: 50, alignment: .center)
            }

            Rectangle()
              .fill(Color(hex: "E5E7EB"))
              .frame(width: 1, height: 18)
          }

          TextField("请输入手机号码", text: $phoneText)
            .autoFocus(false)
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "111827"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: phoneText) { newValue in
              normalizePhone(newValue)
            }
        }
      }

      inputContainer {
        HStack(spacing: 12) {
          Image(isPasswordLogin ? "icon_login_password" : "icon_login_captcha")
            .renderingMode(.template)
            .foregroundColor(Color(hex: "374151"))
            .frame(width: 24, height: 24)

          if isPasswordLogin {
            HStack(spacing: 12) {
              SecureTextField(
                text: $passwordText,
                placeholder: "请输入密码",
                isSecure: !isPasswordVisible
              )
              .frame(maxWidth: .infinity, alignment: .leading)

              Button {
                isPasswordVisible.toggle()
              } label: {
                Image(isPasswordVisible ? "icon_login_eye" : "icon_login_eye_open")
                  .renderingMode(.template)
                  .foregroundColor(Color(hex: "9CA3AF"))
                  .frame(width: 24, height: 24)
              }
              .buttonStyle(.plain)
            }
          } else {
            TextField("请输入验证码", text: $codeText)
              .focusOneTime($focusOneTime)
              .keyboardType(.numberPad)
              .textContentType(.oneTimeCode)
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(Color(hex: "111827"))
              .frame(maxWidth: .infinity, alignment: .leading)
              .onChange(of: codeText) { newValue in
                let filtered = newValue.filter { $0.isNumber }
                let trimmed = String(filtered.prefix(6))
                if trimmed != newValue {
                  codeText = trimmed
                }
              }

            Button {
              if countdownSeconds == 0 {
                focusOneTime += 1
                onTapGetCode()
              }
            } label: {
              Text(countdownSeconds > 0 ? "\(countdownSeconds)s" : "获取验证码")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(canSendCode ? activeBlue : Color(hex: "9CA3AF"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                  Capsule(style: .continuous)
                    .fill(canSendCode ? ThemeColor.brand100 : Color(hex: "F3F4F6"))
                )
            }
            .disabled(!canSendCode)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func inputContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .padding(.horizontal, 14)
      .frame(height: 52)
      .background(Color.white.opacity(0.94))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
      )
  }

  private func normalizePhone(_ rawInput: String) {
    let compact = rawInput.components(separatedBy: .whitespacesAndNewlines).joined()
    guard !compact.isEmpty else { return }

    // Step 1. 识别并提取支持的区号前缀，若有则同步更新区号
    if let matchedZone = zoneList.first(where: { compact.hasPrefix($0) }) {
      let localPart = String(compact.dropFirst(matchedZone.count)).filter { $0.isNumber }
      if zoneCode != matchedZone {
        zoneCode = matchedZone
      }
      if phoneText != localPart {
        phoneText = localPart
      }
      return
    }

    // Step 2. 兼容 00 前缀形式（如 0086 / 00852）
    if compact.hasPrefix("00") {
      let candidateZoneDigits = String(compact.dropFirst(2))
      if let matchedZone = zoneList.first(where: { candidateZoneDigits.hasPrefix(String($0.dropFirst())) }) {
        let zoneDigits = String(matchedZone.dropFirst())
        let localPart = String(candidateZoneDigits.dropFirst(zoneDigits.count)).filter { $0.isNumber }
        if zoneCode != matchedZone {
          zoneCode = matchedZone
        }
        if phoneText != localPart {
          phoneText = localPart
        }
        return
      }
    }

    // Step 3. 没有可识别区号时，只保留手机号数字，不改写当前区号
    let digitsOnly = compact.filter { $0.isNumber }
    if phoneText != digitsOnly {
      phoneText = digitsOnly
    }
  }
}
