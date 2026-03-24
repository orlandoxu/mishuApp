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
  @StateObject private var recorder = HomeVoiceRecorder()

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
            CuteMascotView(status: status)
            StatusTextView(status: status)
              .padding(.top, -8)
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
            level: recorder.normalizedPower,
            onTap: toggleInteraction
          )
          .frame(height: proxy.size.height * 0.22)
          .padding(.bottom, 12)
        }
      }
      .animation(.easeInOut(duration: 0.25), value: status)
      .accessibilityIdentifier("home_main_root")
    }
    .onChange(of: recorder.lastErrorMessage) { error in
      guard let error, !error.isEmpty else { return }
      transcript = error
      status = .success
      resetToIdleAfterDelay(1.6)
    }
  }

  private var shouldShowTranscript: Bool {
    status == .listening || status == .thinking || status == .success
  }

  // Step 1. 空闲态点击后请求麦克风并真实开始录音
  // Step 2. 录音中再次点击则停止录音并进入过渡状态
  private func toggleInteraction() {
    if status == .idle {
      transcript = "正在启动录音..."
      recorder.startRecording { success in
        if success {
          status = .listening
          transcript = "正在录音，点击按钮结束"
        } else if recorder.permissionDenied {
          status = .success
          transcript = "麦克风权限未开启，请到系统设置中允许访问"
          resetToIdleAfterDelay(2.0)
        } else {
          status = .success
          transcript = recorder.lastErrorMessage ?? "录音启动失败"
          resetToIdleAfterDelay(1.6)
        }
      }
      return
    }

    if status == .listening {
      let url = recorder.stopRecording()
      status = .thinking
      transcript = "录音已结束，正在处理语音..."

      DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
        status = .success
        if let url {
          transcript = "录音完成：\(url.lastPathComponent)"
        } else {
          transcript = "录音已结束"
        }
        resetToIdleAfterDelay(1.5)
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

private struct StatusTextView: View {
  let status: HomeVoiceStatus

  private var text: String {
    switch status {
    case .listening:
      return "Aura 正在认真听你说..."
    case .thinking:
      return "Aura 正在努力思考中..."
    case .success:
      return "处理完成啦！"
    case .idle:
      return "Aura 有很多功能需要你探索哟"
    }
  }

  var body: some View {
    Text(text)
      .font(.system(size: 15, weight: .medium))
      .foregroundColor(Color.black.opacity(0.60))
      .tracking(0.2)
      .multilineTextAlignment(.center)
      .padding(.horizontal, 20)
      .accessibilityIdentifier("home_mascot_status_text")
  }
}

private struct CuteMascotView: View {
  let status: HomeVoiceStatus

  @State private var floating = false
  @State private var blink = false

  var body: some View {
    ZStack {
      Ellipse()
        .fill(Color.black.opacity(status == .listening ? 0.13 : 0.10))
        .frame(width: 70, height: 12)
        .offset(y: 74)
        .scaleEffect(status == .listening ? 1.10 : 1.0)

      ZStack {
        RoundedRectangle(cornerRadius: 35, style: .continuous)
          .fill(Color.white)
          .frame(width: 120, height: 95)
          .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)

        Capsule()
          .fill(Color(hex: "#E2E8F0"))
          .frame(width: 4, height: 16)
          .offset(y: -54)

        Circle()
          .fill(antennaColor)
          .frame(width: 12, height: 12)
          .offset(y: -64)

        Group {
          Circle()
            .fill(Color(hex: "#FFB6C1").opacity(blushOpacity))
            .frame(width: 18, height: 18)
            .offset(x: -35, y: 8)

          Circle()
            .fill(Color(hex: "#FFB6C1").opacity(blushOpacity))
            .frame(width: 18, height: 18)
            .offset(x: 35, y: 8)
        }
        .scaleEffect(status == .success ? 1.10 : 1.0)

        if status == .success {
          Group {
            Path { path in
              path.move(to: CGPoint(x: 47, y: 44))
              path.addQuadCurve(to: CGPoint(x: 63, y: 44), control: CGPoint(x: 55, y: 34))
            }
            .stroke(Color(hex: "#2D3436"), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))

            Path { path in
              path.move(to: CGPoint(x: 97, y: 44))
              path.addQuadCurve(to: CGPoint(x: 113, y: 44), control: CGPoint(x: 105, y: 34))
            }
            .stroke(Color(hex: "#2D3436"), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
          }
          .offset(y: -10)
        } else {
          Group {
            EyeView(blink: blink)
              .offset(x: -25, y: -8)
            EyeView(blink: blink)
              .offset(x: 25, y: -8)
          }
        }

        MouthView(status: status)
          .offset(y: 18)
      }
      .offset(y: -6)
      .offset(y: floating ? -3 : 3)
      .animation(
        .easeInOut(duration: status == .success ? 1.0 : 1.5)
          .repeatForever(autoreverses: true),
        value: floating
      )
    }
    .frame(width: 192, height: 192)
    .onAppear {
      floating = true
      startBlinkLoop()
    }
    .accessibilityIdentifier("home_mascot")
  }

  private var antennaColor: Color {
    switch status {
    case .listening:
      return Color(hex: "#FF6B6B")
    case .thinking:
      return Color(hex: "#4ECDC4")
    case .success:
      return Color(hex: "#51CF66")
    case .idle:
      return Color(hex: "#FFD93D")
    }
  }

  private var blushOpacity: Double {
    switch status {
    case .listening:
      return 0.70
    case .success:
      return 0.90
    default:
      return 0.15
    }
  }

  // Step 1. 通过定时轮询模拟网页版眨眼节奏
  // Step 2. 避免使用 iOS 15+ API，兼容 iOS 14
  private func startBlinkLoop() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
      blink = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
        blink = false
        startBlinkLoop()
      }
    }
  }
}

private struct EyeView: View {
  let blink: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(Color(hex: "#2D3436"))
        .frame(width: 15, height: 15)
      Circle()
        .fill(Color.white)
        .frame(width: 5, height: 5)
        .offset(x: 2, y: -2)
    }
    .scaleEffect(x: 1, y: blink ? 0.12 : 1)
    .animation(.easeInOut(duration: 0.08), value: blink)
  }
}

private struct MouthView: View {
  let status: HomeVoiceStatus

  var body: some View {
    Path { path in
      switch status {
      case .listening:
        path.move(to: CGPoint(x: 72, y: 82))
        path.addQuadCurve(to: CGPoint(x: 88, y: 82), control: CGPoint(x: 80, y: 92))
      case .success:
        path.move(to: CGPoint(x: 70, y: 82))
        path.addQuadCurve(to: CGPoint(x: 90, y: 82), control: CGPoint(x: 80, y: 94))
      default:
        path.move(to: CGPoint(x: 75, y: 85))
        path.addQuadCurve(to: CGPoint(x: 85, y: 85), control: CGPoint(x: 80, y: 89))
      }
    }
    .stroke(Color(hex: "#2D3436"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    .frame(width: 160, height: 160)
    .animation(.easeInOut(duration: 0.5), value: status)
  }
}
