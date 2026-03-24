import AVKit
import Combine
import CoreLocation
import Kingfisher
import SwiftUI
import UIKit

/// 某个资源的详情页（云端）
struct AssetDetailView: View {
  let asset: AlbumAsset
  @Environment(\.presentationMode) var presentationMode
  @StateObject private var localAlbumStore: LocalAlbumStore = .shared
  @State private var player: AVPlayer?
  @State private var isPlaying = false
  @State private var totalDuration: Double = 0
  @State private var currentTime: Double = 0
  @State private var poses: [CLLocationCoordinate2D] = []
  @State private var currentPoseIndex: Int = 0
  @State private var durationObserver: AnyCancellable?
  @State private var timeControlObserver: AnyCancellable?
  @State private var playbackEndObserver: AnyCancellable?
  @State private var isSaving = false
  @State private var isDeleting = false
  @State private var isDeleteConfirmPresented = false
  @State private var orientationToken: UUID?
  @State private var didBeginGeneratingOrientationNotifications = false
  @State private var isFullscreenVideoPresented = false
  @State private var isNavigationSheetPresented = false
  @State private var availableNavigationApps: [MapNavigationApp] = []

  /// Timer for video sync
  let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(spacing: 0) {
      // Header
      ZStack {
        HStack {
          Button(action: {
            presentationMode.wrappedValue.dismiss()
          }) {
            Image(systemName: "chevron.left")
              .font(.system(size: 20))
              .foregroundColor(.black)
              .padding()
          }
          Spacer()
          Spacer().frame(width: 44)
        }
        Text("详情")
          .font(.system(size: 18, weight: .medium))
      }
      .background(Color.white)

      // Content
      VStack(spacing: 0) {
        if asset.mtype == 2 { // Video
          videoPlayerView
        } else {
          imageView
        }

        ZStack {
          if shouldShowMap {
            AlbumDetailMapView(
              poses: poses,
              currentPoseIndex: currentPoseIndex,
              centerCoordinate: mapCenterCoordinate
            )
            .overlay(navigationButtonOverlay, alignment: .topTrailing)
          } else {
            VStack(spacing: 10) {
              Image("img_placeholder_no_location")
              Text("暂无定位信息")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0x666666"))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ThemeColor.gray100)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        // 底部功能按钮
        HStack(spacing: 18) {
          Spacer()
          Button {
            if isDeleting { return }
            isDeleteConfirmPresented = true
          } label: {
            Image("icon_delete")
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .opacity(isDeleting ? 0.6 : 1.0)
              .frame(width: 56, height: 44)
          }
          .buttonStyle(.plain)
          .disabled(isDeleting || isSaving)

          Spacer()

          Button {
            if isSaving { return }
            Task {
              isSaving = true
              let success = await localAlbumStore.save(asset: asset)
              isSaving = false
              if success {
                ToastCenter.shared.show("已保存到本地相册")
              } else {
                ToastCenter.shared.show("保存失败")
              }
            }
          } label: {
            Image("icon_download")
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
              .foregroundColor(Color(hex: "0x111111").opacity(isSaving ? 0.6 : 1.0))
              .frame(width: 56, height: 44)
          }
          .buttonStyle(.plain)
          .disabled(isSaving || isDeleting)

          Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
          VStack(spacing: 0) {
            Divider()
            Color.white
          }
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationBarHidden(true)
    .alert(isPresented: $isDeleteConfirmPresented) {
      Alert(
        title: Text("确认删除？"),
        message: Text("删除后将无法恢复"),
        primaryButton: .destructive(Text("删除")) {
          Task {
            isDeleting = true
            let result = await AlbumAPI.shared.deleteResourceById(asset.id)
            isDeleting = false
            if result != nil {
              await CloudAlbumViewModel.shared(imei: asset.imei).fetchData()
              ToastCenter.shared.show("删除成功")
              presentationMode.wrappedValue.dismiss()
            } else {
              ToastCenter.shared.show("删除失败，请稍后再试")
            }
          }
        },
        secondaryButton: .cancel(Text("取消"))
      )
    }
    .onAppear {
      setupData()
      setupOrientationIfNeeded()
    }
    .onDisappear {
      player?.pause()
      isFullscreenVideoPresented = false
      teardownOrientationIfNeeded()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      handleDeviceOrientationChange()
    }
    .fullScreenCover(isPresented: $isFullscreenVideoPresented) {
      FullscreenVideoPlayerView(player: player, isPresented: $isFullscreenVideoPresented)
    }
    .actionSheet(isPresented: $isNavigationSheetPresented) {
      ActionSheet(
        title: Text("选择导航应用"),
        buttons: navigationSheetButtons
      )
    }
  }

  private var mapCenterCoordinate: CLLocationCoordinate2D? {
    guard asset.pos.count >= 2 else { return nil }
    guard asset.pos[0] != 0, asset.pos[1] != 0 else { return nil }
    return CLLocationCoordinate2D(latitude: asset.pos[1], longitude: asset.pos[0])
  }

  private var shouldShowMap: Bool {
    return !poses.isEmpty || mapCenterCoordinate != nil
  }

  private var navigationSheetButtons: [ActionSheet.Button] {
    let mapButtons = availableNavigationApps.map { mapApp in
      ActionSheet.Button.default(Text(mapApp.displayName)) {
        openNavigationApp(mapApp)
      }
    }
    return mapButtons + [.cancel(Text("取消"))]
  }

  private var navigationButtonOverlay: some View {
    Group {
      if mapCenterCoordinate != nil {
        Button {
          presentNavigationOptions()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "location.fill")
              .font(.system(size: 12, weight: .semibold))
            Text("导航")
              .font(.system(size: 13, weight: .semibold))
          }
          .foregroundColor(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(hex: "0x111111").opacity(0.85))
          .cornerRadius(18)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.trailing, 12)
      }
    }
  }

  private var videoPlayerView: some View {
    VStack(spacing: 0) {
      ZStack {
        if let player = player, !isFullscreenVideoPresented {
          VideoPlayer(player: player)
        } else {
          Color.black
        }
      }
      .frame(width: windowWidth, height: windowWidth * 9 / 16)
      .background(ThemeColor.gray700)
    }
    .onReceive(timer) { _ in
      guard isPlaying, let player = player else { return }
      let current = player.currentTime().seconds
      if !current.isNaN {
        currentTime = current
        updateMapIndex()
      }
    }
  }

  private var imageView: some View {
    KFImage(URL(string: asset.url))
      .resizable()
      .scaledToFill()
      .frame(width: windowWidth, height: windowWidth * 9 / 16)
      .clipped()
      .background(Color.black)
      .contentShape(Rectangle())
      .onTapGesture {
        guard let url = URL(string: asset.url) else { return }
        ImageViewerManager.shared.show(url: url)
      }
  }

  private func setupData() {
    print("asset: \(asset) pos: \(asset.parsedPoses)")
    poses = asset.parsedPoses

    if asset.mtype == 2 {
      if let url = URL(string: asset.url) {
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer

        durationObserver = playerItem.publisher(for: \.duration)
          .receive(on: DispatchQueue.main)
          .sink { duration in
            if duration.isNumeric {
              self.totalDuration = duration.seconds
            }
          }

        timeControlObserver = newPlayer.publisher(for: \.timeControlStatus)
          .receive(on: DispatchQueue.main)
          .sink { status in
            isPlaying = (status == .playing)
          }

        playbackEndObserver = NotificationCenter.default.publisher(
          for: .AVPlayerItemDidPlayToEndTime,
          object: playerItem
        )
        .receive(on: DispatchQueue.main)
        .sink { _ in
          isPlaying = false
          currentTime = totalDuration
        }

        newPlayer.play()
      }
    }
  }

  private func togglePlayPause() {
    guard let player = player else { return }
    if isPlaying {
      player.pause()
    } else {
      if currentTime >= totalDuration {
        player.seek(to: .zero)
        currentTime = 0
      }
      player.play()
    }
    isPlaying.toggle()
  }

  private func seek(to time: Double) {
    guard let player = player else { return }
    player.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    currentTime = time
    updateMapIndex()
  }

  private func updateMapIndex() {
    guard !poses.isEmpty, totalDuration > 0 else { return }
    let progress = currentTime / totalDuration
    let index = Int(Double(poses.count - 1) * progress)
    currentPoseIndex = min(max(index, 0), poses.count - 1)
  }

  private func formatTime(_ seconds: Double) -> String {
    if seconds.isNaN || seconds.isInfinite { return "00:00" }
    let s = Int(seconds)
    let m = s / 60
    let sec = s % 60
    return String(format: "%02d:%02d", m, sec)
  }

  private func setupOrientationIfNeeded() {
    guard asset.mtype == 2 else { return }

    if orientationToken == nil {
      orientationToken = OrientationManager.shared.push(.allButUpsideDown)
    }

    if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
      didBeginGeneratingOrientationNotifications = true
    }

    DispatchQueue.main.async {
      handleDeviceOrientationChange()
    }
  }

  private func teardownOrientationIfNeeded() {
    if let token = orientationToken {
      orientationToken = nil
      OrientationManager.shared.pop(token)
    }

    if didBeginGeneratingOrientationNotifications {
      didBeginGeneratingOrientationNotifications = false
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
  }

  private func handleDeviceOrientationChange() {
    guard asset.mtype == 2 else { return }

    switch UIDevice.current.orientation {
    case .landscapeLeft, .landscapeRight:
      isFullscreenVideoPresented = true
    case .portrait:
      isFullscreenVideoPresented = false
    default:
      break
    }
  }

  private func presentNavigationOptions() {
    guard mapCenterCoordinate != nil else {
      ToastCenter.shared.show("暂无可导航的位置")
      return
    }

    let installedApps = MapNavigationApp.allCases.filter { $0.isInstalled }
    guard !installedApps.isEmpty else {
      ToastCenter.shared.show("未检测到可用地图App，请先安装百度/高德/腾讯地图")
      return
    }

    availableNavigationApps = installedApps
    isNavigationSheetPresented = true
  }

  private func openNavigationApp(_ mapApp: MapNavigationApp) {
    guard let coordinate = mapCenterCoordinate else {
      ToastCenter.shared.show("暂无可导航的位置")
      return
    }

    guard let url = mapApp.navigationURL(to: coordinate) else {
      ToastCenter.shared.show("导航跳转失败")
      return
    }

    guard UIApplication.shared.canOpenURL(url) else {
      ToastCenter.shared.show("\(mapApp.displayName)未安装或无法打开")
      return
    }

    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }
}

private enum MapNavigationApp: CaseIterable {
  case baidu
  case gaode
  case tencent

  var displayName: String {
    switch self {
    case .baidu: return "百度地图"
    case .gaode: return "高德地图"
    case .tencent: return "腾讯地图"
    }
  }

  private var schemeURL: URL? {
    switch self {
    case .baidu:
      return URL(string: "baidumap://")
    case .gaode:
      return URL(string: "iosamap://")
    case .tencent:
      return URL(string: "qqmap://")
    }
  }

  var isInstalled: Bool {
    guard let schemeURL else { return false }
    return UIApplication.shared.canOpenURL(schemeURL)
  }

  func navigationURL(to coordinate: CLLocationCoordinate2D) -> URL? {
    let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? "MishuApp"
    let destinationName = "车辆位置"
    let encodedAppName = appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appName
    let encodedDestinationName =
      destinationName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? destinationName
    let latitude = coordinate.latitude
    let longitude = coordinate.longitude

    let urlString: String
    switch self {
    case .baidu:
      urlString =
        "baidumap://map/direction?destination=name:\(encodedDestinationName)|latlng:\(latitude),\(longitude)&coord_type=gcj02&mode=driving"
    case .gaode:
      urlString =
        "iosamap://path?sourceApplication=\(encodedAppName)&dlat=\(latitude)&dlon=\(longitude)&dname=\(encodedDestinationName)&dev=0&t=0"
    case .tencent:
      let referer = (Bundle.main.bundleIdentifier ?? "com.spreadwin.mishuapp")
        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "com.spreadwin.mishuapp"
      urlString =
        "qqmap://map/routeplan?type=drive&tocoord=\(latitude),\(longitude)&to=\(encodedDestinationName)&policy=0&referer=\(referer)"
    }

    return URL(string: urlString)
  }
}

private struct FullscreenVideoPlayerView: View {
  let player: AVPlayer?
  @Binding var isPresented: Bool
  @State private var didBeginGeneratingOrientationNotifications = false

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea()
      if let player {
        VideoPlayer(player: player)
          .ignoresSafeArea()
      }
    }
    .statusBarHidden(true)
    .onAppear {
      if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        didBeginGeneratingOrientationNotifications = true
      }
    }
    .onDisappear {
      if didBeginGeneratingOrientationNotifications {
        didBeginGeneratingOrientationNotifications = false
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      if UIDevice.current.orientation == .portrait {
        isPresented = false
      }
    }
  }
}
