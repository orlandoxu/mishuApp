import SwiftUI
import UIKit

struct LiveVideoFullscreenView: View {
  let did: String
  let channel: Int
  let title: String
  @Binding var isPlaying: Bool
  @Binding var quality: LiveVideoQuality
  @Binding var isAudioOn: Bool
  @Binding var isPresented: Bool

  @EnvironmentObject private var vm: VehicleLiveViewModel

  @State private var orientationToken: UUID?
  @State private var didBeginGeneratingOrientationNotifications = false
  @State private var isQualityPopupPresented = false
  @State private var isControlsVisible = true
  @State private var autoHideTask: Task<Void, Error>?

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.black.ignoresSafeArea()

      XCPlayerViewRepresentable(
        bridge: vm.currentPlayerBridge,
        did: did,
        channel: channel,
        qos: quality.qos,
        isPlaying: $isPlaying
      )
      .ignoresSafeArea()

      Color.white.opacity(0.001)
        .onTapGesture {
          withAnimation {
            isControlsVisible.toggle()
            if isControlsVisible {
              resetAutoHideTimer()
            } else {
              isQualityPopupPresented = false
            }
          }
        }

      if isControlsVisible {
        HStack(spacing: 10) {
          Button {
            isPresented = false
          } label: {
            Image(systemName: "xmark")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .frame(width: 34, height: 34)
              .background(Color.black.opacity(0.35))
              .clipShape(Circle())
          }
          .buttonStyle(.plain)

          Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
            .cornerRadius(8)

          Spacer()
        }
        .padding(.top, 14)
        .padding(.leading, 14)
        .padding(.trailing, 14)
        .transition(.move(edge: .top).combined(with: .opacity))
      }

      VStack {
        Spacer()
        if isControlsVisible {
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
              isPresented = false
            },
            isFullscreenMode: true,
            showAudioButton: vm.isLiveWifiMode == false
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }

      if isQualityPopupPresented && isControlsVisible {
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
    }
    .statusBarHidden(true)
    .onChange(of: isAudioOn) { enabled in
      guard isPlaying else { return }
      vm.currentPlayerBridge.setAudioEnabled(enabled, channel: channel)
      resetAutoHideTimer()
    }
    .onAppear {
      resetAutoHideTimer()
      if orientationToken == nil {
        orientationToken = OrientationManager.shared.push(.landscape)
      }

      if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        didBeginGeneratingOrientationNotifications = true
      }
    }
    .onDisappear {
      if let token = orientationToken {
        orientationToken = nil
        OrientationManager.shared.pop(token)
      }

      if didBeginGeneratingOrientationNotifications {
        didBeginGeneratingOrientationNotifications = false
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
      }
      autoHideTask?.cancel()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      if UIDevice.current.orientation == .portrait {
        isPresented = false
      }
    }
  }

  private func resetAutoHideTimer() {
    autoHideTask?.cancel()
    autoHideTask = Task {
      try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
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
