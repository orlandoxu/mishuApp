import SwiftUI

enum MainTab: Hashable {
  case home
}

enum HomeVoiceStatus {
  case idle
  case listening
  case thinking
  case success
}

struct MainTabView: View {
  @State private var selectedTab: MainTab = .home
  @State private var status: HomeVoiceStatus = .idle
  @State private var transcript: String = ""
  @StateObject private var realtimeController = HomeVoiceRealtimeController()

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
            HomeMascotSectionView(status: status)
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

          HomeVoiceInteractionView(
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
      transcript = error
      status = .success
      resetToIdleAfterDelay(1.6)
    })
    .onChange(of: realtimeController.recognizedText, perform: { text in
      guard status == .listening else { return }
      let normalized = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      if normalized.isEmpty {
        transcript = "正在实时识别..."
      } else {
        transcript = normalized
      }
    })
  }

  private var shouldShowTranscript: Bool {
    status == .listening || status == .thinking || status == .success
  }

  // Step 1. 空闲态点击后请求麦克风并真实开始录音
  // Step 2. 录音中再次点击则停止录音并进入过渡状态
  private func toggleInteraction() {
    if status == .idle {
      status = .thinking
      transcript = "正在连接语音服务..."
      realtimeController.startListening { success in
        if success {
          status = .listening
          transcript = "正在实时识别..."
        } else {
          status = .success
          transcript = realtimeController.lastErrorMessage ?? "语音识别启动失败"
          resetToIdleAfterDelay(2.0)
        }
      }
      return
    }

    if status == .listening {
      status = .thinking
      transcript = "已停止录音，正在汇总识别结果..."
      realtimeController.stopListening { finalText in
        status = .success
        if finalText.isEmpty {
          transcript = "未识别到清晰语音"
        } else {
          transcript = finalText
        }
        resetToIdleAfterDelay(1.8)
      }
    }
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
