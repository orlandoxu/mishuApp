import SwiftUI

struct VoiceActionView: View {
  let status: VoiceState
  let level: CGFloat
  let onTap: () -> Void

  var body: some View {
    let isListening = status == .listening
    let isThinking = status == .thinking
    let isActive = isListening || isThinking

    ZStack {
      if isListening {
        VoiceListeningRippleView(level: level)
          .transition(.opacity)
          .accessibilityIdentifier("home_voice_visualizer")
      }

      if isThinking {
        VoiceThinkingIndicatorView()
          .accessibilityIdentifier("home_voice_thinking")
      }

      Button(action: onTap) {
        ZStack {
          Circle()
            .fill(isActive ? Color.black.opacity(0.06) : Color.white)
            .frame(width: isActive ? 58 : 66, height: isActive ? 58 : 66)
            .overlay(
              Circle()
                .stroke(isActive ? Color.black.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isActive ? 0.08 : 0.16), radius: isActive ? 10 : 20, x: 0, y: isActive ? 3 : 8)

          Image(systemName: isActive ? "stop.fill" : "mic.fill")
            .font(.system(size: isActive ? 18 : 22, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.74))
            .symbolRenderingMode(.hierarchical)
            .offset(y: isActive ? 0 : -0.5)
        }
      }
      .buttonStyle(PlainButtonStyle())
      .offset(y: 42)
      .accessibilityIdentifier("home_voice_mic_button")
    }
    .frame(maxWidth: .infinity)
    .frame(height: 196)
    .accessibilityIdentifier("home_voice_interaction_root")
  }
}
