import SwiftUI

enum MainTab: Hashable {
  case home
}

enum VoicePhase {
  case idle
  case listening
  case thinking
  case success
}

enum VoiceThinkingReason {
  case connecting
  case summarizing
}

enum VoiceState {
  case idle
  case listening(transcript: String)
  case thinking(VoiceThinkingReason)
  case success(message: String)

  var phase: VoicePhase {
    switch self {
    case .idle:
      return .idle
    case .listening:
      return .listening
    case .thinking:
      return .thinking
    case .success:
      return .success
    }
  }

  var transcriptText: String? {
    switch self {
    case .idle:
      return nil
    case let .listening(transcript):
      return transcript
    case let .thinking(reason):
      return reason == .connecting ? "正在连接语音服务..." : "已停止录音，正在汇总识别结果..."
    case let .success(message):
      return message
    }
  }
}

struct MainView: View {
  @State private var selectedTab: MainTab = .home
  @State private var status: VoiceState = .idle
  @StateObject private var realtimeController = VoiceRealtimeCtrl()
  @State private var simulatorInput: String = ""

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
            MascotSectionView(status: status.phase)
          }
          .frame(height: proxy.size.height * 0.40)
          .frame(maxWidth: .infinity, alignment: .bottom)
          .padding(.bottom, 18)

          VStack(spacing: 0) {
            if let transcript = status.transcriptText {
              Text(transcript)
                .font(.system(size: 26, weight: .light))
                .foregroundColor(Color.black.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 24)
                .transition(.opacity)
                .accessibilityIdentifier("home_voice_status_text")
            }

            #if targetEnvironment(simulator)
              VStack(spacing: 10) {
                TextField("模拟输入文本（替代语音）", text: $simulatorInput)
                  .textFieldStyle(.roundedBorder)
                  .font(.system(size: 14))
                  .accessibilityIdentifier("home_simulator_input")
                Button(action: submitSimulatorInput) {
                  Text("提交模拟输入")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.78))
                    .cornerRadius(8)
                }
                .accessibilityIdentifier("home_simulator_submit")
              }
              .padding(.top, 16)
            #endif
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
          .padding(.horizontal, 32)

          VoiceActionView(
            status: status.phase,
            onTap: toggleInteraction
          )
          .frame(height: proxy.size.height * 0.22)
          .padding(.bottom, 12)
        }
      }
      .animation(.easeInOut(duration: 0.25), value: status.phase)
      .accessibilityIdentifier("home_main_root")
    }
    .onChange(of: realtimeController.lastErrorMessage, perform: { error in
      guard let error, !error.isEmpty else { return }
      showResult(error, resetDelay: 1.6)
    })
    .onChange(of: realtimeController.recognizedText, perform: { text in
      guard case .listening = status else { return }
      status = .listening(transcript: liveTranscript(from: text))
    })
  }

  // Step 1. 空闲态点击后请求麦克风并真实开始录音
  // Step 2. 录音中再次点击则停止录音并进入过渡状态
  private func toggleInteraction() {
    switch status {
    case .idle:
      startVoiceFlow()
    case .listening:
      stopVoiceFlow()
    default:
      break
    }
  }

  // Step 1. 进入连接阶段并发起实时识别
  // Step 2. 根据结果切换到监听态或失败态
  private func startVoiceFlow() {
    status = .thinking(.connecting)
    realtimeController.startListening { success in
      success ? showListening() : showStartError()
    }
  }

  // Step 1. 从监听态进入汇总阶段
  // Step 2. 展示最终识别结果并回到空闲态
  private func stopVoiceFlow() {
    status = .thinking(.summarizing)
    realtimeController.stopListening { finalText in
      showResult(finalText.isEmpty ? "未识别到清晰语音" : finalText, resetDelay: 1.8)
    }
  }

  private func submitSimulatorInput() {
    status = .thinking(.summarizing)
    realtimeController.processTextInputForTesting(simulatorInput) { output in
      showResult(output, resetDelay: 2.0)
    }
  }

  private func showListening() {
    status = .listening(transcript: "正在实时识别...")
  }

  private func showStartError() {
    showResult(realtimeController.lastErrorMessage ?? "语音识别启动失败", resetDelay: 2.0)
  }

  private func showResult(_ text: String, resetDelay: TimeInterval) {
    status = .success(message: text)
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
    }
  }
}
