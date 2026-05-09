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
    }
  }
}

struct MainView: View {
  @State private var selectedTab: MainTab = .home
  @State private var status: VoiceState = .idle
  @State private var messages: [TreeHoleChatMessage] = []
  @StateObject private var realtimeController = VoiceRealtimeCtrl()
  @ObservedObject private var appNavigation = AppNavigationModel.shared

  init(initialTab: MainTab) {
    _selectedTab = State(initialValue: initialTab)
  }

  private var hasActiveConversation: Bool {
    !messages.isEmpty
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottom) {
        Color(hex: "#FDFDFD")
          .ignoresSafeArea()

        ScrollView(showsIndicators: false) {
          VStack(spacing: 18) {
            if hasActiveConversation {
              HomeConversationHeaderView(
                status: status.phase,
                onNewTask: resetConversation
              )
              .padding(.top, 12)
            } else {
              MascotSectionView(status: status.phase)
                .scaleEffect(0.84)
                .frame(height: 190)
                .padding(.top, 50)
            }

            if hasActiveConversation {
              HomeConversationListView(messages: messages)
            } else {
              HomeInfoCarouselView {
                appNavigation.push(.pro)
              }

              HomeFunctionGridView { route in
                appNavigation.push(route)
              }
              .padding(.top, 6)
            }

            Spacer(minLength: 128 + proxy.safeAreaInsets.bottom)
          }
          .frame(maxWidth: .infinity)
        }

        LinearGradient(
          colors: [Color.white, Color.white.opacity(0.82), Color.white.opacity(0)],
          startPoint: .bottom,
          endPoint: .top
        )
        .ignoresSafeArea(edges: .bottom)
        .frame(height: 150 + proxy.safeAreaInsets.bottom)
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
      let reviewed = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !reviewed.isEmpty else {
        status = .idle
        return
      }
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
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    status = .thinking
    messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-user", role: .user, text: trimmed))
    Task {
      let reply: String
      do {
        reply = try await realtimeController.requestReply(for: trimmed)
      } catch {
        reply = "指令下发失败：\(error.localizedDescription)"
      }
      await MainActor.run {
        messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-ai", role: .ai, text: reply))
        status = .idle
      }
    }
  }

  private func showStartError() {
    let errorText = realtimeController.lastErrorMessage ?? "语音识别启动失败"
    messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-ai", role: .ai, text: errorText))
    status = .idle
  }

  private func resetConversation() {
    messages.removeAll()
    status = .idle
  }

  private func liveTranscript(from text: String) -> String {
    text.isEmpty ? "正在实时识别..." : text
  }

}

private struct HomeConversationListView: View {
  let messages: [TreeHoleChatMessage]

  var body: some View {
    VStack(spacing: 18) {
      ForEach(messages) { message in
        TreeHoleChatBubble(message: message, maxBubbleWidth: 268)
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 8)
  }
}

private struct HomeConversationHeaderView: View {
  let status: VoicePhase
  let onNewTask: () -> Void

  private var statusText: String {
    switch status {
    case .recording:
      return "正在聆听..."
    case .thinking:
      return "思考中..."
    default:
      return "在线"
    }
  }

  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      HStack(spacing: 8) {
        MascotSectionView(status: status)
          .scaleEffect(0.28)
          .frame(width: 54, height: 54)
        VStack(alignment: .leading, spacing: 2) {
          Text("Aura")
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(Color.black.opacity(0.80))
          Text(statusText)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.black.opacity(0.30))
        }
      }

      Spacer(minLength: 12)

      Button(action: onNewTask) {
        Text("新任务")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Color.black.opacity(0.78))
          .padding(.horizontal, 14)
          .padding(.vertical, 9)
          .background(Color.white.opacity(0.95))
          .clipShape(Capsule())
          .overlay(
            Capsule()
              .stroke(Color.black.opacity(0.08), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 24)
    .frame(maxWidth: .infinity)
  }
}
