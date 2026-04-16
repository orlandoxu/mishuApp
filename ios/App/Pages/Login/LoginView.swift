import SwiftUI

struct LoginView: View {
  private enum ActiveAlert: Identifiable {
    case message(String)

    var id: String {
      switch self {
      case let .message(message):
        return "message:\(message)"
      }
    }
  }

  @State private var zoneCode: String = "+86"
  @State private var phoneText: String = ""
  @State private var codeText: String = ""
  @State private var agreed: Bool = false
  @State private var countdownSeconds: Int = 0
  @State private var isWorking: Bool = false
  @State private var shakeAgreement: Bool = false
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

      VStack(spacing: 0) {
        Spacer(minLength: 34)

        LoginLogoView()
          .padding(.bottom, 42)

        VStack(spacing: 26) {
          LoginInputView(
            phoneText: $phoneText,
            codeText: $codeText,
            countdownSeconds: countdownSeconds,
            canGetCode: canGetCode,
            isWorking: isWorking,
            onTapGetCode: tapGetCode
          )

          LoginActionView(
            canLogin: canLogin,
            isWorking: isWorking,
            onTapLogin: tapLogin,
            onTapWeChatLogin: tapWeChatLogin
          )
        }
        .padding(.horizontal, 25)

        Spacer(minLength: 46)

        LoginAgreementView(agreed: $agreed, shake: shakeAgreement)
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 18)
      .padding(.bottom, 16)
    }
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .alert(item: $activeAlert) { item in
      switch item {
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
    codeValue.count == 6
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
        case let .failure(error):
          activeAlert = .message(error.userMessage)
        }
      }
    }
  }

  private func tapLogin() {
    guard agreed else {
      triggerAgreementShake()
      return
    }
    performLogin()
  }

  private func tapWeChatLogin() {
    guard agreed else {
      triggerAgreementShake()
      return
    }
    activeAlert = .message("微信登录开发中，请先使用手机号登录")
  }

  private func triggerAgreementShake() {
    withAnimation(.easeInOut(duration: 0.1)) {
      shakeAgreement = true
    }
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 420_000_000)
      shakeAgreement = false
    }
  }

  private func performLogin() {
    // Step 1. 发起登录
    isWorking = true
    Task {
      let result = await viewModel.requestLogin(
        phoneText: phoneText,
        codeText: codeText,
        zoneCode: zoneCode,
        agreementAccepted: agreed
      )

      await MainActor.run {
        isWorking = false
        switch result {
        case let .success(data):
          // Step 2. 同步写入登录态并跳转首页
          SelfStore.shared.applyLogin(data)
          appNavigation.root = .mainTab(.home)
        case let .failure(error):
          activeAlert = .message(error.userMessage)
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
