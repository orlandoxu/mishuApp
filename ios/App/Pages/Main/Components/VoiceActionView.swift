import SwiftUI

struct VoiceActionView: View {
  let status: VoicePhase
  let onTap: () -> Void
  let onTextInput: (String) -> Void

  @State private var isTextInput = false
  @State private var inputValue = ""

  var body: some View {
    let isListening = status == .listening
    let isThinking = status == .thinking
    let isActive = isListening || isThinking
    let canTap = status == .idle || status == .listening

    VStack(spacing: 0) {
      if isTextInput {
        VStack(spacing: 16) {
          HStack(spacing: 8) {
            TextField("在此输入文字...", text: $inputValue)
              .font(.system(size: 15, weight: .regular))
              .foregroundColor(Color.black.opacity(0.80))
              .submitLabel(.send)
              .onSubmit(sendText)

            Button(action: sendText) {
              Text("发送")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.black.opacity(inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.30 : 1))
                .clipShape(Capsule())
            }
            .disabled(inputValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .stroke(Color.black.opacity(0.05), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.12), radius: 22, x: 0, y: 8)
          .padding(.horizontal, 16)

          Button {
            isTextInput = false
          } label: {
            Text("返回语音输入")
              .font(.system(size: 13, weight: .black))
              .foregroundColor(Color.black.opacity(0.70))
              .tracking(1.4)
          }
          .buttonStyle(.plain)
        }
        .padding(.bottom, 6)
      } else {
        VStack(spacing: 0) {
          ZStack {
            if isListening {
              Button(action: onTap) {
                VStack(spacing: 8) {
                  VoiceThinkingIndicatorView()
                    .accessibilityIdentifier("home_voice_indicator")
                  Text("再次点击停止语音")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.gray.opacity(0.82))
                }
              }
              .buttonStyle(.plain)
            } else {
              VStack(spacing: 0) {
                if isThinking {
                  ThinkingDotsView()
                    .padding(.bottom, 16)
                }

                Button(action: onTap) {
                  ZStack {
                    Circle()
                      .fill(isThinking ? Color.black.opacity(0.05) : Color.white)
                      .frame(width: isThinking ? 56 : 66, height: isThinking ? 56 : 66)
                      .overlay(
                        Circle()
                          .stroke(Color.black.opacity(0.05), lineWidth: 1)
                      )
                      .shadow(color: Color.black.opacity(isThinking ? 0 : 0.16), radius: 20, x: 0, y: 8)

                    Image(systemName: isThinking ? "stop.fill" : "mic.fill")
                      .font(.system(size: isThinking ? 20 : 22, weight: .semibold))
                      .foregroundStyle(Color.black.opacity(isThinking ? 0.60 : 0.74))
                      .symbolRenderingMode(.hierarchical)
                      .offset(y: -0.5)
                  }
                }
                .buttonStyle(.plain)
                .disabled(!canTap)
                .accessibilityIdentifier("home_voice_mic_button")
              }
            }
          }
          .frame(minHeight: 120)

          if status == .idle {
            Button {
              isTextInput = true
            } label: {
              Text("文字输入")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(Color.black.opacity(0.70))
                .tracking(1.4)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: 144)
    .accessibilityIdentifier("home_voice_interaction_root")
  }

  private func sendText() {
    let text = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }
    inputValue = ""
    isTextInput = false
    onTextInput(text)
  }
}

private struct ThinkingDotsView: View {
  @State private var animate = false

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(Color.black)
          .frame(width: 12, height: 12)
          .offset(y: animate ? (index == 1 ? 5 : -5) : 0)
          .opacity(animate ? (index == 1 ? 1 : 0.3) : 0.6)
          .animation(
            .easeInOut(duration: 0.75)
              .delay(Double(index) * 0.2)
              .repeatForever(autoreverses: true),
            value: animate
          )
      }
    }
    .onAppear { animate = true }
  }
}
