import SwiftUI

struct VoiceActionView: View {
  let status: VoicePhase
  let onTap: () -> Void

  var body: some View {
    let isListening = status == .listening
    let isThinking = status == .thinking
    let isActive = isListening || isThinking
    let canTap = status == .idle || status == .listening

    VStack(spacing: 10) {
      Button(action: onTap) {
        Group {
          if isActive {
            VoiceThinkingIndicatorView()
              .accessibilityIdentifier("home_voice_indicator")
          } else {
            ZStack {
              Circle()
                .fill(Color.white)
                .frame(width: 66, height: 66)
                .overlay(
                  Circle()
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 8)

              Image(systemName: "mic.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.74))
                .symbolRenderingMode(.hierarchical)
                .offset(y: -0.5)
            }
          }
        }
      }
      .buttonStyle(PlainButtonStyle())
      .disabled(!canTap)
      .accessibilityIdentifier("home_voice_mic_button")

      if isListening {
        Text("再次点击停止语音")
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(Color.black.opacity(0.44))
          .transition(.opacity)
          .accessibilityIdentifier("home_voice_stop_hint")
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 196)
    .accessibilityIdentifier("home_voice_interaction_root")
  }
}
