import SwiftUI

struct TCardReplayView: View {
  let imei: String
  @StateObject private var viewModel: TCardReplayViewModel

  @State private var showSpeedControl = false

  init(imei: String) {
    self.imei = imei
    _viewModel = StateObject(wrappedValue: TCardReplayViewModel(imei: imei))
  }

  var body: some View {
    // Step 1. Setup the main layout container
    VStack(spacing: 0) {
      // Spacer().frame(height: safeAreaTop).background(Color.white)
      NavHeader(title: "T卡回放") {
        HStack(spacing: 8) {
          Menu {
            ForEach(viewModel.tCardAvailableCameraChannels, id: \.self) { channel in
              Button {
                viewModel.switchTCardCamera(to: channel)
              } label: {
                if viewModel.tCardSelectedCameraForMenu == channel {
                  Label(viewModel.tCardCameraTitleForChannel(channel), systemImage: "checkmark")
                } else {
                  Text(viewModel.tCardCameraTitleForChannel(channel))
                }
              }
            }
          } label: {
            HStack(spacing: 4) {
              Text(viewModel.tCardCameraTitle)
                .font(.system(size: 14, weight: .medium))
              Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(viewModel.tCardCanSwitchCamera ? ThemeColor.brand500 : Color(hex: "0x9FB5CC"))
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color.white)
            .overlay(
              RoundedRectangle(cornerRadius: 17)
                .stroke(viewModel.tCardCanSwitchCamera ? ThemeColor.brand500 : Color(hex: "0xDDE7F2"), lineWidth: 1)
            )
          }
          .disabled(viewModel.tCardCanSwitchCamera == false)

          Button {
            ToastCenter.shared.show("功能开发中")
          } label: {
            Image(systemName: "list.bullet")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(Color(hex: "0x111111"))
              .frame(width: 44, height: 44)
          }
          .buttonStyle(.plain)
        }
      }

      // 播放器区域
      ZStack {
        TCardPlayerView(
          did: viewModel.currTCardDid,
          channel: viewModel.tCardChannel,
          playbackController: viewModel.tCardPlaybackController
        )
        .frame(height: windowWidth * 9 / 16)

        // 播放器上面的控制按钮
        VStack {
          Spacer()
          HStack {
            Button(action: {
              viewModel.toggleTCardMute()
            }) {
              Image(systemName: viewModel.tCardIsMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .foregroundColor(.white)
                .padding()
            }
            Spacer()

            // Speed Control
            ZStack(alignment: .bottom) {
              if showSpeedControl {
                VStack(spacing: 0) {
                  ForEach(TCardPlaybackSpeed.allCases.reversed(), id: \.self) { speed in
                    Button(action: {
                      viewModel.setTCardSpeed(speed)
                      showSpeedControl = false
                    }) {
                      Text(speed.title)
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.tCardSpeed == speed ? ThemeColor.brand500 : .white)
                        .padding(.vertical, 8)
                        .frame(width: 60)
                        .background(Color.black.opacity(0.7))
                    }
                    if speed != .x0_5 {
                      Divider().background(Color.white.opacity(0.2))
                    }
                  }
                }
                .cornerRadius(4)
                .offset(y: -40)
              }

              Button(action: {
                withAnimation { showSpeedControl.toggle() }
              }) {
                Text("倍速")
                  .font(.system(size: 14))
                  .foregroundColor(.white)
                  .padding()
              }
            }

            Button(action: {
              viewModel.tCardIsFullscreen = true
            }) {
              Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.white)
                .padding()
            }
          }
        }

        // 播放和暂停播放按钮
        Button(action: {
          viewModel.toggleTCardPlayback()
        }) {
          ZStack {
            Circle()
              .fill(Color.black.opacity(0.4))
              .frame(width: 60, height: 60)

            Image(systemName: viewModel.tCardIsPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 30))
              .foregroundColor(.white)
          }
        }
        .disabled(viewModel.tCardIsLoading || viewModel.currTCardDid.isEmpty || viewModel.tCardSegments.isEmpty)
      }
      .frame(height: windowWidth * 9 / 16)

      // 操作区域
      VStack(spacing: 0) {
        if viewModel.tCardIsLoading || viewModel.tCardIsBridgeConnected == false {
          VStack(alignment: .center, spacing: 12) {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: ThemeColor.gray600))
            Text(viewModel.tCardIsBridgeConnected ? "正在通讯" : "正在建立链接")
              .font(.system(size: 16))
              .foregroundColor(ThemeColor.gray600)
          }
          .frame(height: 160)
          .background(Color.white)
        } else {
          // Step 5. 日期选择组件
          TCardDateSelectorView(
            dates: viewModel.tCardAvailableDates,
            selectedDate: viewModel.tCardSelectedDate,
            onSelect: { viewModel.selectTCardDate($0) }
          )
          .frame(height: 50)
          .background(Color.white)

          // Step 6. 某一天的时间控件
          TCardTimelineView(
            day: viewModel.tCardSelectedDate,
            selectedTimeMs: viewModel.tCardSelectedTimeMs,
            ranges: viewModel.tCardRanges,
            canSeekPreviousRange: viewModel.tCardCanSeekPreviousRange,
            canSeekNextRange: viewModel.tCardCanSeekNextRange,
            onSeekPreviousRange: { viewModel.seekToPreviousRange() },
            onSeekNextRange: { viewModel.seekToNextRange() },
            onScrubBegin: { viewModel.beginTimelineScrub() },
            onSeek: { viewModel.endTimelineScrub(at: $0) }
          )

          // Step 7. 操作按钮
          TCardControlBarView()
        }
      }

      // Step 8. 地图
      TCardMapView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.bottom)
    }
    .navigationBarHidden(true)
    .ignoresSafeArea()
    .environmentObject(viewModel)
    .taskOnce {
      await viewModel.prepare()
    }
    .onDisappear {
      viewModel.closeTCardReplay()
    }
    .overlay(
      Group {
        if viewModel.tCardIsDownloading {
          TCardDownloadProgressOverlay(
            progress: viewModel.tCardDownloadProgress,
            onCancel: { viewModel.cancelTCardDownload() }
          )
        }
      }
    )
    .fullScreenCover(isPresented: Binding(get: { viewModel.tCardIsFullscreen }, set: { viewModel.tCardIsFullscreen = $0 })) {
      TCardReplayFullscreenView(
        viewModel: viewModel,
        onClose: { viewModel.tCardIsFullscreen = false }
      )
    }
  }
}

private struct TCardDownloadProgressOverlay: View {
  let progress: Int
  let onCancel: () -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.25)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        Text("视频下载")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(Color(hex: "0x111111"))
          .padding(.top, 24)

        ZStack {
          Circle()
            .stroke(Color(hex: "0xEEF1F4"), lineWidth: 8)
            .frame(width: 88, height: 88)

          Circle()
            .trim(from: 0, to: CGFloat(value) / 100)
            .stroke(
              Color(hex: "0x09B6FF"),
              style: StrokeStyle(lineWidth: 8, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .frame(width: 88, height: 88)

          Text("\(value)%")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color(hex: "0x3A3A3A"))
        }
        .padding(.top, 28)

        Text("下载视频中，请耐心等待")
          .font(.system(size: 14, weight: .regular))
          .foregroundColor(Color(hex: "0x4B4B4B"))
          .padding(.top, 28)

        Button(action: onCancel) {
          Text("取消")
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(Color(hex: "0x6A6A6A"))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "0xF3F4F6"))
            .cornerRadius(24)
        }
        .buttonStyle(.plain)
        .padding(.top, 24)
        .padding(.bottom, max(24, safeAreaBottom + 8))
      }
      .padding(.horizontal, 24)
      .frame(maxWidth: 360)
      .background(Color.white)
      .cornerRadius(18)
      .padding(.horizontal, 20)
      .padding(.bottom, 16)
    }
  }

  private var value: Int {
    max(0, min(100, progress))
  }
}
