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
            if status == .listening {
              Text(transcript.isEmpty ? "请说，我在听..." : transcript)
                .font(.system(size: 30, weight: .light))
                .foregroundColor(Color.black.opacity(0.80))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 24)
                .transition(.opacity)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
          .padding(.horizontal, 32)

          VoiceInputButtonView(status: status, onTap: toggleInteraction)
            .frame(height: proxy.size.height * 0.20)
            .padding(.bottom, 18)
        }

        RoundedRectangle(cornerRadius: 999)
          .fill(Color.black.opacity(0.06))
          .frame(width: 128, height: 5)
          .padding(.bottom, 7)
      }
      .animation(.easeInOut(duration: 0.25), value: status)
    }
  }

  // Step 1. 处理语音按钮点击（先按 UI 原型切换监听状态）
  // Step 2. 保持文案和状态动画一致
  private func toggleInteraction() {
    if status == .idle {
      status = .listening
      transcript = "正在聆听..."
      return
    }

    status = .idle
    transcript = ""
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

      if status == .thinking {
        ForEach(0..<4) { index in
          SparkleDotView(delay: Double(index) * 0.25)
        }
      }
    }
    .frame(width: 192, height: 192)
    .onAppear {
      floating = true
      startBlinkLoop()
    }
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

private struct SparkleDotView: View {
  let delay: Double
  @State private var animate = false

  var body: some View {
    Circle()
      .fill(Color(hex: "#4ECDC4").opacity(0.55))
      .frame(width: 10, height: 10)
      .offset(x: animate ? CGFloat((delay * 30) - 25) : 0, y: animate ? -55 : -20)
      .opacity(animate ? 0 : 1)
      .scaleEffect(animate ? 0.5 : 1.1)
      .onAppear {
        withAnimation(.easeInOut(duration: 1.8).delay(delay).repeatForever(autoreverses: false)) {
          animate = true
        }
      }
  }
}

private struct VoiceInputButtonView: View {
  let status: HomeVoiceStatus
  let onTap: () -> Void

  @State private var wavePhase: CGFloat = 0
  @State private var ringPulse = false

  private var isActive: Bool {
    status != .idle
  }

  var body: some View {
    ZStack {
      if status == .listening {
        VStack(spacing: 8) {
          WaveLine(amplitude: 12, phase: wavePhase)
            .stroke(Color.black.opacity(0.90), lineWidth: 2)
            .frame(width: 300, height: 34)
          WaveLine(amplitude: 8, phase: wavePhase + 1.2)
            .stroke(Color.black.opacity(0.55), lineWidth: 1.5)
            .frame(width: 300, height: 24)
        }
        .transition(.opacity)
      }

      if status == .thinking {
        HStack(spacing: 8) {
          ForEach(0..<3) { idx in
            ThinkingDot(delay: Double(idx) * 0.2)
          }
        }
      }

      Button(action: onTap) {
        ZStack {
          Circle()
            .fill(isActive ? Color.black.opacity(0.05) : Color.white)
            .frame(width: isActive ? 56 : 64, height: isActive ? 56 : 64)
            .overlay(
              Circle()
                .stroke(Color.black.opacity(isActive ? 0.0 : 0.05), lineWidth: 1)
            )
            .shadow(color: isActive ? .clear : Color.black.opacity(0.16), radius: 20, x: 0, y: 8)

          if status == .idle {
            MicIcon()
              .fill(Color.black.opacity(0.60))
              .frame(width: 20, height: 24)
          } else {
            RoundedRectangle(cornerRadius: 2)
              .fill(Color.black.opacity(0.62))
              .frame(width: 16, height: 16)
          }

          if status == .idle {
            Circle()
              .stroke(Color.black.opacity(0.10), lineWidth: 1)
              .frame(width: 64, height: 64)
              .scaleEffect(ringPulse ? 1.40 : 1.0)
              .opacity(ringPulse ? 0.0 : 0.15)
          }
        }
      }
      .buttonStyle(PlainButtonStyle())
      .offset(y: 48)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 190)
    .onAppear {
      withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
        wavePhase = .pi * 2
      }
      withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: false)) {
        ringPulse = true
      }
    }
  }
}

private struct ThinkingDot: View {
  let delay: Double
  @State private var animate = false

  var body: some View {
    Circle()
      .fill(Color.black)
      .frame(width: 12, height: 12)
      .offset(y: animate ? 5 : -5)
      .opacity(animate ? 0.3 : 1.0)
      .onAppear {
        withAnimation(.easeInOut(duration: 1.5).delay(delay).repeatForever(autoreverses: true)) {
          animate = true
        }
      }
  }
}

private struct WaveLine: Shape {
  var amplitude: CGFloat
  var phase: CGFloat

  var animatableData: CGFloat {
    get { phase }
    set { phase = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let midY = rect.midY
    let width = rect.width

    path.move(to: CGPoint(x: 0, y: midY))

    for x in stride(from: CGFloat(0), through: width, by: 2) {
      let relative = x / width
      let sine = sin((relative * .pi * 2 * 2) + phase)
      let y = midY + sine * amplitude
      path.addLine(to: CGPoint(x: x, y: y))
    }

    return path
  }
}

private struct MicIcon: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    let capsuleRect = CGRect(x: rect.midX - rect.width * 0.22,
                             y: rect.minY + rect.height * 0.05,
                             width: rect.width * 0.44,
                             height: rect.height * 0.56)
    path.addRoundedRect(in: capsuleRect, cornerSize: CGSize(width: rect.width * 0.22, height: rect.width * 0.22))

    path.move(to: CGPoint(x: rect.midX - rect.width * 0.34, y: rect.height * 0.48))
    path.addQuadCurve(to: CGPoint(x: rect.midX + rect.width * 0.34, y: rect.height * 0.48),
                      control: CGPoint(x: rect.midX, y: rect.height * 0.80))

    path.addRect(CGRect(x: rect.midX - rect.width * 0.04,
                        y: rect.height * 0.72,
                        width: rect.width * 0.08,
                        height: rect.height * 0.18))

    path.addRoundedRect(in: CGRect(x: rect.midX - rect.width * 0.18,
                                   y: rect.height * 0.88,
                                   width: rect.width * 0.36,
                                   height: rect.height * 0.08),
                        cornerSize: CGSize(width: rect.width * 0.04, height: rect.width * 0.04))

    return path
  }
}
