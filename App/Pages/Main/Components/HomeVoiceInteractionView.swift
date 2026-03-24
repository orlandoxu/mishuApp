import SwiftUI

struct HomeVoiceInteractionView: View {
  let status: HomeVoiceStatus
  let level: CGFloat
  let onTap: () -> Void

  @State private var phase: CGFloat = 0
  @State private var glowShift: CGFloat = 0

  private var isListening: Bool { status == .listening }

  var body: some View {
    ZStack {
      if isListening {
        VoiceFluxVisualizer(phase: phase, level: level, glowShift: glowShift)
          .transition(.opacity)
          .accessibilityIdentifier("home_voice_visualizer")
      }

      if status == .thinking {
        ThinkingMatrixView()
          .accessibilityIdentifier("home_voice_thinking")
      }

      Button(action: onTap) {
        ZStack {
          Circle()
            .fill(isListening ? Color.black.opacity(0.06) : Color.white)
            .frame(width: isListening ? 58 : 66, height: isListening ? 58 : 66)
            .overlay(
              Circle()
                .stroke(isListening ? Color.black.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isListening ? 0.08 : 0.16), radius: isListening ? 10 : 20, x: 0, y: isListening ? 3 : 8)

          if isListening || status == .thinking {
            RoundedRectangle(cornerRadius: 3)
              .fill(Color.black.opacity(0.72))
              .frame(width: 17, height: 17)
          } else {
            MicShape()
              .fill(Color.black.opacity(0.70))
              .frame(width: 21, height: 25)
          }
        }
      }
      .buttonStyle(PlainButtonStyle())
      .offset(y: 42)
      .accessibilityIdentifier("home_voice_mic_button")
    }
    .frame(maxWidth: .infinity)
    .frame(height: 196)
    .onAppear {
      withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
        phase = .pi * 2
      }
      withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
        glowShift = 1
      }
    }
  }
}

private struct VoiceFluxVisualizer: View {
  let phase: CGFloat
  let level: CGFloat
  let glowShift: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(hex: "#080B14"), Color(hex: "#101728"), Color(hex: "#0A0E1B")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 320, height: 116)

      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
        .frame(width: 320, height: 116)

      FluxWave(amplitude: 9 + (level * 15), phase: phase, frequency: 2.1)
        .stroke(
          LinearGradient(colors: [Color(hex: "#6AF6FF"), Color(hex: "#40B3FF")], startPoint: .leading, endPoint: .trailing),
          style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
        )
        .frame(width: 292, height: 90)
        .shadow(color: Color(hex: "#4DDFFF").opacity(0.55), radius: 6)

      FluxWave(amplitude: 6 + (level * 12), phase: phase + 1.7, frequency: 3.0)
        .stroke(
          LinearGradient(colors: [Color(hex: "#8A5CFF"), Color(hex: "#D46CFF")], startPoint: .leading, endPoint: .trailing),
          style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
        )
        .frame(width: 292, height: 90)
        .blendMode(.screen)

      HStack(alignment: .center, spacing: 5) {
        ForEach(0..<22) { index in
          Capsule()
            .fill(
              LinearGradient(
                colors: [Color(hex: "#74F4FF"), Color(hex: "#5E8DFF"), Color(hex: "#A05CFF")],
                startPoint: .bottom,
                endPoint: .top
              )
            )
            .frame(width: 4, height: barHeight(index: index))
            .opacity(0.85)
        }
      }
      .frame(width: 292, height: 76)

      LinearGradient(
        colors: [Color.clear, Color.white.opacity(0.10), Color.clear],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: 82, height: 116)
      .offset(x: -146 + (glowShift * 292))
      .blendMode(.screen)
      .clipped()
    }
    .compositingGroup()
  }

  private func barHeight(index: Int) -> CGFloat {
    let base = CGFloat(10)
    let wave = abs(sin((CGFloat(index) * 0.45) + phase * 1.25))
    let secondary = abs(sin((CGFloat(index) * 0.22) + phase * 2.2))
    return base + wave * (18 + level * 34) + secondary * 6
  }
}

private struct ThinkingMatrixView: View {
  @State private var animate = false

  var body: some View {
    HStack(spacing: 7) {
      ForEach(0..<5) { idx in
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.black.opacity(0.72))
          .frame(width: 7, height: animate ? (8 + CGFloat((idx % 3) * 8)) : 9)
          .animation(
            .easeInOut(duration: 0.45)
              .delay(Double(idx) * 0.08)
              .repeatForever(autoreverses: true),
            value: animate
          )
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
    .background(Color.white.opacity(0.64))
    .clipShape(Capsule())
    .overlay(Capsule().stroke(Color.black.opacity(0.05), lineWidth: 1))
    .offset(y: 4)
    .onAppear { animate = true }
  }
}

private struct FluxWave: Shape {
  var amplitude: CGFloat
  var phase: CGFloat
  var frequency: CGFloat

  var animatableData: CGFloat {
    get { phase }
    set { phase = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let midY = rect.midY
    path.move(to: CGPoint(x: 0, y: midY))

    let width = rect.width
    for x in stride(from: CGFloat(0), through: width, by: 2) {
      let relativeX = x / width
      let y = midY + sin((relativeX * .pi * 2 * frequency) + phase) * amplitude
      path.addLine(to: CGPoint(x: x, y: y))
    }

    return path
  }
}

private struct MicShape: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()

    let bodyRect = CGRect(
      x: rect.midX - rect.width * 0.23,
      y: rect.minY + rect.height * 0.06,
      width: rect.width * 0.46,
      height: rect.height * 0.56
    )
    path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: rect.width * 0.23, height: rect.width * 0.23))

    path.move(to: CGPoint(x: rect.midX - rect.width * 0.34, y: rect.height * 0.48))
    path.addQuadCurve(
      to: CGPoint(x: rect.midX + rect.width * 0.34, y: rect.height * 0.48),
      control: CGPoint(x: rect.midX, y: rect.height * 0.80)
    )

    path.addRect(
      CGRect(
        x: rect.midX - rect.width * 0.04,
        y: rect.height * 0.70,
        width: rect.width * 0.08,
        height: rect.height * 0.20
      )
    )

    path.addRoundedRect(
      in: CGRect(
        x: rect.midX - rect.width * 0.18,
        y: rect.height * 0.90,
        width: rect.width * 0.36,
        height: rect.height * 0.08
      ),
      cornerSize: CGSize(width: rect.width * 0.04, height: rect.width * 0.04)
    )

    return path
  }
}
