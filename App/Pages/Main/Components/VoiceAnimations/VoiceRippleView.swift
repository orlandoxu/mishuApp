import SwiftUI

struct VoiceListeningRippleView: View {
  let level: CGFloat

  @State private var phase: CGFloat = 0
  @State private var pulse = false
  @State private var shimmer = false

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 30, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color(hex: "#F6F9FF"), Color(hex: "#EEF4FF"), Color(hex: "#F8FAFF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 30, style: .continuous)
            .stroke(Color(hex: "#C7D8FF").opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Color(hex: "#7AA7FF").opacity(0.16), radius: 20, x: 0, y: 10)

      ForEach(0..<4, id: \.self) { index in
        Circle()
          .stroke(
            Color(hex: "#6B9BFF").opacity(0.24 - (CGFloat(index) * 0.04)),
            lineWidth: 1.4
          )
          .frame(width: ringSize(for: index), height: ringSize(for: index))
          .scaleEffect(pulse ? (1.02 + (CGFloat(index) * 0.03) + intensity * 0.12) : (0.94 + CGFloat(index) * 0.02))
          .opacity(pulse ? (0.20 - CGFloat(index) * 0.03) : (0.33 - CGFloat(index) * 0.05))
          .animation(
            .easeInOut(duration: 1.55)
              .delay(Double(index) * 0.08)
              .repeatForever(autoreverses: true),
            value: pulse
          )
      }

      HStack(alignment: .center, spacing: 4) {
        ForEach(0..<22, id: \.self) { index in
          Capsule()
            .fill(
              LinearGradient(
                colors: [Color(hex: "#6ED8FF"), Color(hex: "#5A8FFF")],
                startPoint: .bottom,
                endPoint: .top
              )
            )
            .frame(width: 3.5, height: barHeight(at: index))
            .opacity(0.90)
        }
      }
      .frame(width: 260, height: 76)

      RoundedRectangle(cornerRadius: 26, style: .continuous)
        .fill(
          LinearGradient(
            colors: [Color.clear, Color.white.opacity(0.44), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 56, height: 112)
        .offset(x: shimmer ? 120 : -120)
        .blur(radius: 0.2)
        .animation(.linear(duration: 2.3).repeatForever(autoreverses: false), value: shimmer)
        .mask(
          RoundedRectangle(cornerRadius: 30, style: .continuous)
            .frame(width: 320, height: 124)
        )
    }
    .frame(width: 320, height: 124)
    .drawingGroup()
    .onAppear {
      withAnimation(.linear(duration: 2.1).repeatForever(autoreverses: false)) {
        phase = .pi * 2
      }

      pulse = true
      shimmer = true
    }
  }

  private var intensity: CGFloat {
    min(max(level, 0), 1)
  }

  private func ringSize(for index: Int) -> CGFloat {
    64 + (CGFloat(index) * 26)
  }

  private func barHeight(at index: Int) -> CGFloat {
    let base: CGFloat = 10
    let wave = abs(sin((CGFloat(index) * 0.46) + phase * 1.7))
    let subWave = abs(sin((CGFloat(index) * 0.24) + phase * 2.3))
    let dynamic = (14 + intensity * 26) * wave
    return base + dynamic + subWave * 5
  }
}
