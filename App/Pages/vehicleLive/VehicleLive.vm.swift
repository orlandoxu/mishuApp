import AVFoundation
import Combine
import Foundation
import SwiftUI

struct LiveCapturePreview: Equatable {
  enum Kind: Equatable {
    case photo
    case video
  }

  let kind: Kind
  let url: URL
  let id: String?
  let cam: LiveCaptureCameraMode
}

struct LiveCaptureSuccessNotice: Identifiable {
  let id = UUID()
  let kind: LiveCapturePreview.Kind
}

enum BottomActionStatus: Equatable, Hashable {
  case record // 录制
  case talkback // 对讲
  case snapshot // 抓拍
}

enum LiveCaptureCameraMode: Equatable, Hashable {
  case front
  case rear
}

enum WifiCaptureActionMode: Equatable, Hashable {
  case photo
  case video
}

struct LivePreviewModeOption: Identifiable, Equatable, Hashable {
  let key: String
  let title: String
  let statusHint: Int?

  var id: String {
    key
  }
}

@MainActor
final class VehicleLiveViewModel: ObservableObject {
  enum WifiDocLog {
    static func info(_ message: String) {
      #if DEBUG
        print("[WifiDoc][Live] \(message)")
      #endif
    }
  }

  @Published var liveIsFrontPlaying: Bool = false // 前路是否在播
  @Published var liveIsRearPlaying: Bool = false // 后路是否在播
  @Published var liveIsExpanded: Bool = true // 功能区是否展开
  @Published var liveIsDualCamera: Bool = false // 是否双路画面
  @Published var liveCapturePreview: LiveCapturePreview? = nil // 当前预览项
  @Published var liveCaptureHistory: [LiveCapturePreview] = [] // 预览历史列表
  @Published var liveCaptureSuccessNotice: LiveCaptureSuccessNotice? = nil // 抓拍/录像成功提示
  @Published var liveIsFullScreenPreviewPresented: Bool = false // 是否全屏预览
  @Published var liveIsTalking: Bool = false // 是否正在对讲
  @Published var liveIsTalkbackLoading: Bool = false // 对讲按钮加载中
  @Published var isSnapshotLoading: Bool = false // 抓拍中
  @Published var isVideoCaptureLoading: Bool = false // 录制按钮加载中
  @Published var isWifiRecording: Bool = false // Wi-Fi 录像是否进行中
  @Published var bottomActionStatus: BottomActionStatus = .talkback // 底部主按钮模式
  @Published var captureCameraMode: LiveCaptureCameraMode = .front // 当前抓拍摄像头
  @Published var isEagleSnapshotEnabled: Bool = false // 鹰眼抓拍是否开启
  @Published var wifiCaptureActionMode: WifiCaptureActionMode = .photo // Wi-Fi 抓拍按钮模式
  @Published var livePreviewModeOptions: [LivePreviewModeOption] = [] // 预览模式选项
  @Published var isLivePreviewModeSwitchLoading: Bool = false // 模式切换加载中
  @Published var isLivePreviewModeMenuPresented: Bool = false // 模式菜单是否展开

  @Published var currLiveVehicle: VehicleModel? = nil
  @Published var liveImei: String? = nil
  @Published var isLiveDualCameraEnabled: Bool = false
  @Published var selectedLivePreviewModeKey: String? = nil
  @Published var playerIsConnected: Bool = false
  @Published var playerErrorMessage: String? = nil
  @Published var wifiPreviewSessionReady: Bool = false
  @Published var isExitWifiPreviewConfirmPresented: Bool = false

  let vehiclesStore: VehiclesStore
  let wifiStore: WifiStore
  let playerBridge: any XCBridgeProtocol
  let appNavigation: AppNavigationModel
  private let deviceId: String
  let entryMode: VehicleLiveEntryMode
  let liveTalkbackController = LiveTalkbackController()
  var cancellables: Set<AnyCancellable> = []
  var livePreviewModeSettingC: String?
  var livePreviewModeSettingAction: String = "device_mode"
  var livePreviewModeLoadedImei: String?
  var wifiRecordConsumerId: UUID?
  var wifiRecordFileURL: URL?
  var wifiRecorder: XCAVRecord?
  var wifiRecordKeyFrameReady: Bool = false
  var wifiRecordStartTime: Date?
  var wifiRecordAudioFormatHint: XCAVFormat?

  /// 初始化直播页 ViewModel，并绑定依赖与状态订阅。
  init(
    deviceId: String,
    entryMode: VehicleLiveEntryMode = .cellular,
    vehiclesStore: VehiclesStore = .shared,
    wifiStore: WifiStore = .shared,
    playerBridge: (any XCBridgeProtocol)? = nil,
    appNavigation: AppNavigationModel = .shared
  ) {
    self.deviceId = deviceId
    self.entryMode = entryMode
    self.vehiclesStore = vehiclesStore
    self.wifiStore = wifiStore
    if let playerBridge {
      self.playerBridge = playerBridge
    } else {
      self.playerBridge = entryMode == .wifi ? XCBridge4Wifi.shared : XCBridge4Network.shared
    }
    self.appNavigation = appNavigation
    playerIsConnected = self.playerBridge.isConnected
    playerErrorMessage = self.playerBridge.errorMessage
    bindStore()
    syncFromStore()
  }

  var currLiveDid: String {
    currLiveVehicle?.did ?? ""
  }

  var isAnyLivePlaying: Bool {
    liveIsFrontPlaying || liveIsRearPlaying
  }

  var targetImei: String {
    currLiveVehicle?.imei ?? liveImei ?? deviceId
  }

  var isLive4GConnectable: Bool {
    guard entryMode == .cellular else { return false }
    return currLiveVehicle?.canConnect == true
  }

  var isLiveWifiMode: Bool {
    entryMode == .wifi
  }

  var shouldAttemptLiveConnection: Bool {
    if isLiveWifiMode { return wifiPreviewSessionReady && currLiveDid.isEmpty == false }
    if currLiveDid.isEmpty { return false }
    return isLive4GConnectable
  }

  var shouldShowDeviceOfflinePromptInPlayer: Bool {
    if currLiveVehicle == nil { return false }
    return !isLiveWifiMode && !isLive4GConnectable
  }

  var isTalkbackEnabled: Bool {
    if liveIsTalkbackLoading { return false }
    if shouldAttemptLiveConnection == false { return false }
    if currLiveDid.isEmpty { return false }
    if playerIsConnected == false { return false }
    return true
  }

  var isRecordEnabled: Bool {
    guard !isSnapshotLoading, !isVideoCaptureLoading else { return false }
    return currLiveVehicle?.isSnapshotAvailable == true
  }

  var isEagleSnapshotSupported: Bool {
    (currLiveVehicle?.ability?.eaglePhoto ?? 0) > 0
  }

  var recordIsLoading: Bool {
    if isAnyLivePlaying { return false }
    return isVideoCaptureLoading
  }

  var isWifiCaptureEnabled: Bool {
    if isWifiRecording { return true }
    if isSnapshotLoading || isVideoCaptureLoading { return false }
    if isAnyLivePlaying == false { return false }
    if playerIsConnected == false { return false }
    if targetImei.isEmpty { return false }
    return true
  }

  var isTCardReplayEnabled: Bool {
    guard targetImei.isEmpty == false else { return false }
    if isLiveWifiMode { return true } // TODO：这个有点问题，wifi页也需要连接上才行！
    return isLive4GConnectable && playerIsConnected
  }

  /// 页面准备入口：设置连接策略、同步当前设备并预加载模式切换数据。
  func prepare() async {
    playerBridge.setConnectionPolicy(isLiveWifiMode ? .localLan : .auto)
    if vehiclesStore.liveImei != deviceId {
      setLiveImei(deviceId)
    }
    if currLiveVehicle == nil {
      await vehiclesStore.refresh()
      syncFromStore()
    }
    if isLiveWifiMode {
      await prepareWifiPreviewSession()
    } else {
      wifiPreviewSessionReady = false
    }
    fixState()
    await loadModeOptions(force: true)
  }

  /// 设置当前直播目标 IMEI，并同步 store 后重置页面状态。
  func setLiveImei(_ imei: String?) {
    vehiclesStore.setLiveImei(imei)
    syncFromStore()
    resetLiveViewState()
  }

  /// 重置直播页的交互状态与缓存数据。
  func resetLiveViewState() {
    stopWifiRecording(showResult: false)
    stopTalk()
    liveIsFrontPlaying = false
    liveIsRearPlaying = false
    liveIsExpanded = true
    liveIsDualCamera = false
    captureCameraMode = .front
    wifiCaptureActionMode = .photo
    isEagleSnapshotEnabled = false
    liveCapturePreview = nil
    liveCaptureHistory = []
    liveCaptureSuccessNotice = nil
    liveIsFullScreenPreviewPresented = false
    livePreviewModeOptions = []
    livePreviewModeSettingC = nil
    livePreviewModeSettingAction = "device_mode"
    livePreviewModeLoadedImei = nil
    selectedLivePreviewModeKey = nil
    isLivePreviewModeSwitchLoading = false
    isLivePreviewModeMenuPresented = false
  }

  var preferredTalkbackChannel: Int {
    if liveIsRearPlaying { return 2 }
    if liveIsFrontPlaying { return 1 }
    let camera = currLiveVehicle?.defaultCamera ?? ""
    if camera.contains("后") || camera.lowercased().contains("rear") { return 2 }
    return 1
  }
}
