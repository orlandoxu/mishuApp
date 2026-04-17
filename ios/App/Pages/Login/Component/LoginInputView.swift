import SwiftUI

struct LoginInputView: View {
  private enum InputField: Hashable {
    case phone
    case code
  }

  @Binding var phoneText: String
  @Binding var codeText: String
  var countdownSeconds: Int
  var canGetCode: Bool
  var isWorking: Bool
  var onTapGetCode: () -> Void

  /// 当前是否可以发送验证码
  var canSendCode: Bool {
    canGetCode && countdownSeconds == 0 && !isWorking
  }

  private let activeCoral = Color(hex: "FF6B6B")
  private let inactiveIconColor = Color(hex: "A2A8B3")
  private let activeIconColor = Color(hex: "F08CA0")
  private let inactiveContainerColor = Color(hex: "EFEFF4")
  private let activeContainerColor = Color(hex: "FFF6F8")
  private let inactiveBorderColor = Color(hex: "ECECF1")
  private let activeBorderColor = Color(hex: "F6B8C5")

  private func normalizeMainlandPhoneInput(_ value: String) -> String {
    var digits = value.filter { $0.isNumber }

    if digits.hasPrefix("0086"), digits.count > 11 {
      digits = String(digits.dropFirst(4))
    } else if digits.hasPrefix("86"), digits.count > 11 {
      digits = String(digits.dropFirst(2))
    }

    return String(digits.prefix(11))
  }

  @FocusState private var focusedField: InputField?

  var body: some View {
    VStack(spacing: 12) {
      inputContainer(isFocused: focusedField == .phone) {
        HStack(spacing: 12) {
          Image("icon_login_mobile")
            .renderingMode(.template)
            .foregroundColor(focusedField == .phone ? activeIconColor : inactiveIconColor)
            .frame(width: 22, height: 22)

          TextField("请输入手机号", text: $phoneText)
            .autoFocus(false)
            .focused($focusedField, equals: .phone)
            .keyboardType(.numberPad)
            .textContentType(.telephoneNumber)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "2C3440"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .onChange(of: phoneText) { newValue in
              let normalized = normalizeMainlandPhoneInput(newValue)
              if normalized != newValue {
                phoneText = normalized
              }
            }
        }
      }

      inputContainer(isFocused: focusedField == .code) {
        HStack(spacing: 12) {
          Image("icon_login_captcha")
            .renderingMode(.template)
            .foregroundColor(focusedField == .code ? activeIconColor : inactiveIconColor)
            .frame(width: 22, height: 22)

          TextField("请输入验证码", text: $codeText)
            .focused($focusedField, equals: .code)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "2C3440"))
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
              focusedField = .code
              onTapGetCode()
            }
          } label: {
            Text(countdownSeconds > 0 ? "\(countdownSeconds)s" : "获取验证码")
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(canSendCode ? activeCoral : Color(hex: "B8BDC7"))
              .padding(.horizontal, 20)
              .frame(height: 42)
              .background(
                Capsule(style: .continuous)
                  .fill(canSendCode ? Color(hex: "FFEDEF") : Color(hex: "ECEDF2"))
              )
          }
          .offset(x: 4)
          .disabled(!canSendCode)
        }
      }
    }
  }

  @ViewBuilder
  private func inputContainer<Content: View>(
    isFocused: Bool,
    @ViewBuilder content: () -> Content
  ) -> some View {
    content()
      .padding(.horizontal, 20)
      .frame(height: 56)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(isFocused ? activeContainerColor : inactiveContainerColor)
          .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .stroke(isFocused ? activeBorderColor : inactiveBorderColor, lineWidth: isFocused ? 1.5 : 1)
          )
      )
  }
}
