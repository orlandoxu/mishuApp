import SwiftUI

struct TCardReplayFullscreenView: View {
  @ObservedObject var viewModel: TCardReplayViewModel
  let onClose: () -> Void

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      VStack(spacing: 0) {
        HStack {
          Button(action: onClose) {
            Image(systemName: "chevron.left")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
          Spacer()
        }
        .padding(.horizontal, 8)

        Spacer()

        TCardPlayerView(
          did: viewModel.currTCardDid,
          channel: viewModel.tCardChannel,
          playbackController: viewModel.tCardPlaybackController
        )
          .frame(height: UIScreen.main.bounds.width * 9 / 16)

        Spacer()

        HStack {
          Button(action: { viewModel.toggleTCardMute() }) {
            Image(systemName: viewModel.tCardIsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
          Spacer()
          Button(action: { viewModel.toggleTCardPlayback() }) {
            Image(systemName: viewModel.tCardIsPlaying ? "pause.circle.fill" : "play.circle.fill")
              .font(.system(size: 44))
              .foregroundColor(.white.opacity(0.9))
              .frame(width: 64, height: 64)
          }
          Spacer()
          Button(action: onClose) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
      }
    }
  }
}
