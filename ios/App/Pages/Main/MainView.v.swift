import SwiftUI

enum MainTab: Hashable {
  case home
}

enum VoicePhase {
  case idle
  case recording
  case reviewing
  case thinking
  case success
}

enum VoiceState {
  case idle
  case recording(transcript: String)
  case reviewing(transcript: String)
  case thinking
  case success(message: String)

  var phase: VoicePhase {
    switch self {
    case .idle:
      return .idle
    case .recording:
      return .recording
    case .reviewing:
      return .reviewing
    case .thinking:
      return .thinking
    case .success:
      return .success
    }
  }

  var transcriptText: String? {
    switch self {
    case .idle, .recording, .reviewing, .thinking:
      return nil
    case let .success(message):
      return message
    }
  }
}

struct MainView: View {
  @State private var selectedTab: MainTab = .home
  @State private var status: VoiceState = .idle
  @StateObject private var realtimeController = VoiceRealtimeCtrl()
  @ObservedObject private var appNavigation = AppNavigationModel.shared

  init(initialTab: MainTab) {
    _selectedTab = State(initialValue: initialTab)
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        Color(hex: "#FDFDFD")
          .ignoresSafeArea()

        ScrollView(showsIndicators: false) {
          VStack(spacing: 18) {
            MascotSectionView(status: status.phase)
              .scaleEffect(0.84)
              .frame(height: 190)
              .padding(.top, 50)

            if let transcript = status.transcriptText {
              Text(transcript)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color.black.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 32)
                .transition(.opacity)
                .accessibilityIdentifier("home_voice_status_text")
            }

            HomeInfoCarouselView {
              appNavigation.push(.pro)
            }

            HomeFunctionGridView { route in
              appNavigation.push(route)
            }
            .padding(.top, 6)

            Spacer(minLength: 128 + proxy.safeAreaInsets.bottom)
          }
          .frame(maxWidth: .infinity)
        }

        LinearGradient(
          colors: [Color.white, Color.white.opacity(0.82), Color.white.opacity(0)],
          startPoint: .bottom,
          endPoint: .top
        )
        .frame(height: 150 + proxy.safeAreaInsets.bottom)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)

        if isInputOverlayActive {
          Color.black.opacity(0.40)
            .ignoresSafeArea()
            .transition(.opacity)
            .allowsHitTesting(false)
        }

        // 底部不允许穿透点击
        Color.clear
          .frame(height: 20 + max(proxy.safeAreaInsets.bottom, 18))
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
          .onTapGesture {}
          .ignoresSafeArea(edges: .bottom)

        VoiceActionView(
          status: status.phase,
          transcriptText: transcriptForInputOverlay,
          onStartRecording: startVoiceRecording,
          onStopRecording: stopVoiceRecordingAndReview,
          onConfirmRecording: confirmRecordedInput,
          onCancelRecording: cancelRecordedInput,
          onTextInput: submitTextInput
        )
        .padding(.bottom, 0)
        .ignoresSafeArea(edges: .bottom)
      }
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("home_main_root")
    }
    .onChange(of: realtimeController.lastErrorMessage, perform: { error in
      guard let error, !error.isEmpty else { return }
      showResult(error, resetDelay: 1.6)
    })
    .onChange(of: realtimeController.recognizedText, perform: { text in
      guard case .recording = status else { return }
      status = .recording(transcript: liveTranscript(from: text))
    })
  }

  private var transcriptForInputOverlay: String {
    switch status {
    case let .recording(transcript), let .reviewing(transcript):
      return transcript
    default:
      return realtimeController.recognizedText
    }
  }

  var isInputOverlayActive: Bool {
    switch status {
    case .recording, .reviewing:
      return true
    default:
      return false
    }
  }

  /// Step 1. 空闲态长按开始请求麦克风并进入录音
  /// Step 2. 连接成功后持续展示实时识别文案
  private func startVoiceRecording() {
    guard case .idle = status else { return }
    status = .recording(transcript: "正在倾听...")
    realtimeController.startListening { success in
      if !success {
        showStartError()
      }
    }
  }

  /// Step 1. 松手后停止录音
  /// Step 2. 进入复核态，不在此处请求后端
  private func stopVoiceRecordingAndReview() {
    guard case .recording = status else { return }
    realtimeController.stopListening { finalText in
      let reviewed = finalText.isEmpty ? "未识别到清晰语音" : finalText
      status = .reviewing(transcript: reviewed)
    }
  }

  private func cancelRecordedInput() {
    guard case .reviewing = status else { return }
    status = .idle
  }

  private func confirmRecordedInput(_ text: String) {
    submitFinalInput(text)
  }

  private func submitTextInput(_ text: String) {
    submitFinalInput(text)
  }

  private func submitFinalInput(_ text: String) {
    status = .thinking
    realtimeController.submitConfirmedInput(text) { output in
      showResult(output, resetDelay: 2.0)
    }
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

  /// Step 1. 延迟回到空闲态
  /// Step 2. 清空提示文案，为下一次录音准备
  private func resetToIdleAfterDelay(_ delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      status = .idle
    }
  }
}
