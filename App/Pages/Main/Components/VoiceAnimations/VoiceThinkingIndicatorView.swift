import SwiftUI

struct VoiceThinkingIndicatorView: View {
  @State private var animate = false

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<4, id: \.self) { index in
        RoundedRectangle(cornerRadius: 3, style: .continuous)
          .fill(Color(hex: "#2A3344").opacity(0.82))
          .frame(width: 6.5, height: animate ? (8 + CGFloat((index % 2) * 11)) : 10)
          .animation(
            .easeInOut(duration: 0.48)
              .delay(Double(index) * 0.09)
              .repeatForever(autoreverses: true),
            value: animate
          )
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(
      Capsule(style: .continuous)
        .fill(Color.white.opacity(0.92))
    )
    .overlay(
      Capsule(style: .continuous)
        .stroke(Color.black.opacity(0.06), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
    .offset(y: 4)
    .onAppear {
      animate = true
    }
  }
}
