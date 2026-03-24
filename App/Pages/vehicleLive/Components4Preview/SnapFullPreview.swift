import AVKit
import Kingfisher
import SwiftUI

struct SnapFullPreview: View {
  let preview: LiveCapturePreview
  let onClose: () -> Void

  @EnvironmentObject private var vm: VehicleLiveViewModel
  @State private var selectedIndex: Int = 0
  private var orderedPreviews: [LiveCapturePreview] { vm.liveCaptureHistory }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.black.ignoresSafeArea()

      TabView(selection: $selectedIndex) {
        ForEach(Array(orderedPreviews.enumerated()), id: \.offset) { index, item in
          SnapFullPreviewPage(preview: item, isActive: selectedIndex == index)
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .always))
      .ignoresSafeArea()

      topBar
    }
    .onAppear {
      if let index = orderedPreviews.firstIndex(of: preview) {
        selectedIndex = index
      } else if orderedPreviews.isEmpty == false {
        selectedIndex = 0
      } else {
        selectedIndex = 0
      }
      syncSelectedPreviewWithIndex()
    }
    .onChange(of: selectedIndex) { _ in
      syncSelectedPreviewWithIndex()
    }
    .onChange(of: vm.liveCapturePreview) { selected in
      guard let selected else { return }
      guard let index = orderedPreviews.firstIndex(of: selected), index != selectedIndex else { return }
      selectedIndex = index
    }
    .onChange(of: vm.liveCaptureHistory.count) { _ in
      if orderedPreviews.isEmpty {
        onClose()
        return
      }
      if let selected = vm.liveCapturePreview, let index = orderedPreviews.firstIndex(of: selected) {
        selectedIndex = index
      } else if selectedIndex >= orderedPreviews.count {
        selectedIndex = orderedPreviews.count - 1
      }
      syncSelectedPreviewWithIndex()
    }
  }

  private var topBar: some View {
    HStack(spacing: 12) {
      Text("\(selectedIndex + 1)/\(max(orderedPreviews.count, 1))")
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.45))
        .clipShape(Capsule())

      Button {
        onClose()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
          .frame(width: 40, height: 40)
          .background(Color.white.opacity(0.12))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)
    }
    .padding(.trailing, 16)
    .padding(.top, 16)
  }

  private func syncSelectedPreviewWithIndex() {
    guard orderedPreviews.indices.contains(selectedIndex) else { return }
    vm.liveCapturePreview = orderedPreviews[selectedIndex]
  }
}

private struct SnapFullPreviewPage: View {
  let preview: LiveCapturePreview
  let isActive: Bool

  @State private var player: AVPlayer?
  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 1

  var body: some View {
    Group {
      switch preview.kind {
      case .photo:
        KFImage(preview.url)
          .resizable()
          .scaledToFit()
          .scaleEffect(scale)
          .gesture(
            MagnificationGesture()
              .onChanged { value in
                scale = lastScale * value
              }
              .onEnded { _ in
                let clamped = min(max(scale, 1), 4)
                scale = clamped
                lastScale = clamped
              }
          )
      case .video:
        Group {
          if let player {
            VideoPlayer(player: player)
          } else {
            Color.black
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .onAppear {
      prepareVideoIfNeeded()
    }
    .onChange(of: isActive) { active in
      if preview.kind == .video {
        active ? player?.play() : player?.pause()
      }
    }
    .onDisappear {
      player?.pause()
      player = nil
    }
  }

  private func prepareVideoIfNeeded() {
    guard preview.kind == .video else { return }
    if player == nil {
      player = AVPlayer(url: preview.url)
    }
    if isActive {
      player?.play()
    }
  }
}
