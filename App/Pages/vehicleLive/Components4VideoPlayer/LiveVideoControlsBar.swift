import SwiftUI

struct LiveVideoControlsBar: View {
  @Binding var isAudioOn: Bool
  @Binding var quality: LiveVideoQuality
  var onTapQuality: () -> Void
  var onTapFullscreen: () -> Void
  let isFullscreenMode: Bool
  let showAudioButton: Bool

  var body: some View {
    HStack(spacing: 0) {
      if showAudioButton {
        Button {
          isAudioOn.toggle()
        } label: {
          Image(isAudioOn ? "icon_live_speaker_active" : "icon_live_speaker")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
      }

      Spacer()

      Button {
        onTapQuality()
      } label: {
        Text(quality.rawValue)
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
      }
      .buttonStyle(.plain)

      Button {
        onTapFullscreen()
      } label: {
        Image(systemName: isFullscreenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
          .font(.system(size: 18, weight: .regular))
          .foregroundColor(.white)
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .padding(.trailing, 10)
    }
    .padding(.bottom, 10)
    .padding(.top, 30)
    .background(
      LinearGradient(
        colors: [Color.black.opacity(0.7), Color.clear],
        startPoint: .bottom,
        endPoint: .top
      )
    )
  }
}
