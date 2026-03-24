import SwiftUI

struct LiveVideoPaneView: View {
  let did: String
  let channel: Int
  let title: String
  @Binding var isPlaying: Bool

  @EnvironmentObject private var vm: VehicleLiveViewModel

  @State private var quality: LiveVideoQuality = .uhd
  @State private var isAudioOn = false
  @State private var isQualityPopupPresented = false
  @State private var isFullscreenPresented = false
  @State private var isControlsVisible = true
  @State private var autoHideTask: Task<Void, Error>?

  private var isConnecting: Bool {
    guard did.isEmpty == false else { return false }
    guard vm.playerIsConnected == false else { return false }
    return (vm.playerErrorMessage?.isEmpty ?? true)
  }

  private var shouldShowCenterPlayControl: Bool {
    if isPlaying == false { return true }
    return isControlsVisible
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if isFullscreenPresented {
        Color.black
      } else {
        XCPlayerViewRepresentable(
          bridge: vm.currentPlayerBridge,
          did: did,
          channel: channel,
          qos: quality.qos,
          isPlaying: $isPlaying
        )
      }

      Color.white.opacity(0.001)
        .onTapGesture {
          guard vm.playerIsConnected, isPlaying else { return }
          withAnimation {
            isControlsVisible.toggle()
            if isControlsVisible {
              resetAutoHideTimer()
            } else {
              isQualityPopupPresented = false
            }
          }
        }

      if isConnecting {
        VStack(spacing: 10) {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
          Text("连接设备...")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.6))
        .allowsHitTesting(false)
      }

      if isControlsVisible, vm.playerIsConnected {
        HStack {
          Spacer()
          Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.5))
            .cornerRadius(6)
            .padding(10)
        }
        .transition(.opacity)
      }

      if shouldShowCenterPlayControl, isConnecting == false {
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button {
              guard vm.shouldAttemptLiveConnection else {
                if let msg = vm.playerErrorMessage, msg.isEmpty == false {
                  ToastCenter.shared.show(msg)
                } else {
                  ToastCenter.shared.show("正在准备Wi-Fi预览连接，请稍后")
                }
                return
              }
              isPlaying.toggle()
              resetAutoHideTimer()
            } label: {
              Image(systemName: isPlaying ? "pause.circle" : "play.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .disabled(did.isEmpty || vm.shouldAttemptLiveConnection == false)
            Spacer()
          }
          Spacer()
        }
        .transition(.opacity)
      }

      VStack {
        Spacer()
        if isControlsVisible, vm.playerIsConnected {
          LiveVideoControlsBar(
            isAudioOn: $isAudioOn,
            quality: $quality,
            onTapQuality: {
              withAnimation {
                isQualityPopupPresented.toggle()
                resetAutoHideTimer()
              }
            },
            onTapFullscreen: {
              isFullscreenPresented.toggle()
            },
            isFullscreenMode: false,
            showAudioButton: vm.isLiveWifiMode == false
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }

      if isQualityPopupPresented && isControlsVisible && vm.playerIsConnected {
        VStack {
          Spacer()
          HStack {
            Spacer()
            QualityPopupView(currentQuality: quality) { selected in
              quality = selected
              withAnimation {
                isQualityPopupPresented = false
              }
              resetAutoHideTimer()
            }
            .padding(.bottom, 50)
            .padding(.trailing, 60)
          }
        }
        .transition(.opacity)
      }

      if let msg = vm.playerErrorMessage, msg.isEmpty == false {
        VStack {
          Spacer()
          Text(msg)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            .padding(.bottom, 54)
        }
        .allowsHitTesting(false)
      }
    }
    .fullScreenCover(isPresented: $isFullscreenPresented) {
      LiveVideoFullscreenView(
        did: did,
        channel: channel,
        title: title,
        isPlaying: $isPlaying,
        quality: $quality,
        isAudioOn: $isAudioOn,
        isPresented: $isFullscreenPresented
      )
      .environmentObject(vm)
    }
    .onChange(of: isAudioOn) { enabled in
      guard isPlaying else { return }
      vm.currentPlayerBridge.setAudioEnabled(enabled, channel: channel)
      resetAutoHideTimer()
    }
    .onChange(of: isPlaying) { playing in
      if playing == false {
        autoHideTask?.cancel()
        withAnimation {
          isControlsVisible = true
          isQualityPopupPresented = false
        }
        return
      }
      vm.currentPlayerBridge.setAudioEnabled(isAudioOn, channel: channel)
      resetAutoHideTimer()
    }
    .onChange(of: vm.playerIsConnected) { connected in
      if connected == false, isPlaying {
        DispatchQueue.main.async {
          if isPlaying {
            isPlaying = false
          }
        }
      }
    }
    .onChange(of: vm.playerErrorMessage) { msg in
      guard let msg, msg.isEmpty == false else { return }
      if isPlaying {
        DispatchQueue.main.async {
          if isPlaying {
            isPlaying = false
          }
        }
      }
    }
    .onAppear {
      resetAutoHideTimer()
    }
    .onDisappear {
      autoHideTask?.cancel()
      autoHideTask = nil
    }
  }

  private func resetAutoHideTimer() {
    if isPlaying == false {
      autoHideTask?.cancel()
      isControlsVisible = true
      return
    }
    autoHideTask?.cancel()
    autoHideTask = Task {
      try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
      if !Task.isCancelled {
        withAnimation {
          if !isQualityPopupPresented {
            isControlsVisible = false
          }
        }
      }
    }
  }
}
