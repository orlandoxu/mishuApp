import SwiftUI
import UIKit

/// DONE-AI: Wi-Fi 模式下不显示声音按钮，4G 模式保持原样。
struct VideoPlayerView: View {
  @EnvironmentObject private var viewModel: VehicleLiveViewModel
  @State private var didAutoPlayWifi = false

  private var singleCameraHeight: CGFloat {
    windowWidth * 9 / 16
  }

  private var totalPlayerHeight: CGFloat {
    viewModel.liveIsDualCamera ? (singleCameraHeight * 2) : singleCameraHeight
  }

  var body: some View {
    ZStack {
      Group {
        if viewModel.shouldShowDeviceOfflinePromptInPlayer {
          Color.black
            .overlay(
              Text("设备未在线")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            )
        } else if viewModel.isLiveWifiMode, viewModel.shouldAttemptLiveConnection == false {
          Color.black
            .overlay(
              Text(viewModel.playerErrorMessage?.isEmpty == false ? (viewModel.playerErrorMessage ?? "") : "正在准备Wi-Fi预览连接...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            )
        } else if viewModel.currLiveDid.isEmpty {
          Color.black
            .overlay(
              Text("设备异常，未查询到DID")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            )
        } else {
          VStack(spacing: 1) {
            LiveVideoPaneView(
              did: viewModel.currLiveDid,
              channel: 1,
              title: "前摄",
              isPlaying: $viewModel.liveIsFrontPlaying
            )
            .frame(height: singleCameraHeight)

            if viewModel.liveIsDualCamera {
              LiveVideoPaneView(
                did: viewModel.currLiveDid,
                channel: 2,
                title: "后摄",
                isPlaying: $viewModel.liveIsRearPlaying
              )
              .frame(height: singleCameraHeight)
            }
          }
        }
      }
      .frame(height: totalPlayerHeight)
    }
    .frame(height: totalPlayerHeight)
    .onChange(of: viewModel.liveIsDualCamera) { next in
      if next == false {
        DispatchQueue.main.async {
          viewModel.liveIsRearPlaying = false
        }
      }
    }
    .onAppear {
      autoPlayWifiIfNeeded()
    }
    .onChange(of: viewModel.shouldAttemptLiveConnection) { _ in
      autoPlayWifiIfNeeded()
    }
    .onChange(of: viewModel.currLiveDid) { _ in
      autoPlayWifiIfNeeded()
    }
  }

  private func autoPlayWifiIfNeeded() {
    guard viewModel.isLiveWifiMode else { return }
    guard didAutoPlayWifi == false else { return }
    guard viewModel.shouldAttemptLiveConnection else { return }
    guard viewModel.currLiveDid.isEmpty == false else { return }

    didAutoPlayWifi = true
    if viewModel.liveIsFrontPlaying == false {
      viewModel.liveIsFrontPlaying = true
    }
  }
}
