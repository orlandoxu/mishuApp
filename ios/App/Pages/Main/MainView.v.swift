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
  @Namespace private var mascotHeroNamespace
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

        if hasActiveConversation {
          VStack(spacing: 0) {
            HomeTopSectionView(
              status: status.phase,
              hasActiveConversation: true,
              mascotHeroNamespace: mascotHeroNamespace,
              onNewTask: resetConversation
            )

            ScrollView(showsIndicators: false) {
              VStack(spacing: 18) {
                HomeConversationListView(
                  messages: messages,
                  onConfirm: { submitFinalInput("confirm") },
                  onDeny: { submitFinalInput("cancel") }
                )
                Spacer(minLength: 128 + proxy.safeAreaInsets.bottom)
              }
              .frame(maxWidth: .infinity)
            }
          }
        } else {
          ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
              HomeTopSectionView(
                status: status.phase,
                hasActiveConversation: false,
                mascotHeroNamespace: mascotHeroNamespace,
                onNewTask: resetConversation
              )

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
    .onReceive(NotificationCenter.default.publisher(for: .homeQuickTextInput)) { notification in
      guard let text = notification.userInfo?["text"] as? String else { return }
      submitFinalInput(text)
    }
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

  private func startVoiceRecording() {
    guard case .idle = status else { return }
    status = .recording(transcript: "正在倾听...")
    realtimeController.startListening { success in
      if !success {
        showStartError()
      }
    }
  }

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
    withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
      messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-user", role: .user, text: trimmed))
    }

    Task {
      let reply: String
      do {
        reply = try await realtimeController.requestReply(for: trimmed)
      } catch {
        reply = "指令下发失败：\(error.localizedDescription)"
      }
      await MainActor.run {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
          messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-ai", role: .ai, text: reply))
        }
        status = .idle
      }
    }
  }

  private func showStartError() {
    let errorText = realtimeController.lastErrorMessage ?? "语音识别启动失败"
    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
      messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-ai", role: .ai, text: errorText))
    }
    status = .idle
  }

  private func resetConversation() {
    withAnimation(.spring(response: 0.44, dampingFraction: 0.86)) {
      messages.removeAll()
    }
    status = .idle
  }

  private func liveTranscript(from text: String) -> String {
    text.isEmpty ? "正在实时识别..." : text
  }
}

extension Notification.Name {
  static let homeQuickTextInput = Notification.Name("homeQuickTextInput")
}

private struct HomeTopSectionView: View {
  let status: VoicePhase
  let hasActiveConversation: Bool
  let mascotHeroNamespace: Namespace.ID
  let onNewTask: () -> Void

  var body: some View {
    ZStack(alignment: .topLeading) {
      if !hasActiveConversation {
        VStack(spacing: 0) {
          MascotSectionView(status: status)
            .matchedGeometryEffect(id: "home_mascot_hero", in: mascotHeroNamespace)
            .scaleEffect(0.84)
            .frame(height: 190)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
      } else {
        HStack(alignment: .center, spacing: 0) {
          HStack(spacing: 8) {
            MascotSectionView(status: status)
              .matchedGeometryEffect(id: "home_mascot_hero", in: mascotHeroNamespace)
              .scaleEffect(0.31)
              .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 2) {
              Text("Aura")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.black.opacity(0.80))
              Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.black.opacity(0.30))
            }
          }

          Spacer(minLength: 12)

          Button(action: onNewTask) {
            HStack(spacing: 4) {
              Image(systemName: "plus")
                .font(.system(size: 11, weight: .bold))
              Text("新任务")
                .font(.system(size: 14, weight: .bold))
            }
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
        .padding(.top, 18)
        .frame(maxWidth: .infinity)
      }
    }
    .animation(.spring(response: 0.50, dampingFraction: 0.86), value: hasActiveConversation)
  }

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
}

private struct HomeConversationListView: View {
  let messages: [TreeHoleChatMessage]
  let onConfirm: () -> Void
  let onDeny: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      ForEach(messages) { message in
        HomeConversationBubbleRow(message: message)
      }
      if shouldShowConfirmActions {
        HStack(spacing: 10) {
          Button("确认记账", action: onConfirm)
            .buttonStyle(HomeQuickActionButtonStyle(background: Color(hex: "#E8F9EE"), foreground: Color(hex: "#137A3B")))
            .accessibilityIdentifier("home_confirm_action")
          Button("我再改改", action: onDeny)
            .buttonStyle(HomeQuickActionButtonStyle(background: Color(hex: "#F8F9FB"), foreground: Color.black.opacity(0.75)))
            .accessibilityIdentifier("home_deny_action")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  private var shouldShowConfirmActions: Bool {
    guard let last = messages.last, last.role == .ai else { return false }
    return last.text.contains("确认记一笔")
  }
}

private struct HomeConversationBubbleRow: View {
  let message: TreeHoleChatMessage

  var body: some View {
    HStack {
      if message.role == .user { Spacer(minLength: 34) }

      Text(message.text)
        .font(.system(size: 16, weight: .regular))
        .foregroundColor(message.role == .user ? Color(hex: "#082F49") : Color.black.opacity(0.80))
        .lineSpacing(4.5)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 22)
        .padding(.vertical, 13)
        .background(bubbleBackground)
        .clipShape(HomeChatBubbleShape(role: message.role, radius: 24))
        .overlay(
          HomeChatBubbleShape(role: message.role, radius: 24)
            .stroke(bubbleBorder, lineWidth: 1)
        )
        .frame(maxWidth: 306, alignment: message.role == .user ? .trailing : .leading)

      if message.role == .ai { Spacer(minLength: 34) }
    }
    .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
  }

  private var bubbleBackground: Color {
    message.role == .user ? Color(hex: "#F0F9FF") : .white
  }

  private var bubbleBorder: Color {
    message.role == .user ? Color(hex: "#E0F2FE") : Color.black.opacity(0.05)
  }
}

private struct HomeChatBubbleShape: Shape {
  let role: TreeHoleChatMessage.Role
  let radius: CGFloat

  func path(in rect: CGRect) -> Path {
    let corners: UIRectCorner = role == .user
      ? [.topLeft, .bottomLeft, .bottomRight]
      : [.topRight, .bottomLeft, .bottomRight]
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: radius, height: radius)
    )
    return Path(path.cgPath)
  }
}

private struct HomeQuickActionButtonStyle: ButtonStyle {
  let background: Color
  let foreground: Color

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.system(size: 14, weight: .semibold))
      .foregroundColor(foreground)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(background.opacity(configuration.isPressed ? 0.7 : 1))
      .clipShape(Capsule())
      .overlay(
        Capsule().stroke(Color.black.opacity(0.08), lineWidth: 1)
      )
  }
}
