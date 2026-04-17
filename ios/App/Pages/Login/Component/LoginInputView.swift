import SwiftUI

struct LoginInputView: View {
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

  private func normalizeMainlandPhoneInput(_ value: String) -> String {
    var digits = value.filter { $0.isNumber }

    if digits.hasPrefix("0086"), digits.count > 11 {
      digits = String(digits.dropFirst(4))
    } else if digits.hasPrefix("86"), digits.count > 11 {
      digits = String(digits.dropFirst(2))
    }

    return String(digits.prefix(11))
  }

  /// 改变一次，验证码输入框聚焦一次
  @State private var focusOneTime: Int = 0

  var body: some View {
    VStack(spacing: 12) {
      inputContainer {
        HStack(spacing: 12) {
          Image("icon_login_mobile")
            .renderingMode(.template)
            .foregroundColor(Color(hex: "A2A8B3"))
            .frame(width: 22, height: 22)

          TextField("请输入手机号", text: $phoneText)
            .autoFocus(false)
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

      inputContainer {
        HStack(spacing: 12) {
          Image("icon_login_captcha")
            .renderingMode(.template)
            .foregroundColor(Color(hex: "A2A8B3"))
            .frame(width: 22, height: 22)

          TextField("请输入验证码", text: $codeText)
            .focusOneTime($focusOneTime)
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
              focusOneTime += 1
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
  private func inputContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    content()
      .padding(.horizontal, 20)
      .frame(height: 56)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(Color(hex: "EFEFF4"))
          .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .stroke(Color(hex: "ECECF1"), lineWidth: 1)
          )
      )
  }
}
