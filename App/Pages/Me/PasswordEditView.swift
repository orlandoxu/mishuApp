import SwiftUI

struct PasswordEditView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var selfStore: SelfStore = .shared

  @State private var oldPassword = ""
  @State private var newPassword = ""
  @State private var confirmPassword = ""

  @State private var isOldPasswordVisible = false
  @State private var isNewPasswordVisible = false
  @State private var isConfirmPasswordVisible = false

  @State private var isLoading = false

  /// 是否需要显示旧密码（未设置过密码则不需要）
  private var needOldPassword: Bool {
    selfStore.selfUser?.isSetPassword == true
  }

  private var disabled: Bool {
    isLoading || !canSubmit
  }

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "修改密码")

      ScrollView {
        VStack(spacing: 24) {
          if needOldPassword {
            inputRow(title: "旧密码", placeholder: "请输入旧密码", text: $oldPassword, isVisible: $isOldPasswordVisible)
              .background(Color.white)
              .cornerRadius(8)
          }

          VStack(spacing: 0) {
            inputRow(title: "新密码", placeholder: "请输入新密码", text: $newPassword, isVisible: $isNewPasswordVisible)
            Divider().padding(.leading, 16)

            inputRow(title: "确认密码", placeholder: "请再次输入新密码", text: $confirmPassword, isVisible: $isConfirmPasswordVisible)
          }
          .background(Color.white)
          .cornerRadius(8)

          Text("密码长度至少8位，包含数字和字母")
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x999999"))
            .frame(maxWidth: .infinity, alignment: .leading)

          Button {
            submit()
          } label: {
            Text("确定")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(disabled ? Color(hex: "0x06BAFF").opacity(0.4) : Color(hex: "0x06BAFF"))
              .cornerRadius(8)
          }
          .disabled(disabled)
          .padding(.top, 24)
        }
        .padding(16)
      }
      .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
    }
    .ignoresSafeArea()
    .onTapGesture {
      UIApplication.shared.dismissKeyboard()
    }
    .navigationBarHidden(true)
    .overlay(
      Group {
        if isLoading {
          ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            ProgressView()
              .padding()
              .background(Color.white)
              .cornerRadius(8)
          }
        }
      }
    )
  }

  private func inputRow(title: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
    HStack(spacing: 16) {
      Text(title)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(Color(hex: "0x111111"))
        .frame(width: 70, alignment: .leading)

      HStack(spacing: 8) {
        SecureTextField(
          text: text,
          placeholder: placeholder,
          isSecure: !isVisible.wrappedValue
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)

        Button {
          isVisible.wrappedValue.toggle()
        } label: {
          Image(systemName: isVisible.wrappedValue ? "eye" : "eye.slash")
            .foregroundColor(Color(hex: "0x999999"))
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .frame(height: 56)
  }

  private var canSubmit: Bool {
    if needOldPassword && oldPassword.isEmpty { return false }
    if newPassword.isEmpty || confirmPassword.isEmpty { return false }
    return true
  }

  private func submit() {
    // 验证逻辑
    if newPassword.count < 8 {
      ToastCenter.shared.show("密码长度至少8位")
      return
    }

    // 必须包含字母和数字
    let hasLetter = newPassword.rangeOfCharacter(from: .letters) != nil
    let hasNumber = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
    if !hasLetter || !hasNumber {
      ToastCenter.shared.show("密码必须包含字母和数字")
      return
    }

    if newPassword != confirmPassword {
      ToastCenter.shared.show("两次输入的密码不一致")
      return
    }

    isLoading = true
    Task {
      let result = await UserAPI.shared.updatePassword(newPassword, needOldPassword ? oldPassword : "")
      await selfStore.refresh()
      await MainActor.run {
        isLoading = false
        if result != nil {
          ToastCenter.shared.show("密码修改成功")
          appNavigation.pop()
        } else {
          ToastCenter.shared.show("修改失败，请稍后再试")
        }
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }
}
