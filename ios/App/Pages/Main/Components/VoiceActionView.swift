import SwiftUI

struct VoiceActionView: View {
  let status: VoicePhase
  let transcriptText: String
  let onStartRecording: () -> Void
  let onStopRecording: () -> Void
  let onConfirmRecording: (String) -> Void
  let onCancelRecording: () -> Void
  let onTextInput: (String) -> Void

  @State private var isTextInput = false
  @State private var inputValue = ""
  @State private var countdownTrigger = UUID()

  private var isRecording: Bool { status == .recording }
  private var isReviewing: Bool { status == .reviewing }
  private var isThinking: Bool { status == .thinking }
  private var isIdle: Bool { status == .idle }
  private var canSwitchInputMode: Bool { isIdle && !isRecording && !isReviewing }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        if (isRecording || isReviewing) && !isTextInput {
          transcriptPanel
            .padding(.bottom, 30)
            .transition(
              .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .offset(y: 8)),
                removal: .scale(scale: 0.95).combined(with: .opacity)
              )
            )
        }

        if isReviewing {
          reviewActions
            .frame(minHeight: 72)
            .transition(.opacity.combined(with: .scale(scale: 0.90)))
        } else {
          morphInputContainer
            .frame(height: 66)
            .frame(maxWidth: .infinity)
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
        }

        inputModeToggleButton
          .frame(height: 32)
          .padding(.top, 8)
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, 16)
      .padding(.bottom, 4)
    }
    .frame(maxWidth: .infinity)
    .animation(.spring(response: 0.60, dampingFraction: 0.82), value: isTextInput)
    .animation(.spring(response: 0.45, dampingFraction: 0.84), value: status)
    .accessibilityIdentifier("home_voice_interaction_root")
  }

  private var transcriptPanel: some View {
    ScrollViewReader { proxy in
      ScrollView(showsIndicators: false) {
        Text((transcriptText.isEmpty && isRecording) ? "正在倾听..." : (transcriptText.isEmpty ? "..." : transcriptText))
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color.black.opacity(0.80))
          .frame(maxWidth: .infinity, alignment: .leading)
          .lineSpacing(3)
          .id("transcript_text")
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 14)
      .frame(maxWidth: 320)
      .frame(height: 128)
      .background(Color.white.opacity(0.95))
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(Color.black.opacity(0.05), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 6)
      .onChange(of: transcriptText) { _ in
        withAnimation(.easeOut(duration: 0.2)) {
          proxy.scrollTo("transcript_text", anchor: .bottom)
        }
      }
    }
  }

  private var morphInputContainer: some View {
    GeometryReader { geo in
      let expandedWidth = max(geo.size.width - 32, 260)
      let collapsedDiameter: CGFloat = 66
      let width = isTextInput ? expandedWidth : collapsedDiameter

      ZStack {
        if isTextInput {
          RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color.white)
            .overlay(
              RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 22, x: 0, y: 8)
        } else {
          Circle()
            .fill(Color.white)
            .overlay(
              Circle().stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 22, x: 0, y: 8)
        }

        HStack(spacing: 8) {
          TextField("在此输入文字...", text: $inputValue)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Color.black.opacity(0.82))
            .submitLabel(.send)
            .onSubmit(sendText)
            .opacity(isTextInput ? 1 : 0)

          Button(action: sendText) {
            Text("发送")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 8)
              .background(Color.black.opacity(canSendText ? 1 : 0.30))
              .clipShape(Capsule(style: .continuous))
          }
          .disabled(!canSendText || !isTextInput)
          .opacity(isTextInput ? 1 : 0)
        }
        .padding(.horizontal, 16)
        .allowsHitTesting(isTextInput)

        collapsedMicLayer
          .opacity(isTextInput ? 0 : 1)
          .allowsHitTesting(!isTextInput)
      }
      .frame(width: width, height: collapsedDiameter)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .gesture(recordGesture)
      .allowsHitTesting(isTextInput ? isIdle : (status == .idle || isRecording))
      .accessibilityIdentifier("home_voice_mic_button")
      .animation(.spring(response: 0.45, dampingFraction: 0.84), value: width)
      .overlay(
        Group {
          if isRecording {
            CountdownRingView(trigger: countdownTrigger)
              .frame(width: 66, height: 66)
          }
        }
      )
    }
  }

  private var reviewActions: some View {
    HStack(spacing: 32) {
      Button {
        onCancelRecording()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(Color.black.opacity(0.55))
          .frame(width: 56, height: 56)
          .background(Color.white.opacity(0.82))
          .clipShape(Circle())
          .overlay(
            Circle().stroke(Color.black.opacity(0.10), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)

      Button {
        onConfirmRecording(cleanTranscriptForSubmit)
      } label: {
        Text("发送")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 144, height: 56)
          .background(Color.black.opacity(0.92))
          .clipShape(Capsule(style: .continuous))
      }
      .buttonStyle(.plain)
      .disabled(cleanTranscriptForSubmit.isEmpty)
      .opacity(cleanTranscriptForSubmit.isEmpty ? 0.55 : 1)
    }
  }

  private var micSymbolName: String {
    isThinking ? "hourglass" : "mic.fill"
  }

  private var inputModeToggleButton: some View {
    Button {
      guard canSwitchInputMode else { return }
      isTextInput.toggle()
    } label: {
      Text(isTextInput ? "返回语音输入" : "文字输入")
        .font(.system(size: 13, weight: .black))
        .foregroundColor(Color.black.opacity(canSwitchInputMode ? 0.45 : 0.22))
        .tracking(1.4)
        .opacity(canSwitchInputMode ? 1 : 0)
    }
    .buttonStyle(.plain)
    .disabled(!canSwitchInputMode)
    .allowsHitTesting(canSwitchInputMode)
    .animation(.easeInOut(duration: 0.18), value: isTextInput)
  }

  private var recordingCountdownLabel: some View {
    Text("15")
      .font(.system(size: 17, weight: .bold))
      .foregroundColor(Color.black.opacity(0.82))
  }

  private var collapsedMicLayer: some View {
    ZStack {
      if isRecording {
        recordingCountdownLabel
      } else {
        Image(systemName: micSymbolName)
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(Color.black.opacity(0.70))
          .symbolRenderingMode(.hierarchical)
      }
    }
  }

  private var recordGesture: some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { _ in
        guard !isRecording, status == .idle, !isTextInput else { return }
        countdownTrigger = UUID()
        onStartRecording()
      }
      .onEnded { _ in
        guard isRecording else { return }
        onStopRecording()
      }
  }

  private var canSendText: Bool {
    !inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var cleanTranscriptForSubmit: String {
    let text = transcriptText.trimmingCharacters(in: .whitespacesAndNewlines)
    return text == "未识别到清晰语音" ? "" : text
  }

  private func sendText() {
    let text = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    inputValue = ""
    isTextInput = false
    onTextInput(text)
  }
}

private struct CountdownRingView: View {
  let trigger: UUID
  @State private var animate = false

  var body: some View {
    ZStack {
      Circle()
        .stroke(Color.black.opacity(0.08), lineWidth: 4)
      Circle()
        .trim(from: 0, to: animate ? 1 : 0)
        .stroke(
          Color(hex: "#F472B6"),
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 15), value: animate)
    }
    .onAppear {
      animate = false
      DispatchQueue.main.async {
        animate = true
      }
    }
    .onChange(of: trigger) { _ in
      animate = false
      DispatchQueue.main.async {
        animate = true
      }
    }
  }
}
