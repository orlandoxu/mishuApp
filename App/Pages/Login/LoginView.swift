import SwiftUI

struct LoginView: View {
  private enum ActiveAlert: Identifiable {
    case agreement
    case message(String)

    var id: String {
      switch self {
      case .agreement:
        return "agreement"
      case let .message(message):
        return "message:\(message)"
      }
    }
  }

  @State private var zoneCode: String = "+86"
  @State private var phoneText: String = ""
  @State private var codeText: String = ""
  @State private var passwordText: String = ""
  @State private var isPasswordLogin: Bool = false
  @State private var agreed: Bool = false
  @State private var countdownSeconds: Int = 0
  @State private var isWorking: Bool = false
  @State private var countdownTask: Task<Void, Never>?
  @State private var activeAlert: ActiveAlert?

  private let viewModel = LoginViewModel()

  @ObservedObject private var appNavigation = AppNavigationModel.shared

  var body: some View {
    ZStack {
      LoginBackgroundView()
        .onTapGesture {
          UIApplication.shared.dismissKeyboard()
        }

      VStack(spacing: 30) {
        Spacer(minLength: 0)

        LoginLogoView()

        LoginInputView(
          zoneCode: $zoneCode,
          phoneText: $phoneText,
          codeText: $codeText,
          passwordText: $passwordText,
          isPasswordLogin: isPasswordLogin,
          countdownSeconds: countdownSeconds,
          canGetCode: canGetCode,
          isWorking: isWorking,
          onTapGetCode: tapGetCode
        )

        Spacer().frame(height: 30)

        LoginActionView(
          canLogin: canLogin,
          isWorking: isWorking,
          isPasswordLogin: $isPasswordLogin,
          onTapLogin: tapLogin
        )

        Spacer()

        LoginAgreementView(agreed: $agreed)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 20)
      .padding(.bottom, 20)
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .alert(item: $activeAlert) { item in
      switch item {
      case .agreement:
        Alert(
          title: Text("温馨提示"),
          message: Text("请先阅读并同意下方协议"),
          primaryButton: .default(Text("同意并登录")) {
            agreed = true
            performLogin()
          },
          secondaryButton: .cancel(Text("取消"))
        )
      case let .message(message):
        Alert(
          title: Text("提示"),
          message: Text(message),
          dismissButton: .default(Text("好的"))
        )
      }
    }
    .onDisappear {
      countdownTask?.cancel()
    }
  }

  private var canGetCode: Bool {
    countdownSeconds == 0 && viewModel.canRequestCode(phoneText: phoneText, zoneCode: zoneCode)
  }

  private var codeValue: String {
    codeText.filter { $0.isNumber }
  }

  private var authValid: Bool {
    isPasswordLogin ? !passwordText.isEmpty : codeValue.count == 6
  }

  private var canLogin: Bool {
    !phoneText.isEmpty && authValid
  }

  private func tapGetCode() {
    // Step 1. 校验当前状态
    guard canGetCode else { return }
    isWorking = true

    // Step 2. 请求验证码并启动倒计时
    Task {
      let result = await viewModel.requestValidateCode(phoneText: phoneText, zoneCode: zoneCode)
      await MainActor.run {
        isWorking = false
        switch result {
        case .success:
          startCountdown(seconds: 60)
        case .failure:
          break
        }
      }
    }
  }

  private func tapLogin() {
    guard agreed else {
      activeAlert = .agreement
      return
    }
    performLogin()
  }

  private func performLogin() {
    // Step 1. 发起登录
    isWorking = true
    Task {
      let result: Result<LoginData, LoginFlowError>
      if isPasswordLogin {
        result = await viewModel.requestPassLogin(
          phoneText: phoneText,
          passwordText: passwordText,
          zoneCode: zoneCode,
          agreementAccepted: agreed
        )
      } else {
        result = await viewModel.requestLogin(
          phoneText: phoneText,
          codeText: codeText,
          zoneCode: zoneCode,
          agreementAccepted: agreed
        )
      }

      await MainActor.run {
        isWorking = false
        switch result {
        case let .success(data):
          // Step 2. 同步写入登录态并跳转首页
          SelfStore.shared.applyLogin(data)
          appNavigation.root = .mainTab(.home)
        case .failure:
          break
        }
      }
    }
  }

  private func startCountdown(seconds: Int) {
    // Step 1. 取消已有倒计时
    countdownTask?.cancel()
    countdownSeconds = seconds

    // Step 2. 启动新倒计时任务
    countdownTask = Task {
      while !Task.isCancelled {
        if countdownSeconds <= 0 { break }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await MainActor.run {
          countdownSeconds = max(0, countdownSeconds - 1)
        }
      }
    }
  }
}
