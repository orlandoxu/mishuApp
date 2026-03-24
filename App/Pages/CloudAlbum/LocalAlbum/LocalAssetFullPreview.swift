import SwiftUI
import Photos
import AVKit

struct LocalAssetFullPreview: View {
  let assets: [PHAsset]
  let startIndex: Int
  let onClose: () -> Void

  @State private var selectedIndex: Int

  init(assets: [PHAsset], startIndex: Int, onClose: @escaping () -> Void) {
    self.assets = assets
    self.startIndex = startIndex
    self.onClose = onClose
    let safeStartIndex = min(max(startIndex, 0), max(assets.count - 1, 0))
    _selectedIndex = State(initialValue: safeStartIndex)
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.black.ignoresSafeArea()

      TabView(selection: $selectedIndex) {
        ForEach(Array(assets.enumerated()), id: \.element.localIdentifier) { index, asset in
          LocalAssetFullPreviewPage(asset: asset, isActive: selectedIndex == index)
            .tag(index)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .ignoresSafeArea()

      HStack(spacing: 12) {
        Text("\(safeDisplayIndex)/\(max(assets.count, 1))")
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
  }

  private var safeDisplayIndex: Int {
    guard !assets.isEmpty else { return 0 }
    return min(max(selectedIndex + 1, 1), assets.count)
  }
}

private struct LocalAssetFullPreviewPage: View {
  let asset: PHAsset
  let isActive: Bool

  @State private var image: UIImage?
  @State private var player: AVPlayer?
  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 1

  var body: some View {
    Group {
      if asset.mediaType == .video {
        videoContent
      } else {
        imageContent
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .onAppear {
      prepareContentIfNeeded()
    }
    .onChange(of: isActive) { active in
      if asset.mediaType == .video {
        active ? player?.play() : player?.pause()
      }
    }
    .onDisappear {
      player?.pause()
      player = nil
    }
  }

  private var imageContent: some View {
    Group {
      if let image {
        Image(uiImage: image)
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
      } else {
        ProgressView().accentColor(.white)
      }
    }
  }

  private var videoContent: some View {
    Group {
      if let player {
        VideoPlayer(player: player)
      } else {
        ProgressView().accentColor(.white)
      }
    }
  }

  private func prepareContentIfNeeded() {
    if asset.mediaType == .video {
      if player == nil {
        Task { @MainActor in
          guard let item = await requestPlayerItem(asset) else {
            ToastCenter.shared.show("视频加载失败")
            return
          }
          let avPlayer = AVPlayer(playerItem: item)
          player = avPlayer
          if isActive {
            avPlayer.play()
          }
        }
      } else if isActive {
        player?.play()
      }
      return
    }

    guard image == nil else { return }
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .none
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .aspectFit,
      options: options
    ) { result, _ in
      if let result {
        image = result
      }
    }
  }

  private func requestPlayerItem(_ asset: PHAsset) async -> AVPlayerItem? {
    await withCheckedContinuation { continuation in
      let options = PHVideoRequestOptions()
      options.isNetworkAccessAllowed = true
      PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
        continuation.resume(returning: item)
      }
    }
  }
}
