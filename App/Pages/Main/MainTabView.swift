import SwiftUI

enum MainTab: Hashable {
  case home
}

enum VoiceState {
  case idle
  case listening
  case thinking
  case success
}

struct MainView: View {
  @State private var selectedTab: MainTab = .home
  @State private var status: VoiceState = .idle
  @State private var transcript: String = ""
  @StateObject private var realtimeController = VoiceRealtimeCtrl()

  init(initialTab: MainTab) {
    _selectedTab = State(initialValue: initialTab)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        Color(hex: "#FAFAFC")
          .ignoresSafeArea()

        VStack(spacing: 0) {
          VStack(spacing: 0) {
            MascotSectionView(status: status)
          }
          .frame(height: proxy.size.height * 0.40)
          .frame(maxWidth: .infinity, alignment: .bottom)
          .padding(.bottom, 18)

          VStack(spacing: 0) {
            if shouldShowTranscript {
              Text(transcript)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Color.black.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 24)
                .transition(.opacity)
                .accessibilityIdentifier("home_voice_status_text")
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
          .padding(.horizontal, 32)

          VoiceActionView(
            status: status,
            level: realtimeController.audioLevel,
            onTap: toggleInteraction
          )
          .frame(height: proxy.size.height * 0.22)
          .padding(.bottom, 12)
        }
      }
      .animation(.easeInOut(duration: 0.25), value: status)
      .accessibilityIdentifier("home_main_root")
    }
    .onChange(of: realtimeController.lastErrorMessage, perform: { error in
      guard let error, !error.isEmpty else { return }
      showResult(error, resetDelay: 1.6)
    })
    .onChange(of: realtimeController.recognizedText, perform: { text in
      guard status == .listening else { return }
      transcript = liveTranscript(from: text)
    })
  }

  private var shouldShowTranscript: Bool {
    status == .listening || status == .thinking || status == .success
  }

  // Step 1. 空闲态点击后请求麦克风并真实开始录音
  // Step 2. 录音中再次点击则停止录音并进入过渡状态
  private func toggleInteraction() {
    guard status == .idle || status == .listening else { return }
    status == .idle ? startVoiceFlow() : stopVoiceFlow()
  }

  // Step 1. 进入连接阶段并发起实时识别
  // Step 2. 根据结果切换到监听态或失败态
  private func startVoiceFlow() {
    status = .thinking
    transcript = "正在连接语音服务..."
    realtimeController.startListening { success in
      success ? showListening() : showStartError()
    }
  }

  // Step 1. 从监听态进入汇总阶段
  // Step 2. 展示最终识别结果并回到空闲态
  private func stopVoiceFlow() {
    status = .thinking
    transcript = "已停止录音，正在汇总识别结果..."
    realtimeController.stopListening { finalText in
      showResult(finalText.isEmpty ? "未识别到清晰语音" : finalText, resetDelay: 1.8)
    }
  }

  private func showListening() {
    status = .listening
    transcript = "正在实时识别..."
  }

  private func showStartError() {
    showResult(realtimeController.lastErrorMessage ?? "语音识别启动失败", resetDelay: 2.0)
  }

  private func showResult(_ text: String, resetDelay: TimeInterval) {
    status = .success
    transcript = text
    resetToIdleAfterDelay(resetDelay)
  }

  private func liveTranscript(from text: String) -> String {
    text.isEmpty ? "正在实时识别..." : text
  }

  // Step 1. 延迟回到空闲态
  // Step 2. 清空提示文案，为下一次录音准备
  private func resetToIdleAfterDelay(_ delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      status = .idle
      transcript = ""
    }
  }
}
