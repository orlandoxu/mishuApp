import SwiftUI

struct TCardPlayerView: View {
  let did: String
  let channel: Int
  let playbackController: TCardPlaybackController

  var body: some View {
    ZStack {
      TCardPlayerViewRepresentable(did: did, channel: channel, playbackController: playbackController)
        .background(Color.black)

      if did.isEmpty {
        Text("设备异常，未查询到DID")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color.black.opacity(0.5))
          .cornerRadius(8)
      }
    }
  }
}

private struct TCardPlayerViewRepresentable: UIViewRepresentable {
  let did: String
  let channel: Int
  let playbackController: TCardPlaybackController

  final class Coordinator {
    var lastDid: String?
    var lastChannel: Int?
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> UIView {
    let container = UIView()
    container.backgroundColor = .black
    context.coordinator.lastDid = did
    context.coordinator.lastChannel = channel
    if did.isEmpty == false {
      playbackController.bindAndInit(deviceId: did, channel: channel, renderView: container)
    }
    return container
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    let didChanged = context.coordinator.lastDid != did
    let channelChanged = context.coordinator.lastChannel != channel

    if didChanged { context.coordinator.lastDid = did }
    if channelChanged { context.coordinator.lastChannel = channel }

    guard did.isEmpty == false else { return }

    if didChanged || channelChanged {
      playbackController.bindAndInit(deviceId: did, channel: channel, renderView: uiView)
    }
    playbackController.updateLayout(in: uiView)
  }
}
