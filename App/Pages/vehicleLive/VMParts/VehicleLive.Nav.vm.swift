import Combine
import Foundation

@MainActor
extension VehicleLiveViewModel {
  /// 进入 T 卡回放页，并在进入前校验可用性与连接状态。
  func openReplay() {
    guard isTCardReplayEnabled else {
      if isLiveWifiMode == false {
        if isLive4GConnectable == false {
          ToastCenter.shared.show("设备未在线，暂无法查看T卡视频")
        } else if playerIsConnected == false {
          ToastCenter.shared.show("设备连接中，请稍后")
        }
      }
      return
    }

    let target = targetImei
    guard target.isEmpty == false else { return }
    liveIsFrontPlaying = false
    liveIsRearPlaying = false
    appNavigation.push(.tCardReplay(imei: target))
  }

  /// 跳转到设备设置页。
  func openSet() {
    let target = targetImei
    guard target.isEmpty == false else { return }
    appNavigation.push(.vehicleSettings(imei: target))
  }

  /// 退出直播页时执行清理：恢复连接策略、释放连接并清空目标设备。
  func cleanExit() {
    stopWifiRecording(showResult: false)
    playerBridge.setConnectionPolicy(.auto)
    playerBridge.releaseAll()
    setLiveImei(nil)
  }

  /// 点击返回时拦截 Wi-Fi 预览退出确认（仅 SDK 已连上时提示）。
  func tapBack() {
    if isLiveWifiMode, wifiStore.isCurrentWifiAppManaged {
      isExitWifiPreviewConfirmPresented = true
      return
    }
    appNavigation.pop()
  }

  /// 用户确认断开 Wi-Fi 预览并退出。
  func confirmExit() {
    stopWifiRecording(showResult: false)
    _ = wifiStore.disconnectCurrentAppManagedWifiIfNeeded()
    isExitWifiPreviewConfirmPresented = false
    appNavigation.pop()
  }
}

@MainActor
extension VehicleLiveViewModel {
  var showModeBtn: Bool {
    guard isLiveWifiMode == false else { return false }
    guard let status = currLiveVehicle?.onlineStatus else { return false }
    guard [2, 7, 9].contains(status) else { return false }
    return !livePreviewModeOptions.isEmpty
  }

  var modeText: String {
    if let selected = livePreviewModeOptions.first(where: { $0.key == selectedLivePreviewModeKey }) {
      return selected.title
    }
    if let fallback = titleByStat(currLiveVehicle?.onlineStatus) {
      return fallback
    }
    return "模式切换"
  }

  func toggleModeMenu() {
    guard showModeBtn else { return }
    isLivePreviewModeMenuPresented.toggle()
  }

  func closeModeMenu() {
    isLivePreviewModeMenuPresented = false
  }

  func setMode(to option: LivePreviewModeOption) {
    guard isLivePreviewModeSwitchLoading == false else { return }
    guard showModeBtn else { return }
    guard targetImei.isEmpty == false else {
      ToastCenter.shared.show("设备信息缺失")
      return
    }
    if selectedLivePreviewModeKey == option.key {
      isLivePreviewModeMenuPresented = false
      return
    }

    isLivePreviewModeSwitchLoading = true
    let imei = targetImei
    let action = livePreviewModeSettingAction
    let params = option.key

    Task {
      let patch = await SettingAPI.shared.setDeviceSettings(imei: imei, action: action, params: params)
      await MainActor.run {
        isLivePreviewModeSwitchLoading = false
        isLivePreviewModeMenuPresented = false
        guard patch != nil else {
          ToastCenter.shared.show("模式切换失败，请稍后再试")
          return
        }
        selectedLivePreviewModeKey = option.key
        if let nextStatus = option.statusHint {
          currLiveVehicle?.onlineStatus = nextStatus
        }
        ToastCenter.shared.show("模式切换成功")
      }

      await loadModeOptions(force: true)
    }
  }

  func loadModeOptions(force: Bool = false) async {
    guard isLiveWifiMode == false else {
      clearModeOptions()
      return
    }
    guard let status = currLiveVehicle?.onlineStatus, [2, 7, 9].contains(status) else {
      clearModeOptions()
      return
    }

    let imei = targetImei
    guard imei.isEmpty == false else {
      clearModeOptions()
      return
    }

    if force == false, livePreviewModeLoadedImei == imei, livePreviewModeOptions.isEmpty == false {
      if selectedLivePreviewModeKey == nil {
        selectedLivePreviewModeKey = keyByStat(status)
      }
      return
    }

    isLivePreviewModeSwitchLoading = true
    async let templateTask = SettingAPI.shared.getTemplateData(imei: imei)
    async let settingsTask = SettingAPI.shared.queryDeviceSetting(imei: imei)

    let templateData = await templateTask
    let deviceSettings = await settingsTask
    isLivePreviewModeSwitchLoading = false

    guard
      let templateData,
      let modeItem = findModeItem(in: templateData.template),
      case let .radio(payload) = modeItem.payload
    else {
      clearModeOptions()
      return
    }

    let c = modeItem.c ?? ""
    let currentSetting = deviceSettings?.first(where: { $0.c == c })
    let allowed = Set(currentSetting?.l ?? [])
    let options = (payload.items ?? [])
      .filter { option in
        let key = option.k?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = option.v?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if key.isEmpty || title.isEmpty { return false }
        if !allowed.isEmpty, !allowed.contains(key) { return false }
        return isModeTitle(title)
      }
      .map { option in
        LivePreviewModeOption(
          key: option.k ?? "",
          title: option.v ?? "",
          statusHint: statusByTitle(option.v ?? "")
        )
      }

    guard !options.isEmpty else {
      clearModeOptions()
      return
    }

    livePreviewModeOptions = options
    livePreviewModeSettingC = modeItem.c
    livePreviewModeSettingAction = modeItem.cmd ?? modeItem.c ?? "device_mode"
    livePreviewModeLoadedImei = imei

    if let currentValue = currentSetting?.v, options.contains(where: { $0.key == currentValue }) {
      selectedLivePreviewModeKey = currentValue
      return
    }
    if let keyFromStatus = keyByStat(status), options.contains(where: { $0.key == keyFromStatus }) {
      selectedLivePreviewModeKey = keyFromStatus
      return
    }
    selectedLivePreviewModeKey = options.first?.key
  }

  func clearModeOptions() {
    livePreviewModeOptions = []
    livePreviewModeSettingC = nil
    livePreviewModeSettingAction = "device_mode"
    livePreviewModeLoadedImei = nil
    selectedLivePreviewModeKey = nil
    isLivePreviewModeSwitchLoading = false
    isLivePreviewModeMenuPresented = false
  }

  private func findModeItem(in items: [TemplateItem]) -> TemplateItem? {
    for item in items {
      if item.cmd == "device_mode" {
        return item
      }
      guard let payload = item.payload else { continue }
      switch payload {
      case let .folder(folder):
        if let children = folder.items, let found = findModeItem(in: children) {
          return found
        }
      case let .group(group):
        if let children = group.items, let found = findModeItem(in: children) {
          return found
        }
      case let .storage(storage):
        if let children = storage.items, let found = findModeItem(in: children) {
          return found
        }
      default:
        continue
      }
    }
    return nil
  }

  private func isModeTitle(_ title: String) -> Bool {
    if title.contains("停车") || title.contains("震动") { return true }
    if title.contains("缩时") { return true }
    if title.contains("哨兵") || title.contains("低功耗") { return true }
    return false
  }

  private func statusByTitle(_ title: String) -> Int? {
    if title.contains("缩时") { return 7 }
    if title.contains("哨兵") || title.contains("低功耗") { return 9 }
    if title.contains("停车") || title.contains("震动") { return 2 }
    return nil
  }

  private func keyByStat(_ status: Int?) -> String? {
    guard let status else { return nil }
    return livePreviewModeOptions.first(where: { $0.statusHint == status })?.key
  }

  private func titleByStat(_ status: Int?) -> String? {
    guard let status else { return nil }
    if status == 2 { return "停车监控" }
    if status == 7 { return "缩时录影" }
    if status == 9 { return "哨兵模式" }
    return nil
  }
}

@MainActor
extension VehicleLiveViewModel {
  /// 绑定播放器与车辆数据订阅，驱动页面状态自动同步。
  func bindStore() {
    playerBridge.isConnectedPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] connected in
        DispatchQueue.main.async {
          guard let self else { return }
          self.playerIsConnected = connected
          self.enforceLiveConnectionPolicy()
        }
      }
      .store(in: &cancellables)

    playerBridge.errorMessagePublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] message in
        self?.playerErrorMessage = message
      }
      .store(in: &cancellables)

    vehiclesStore.$liveImei
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.syncFromStore()
      }
      .store(in: &cancellables)

    vehiclesStore.$vehicles
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.syncFromStore()
      }
      .store(in: &cancellables)

    if entryMode == .wifi {
      wifiStore.$currentSSID
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
          DispatchQueue.main.async {
            self?.syncFromStore()
          }
        }
        .store(in: &cancellables)
    }
  }

  func prepareWifiPreviewSession() async {
    let imei = targetImei
    guard imei.isEmpty == false else {
      wifiPreviewSessionReady = false
      playerErrorMessage = "设备信息缺失，无法准备 Wi-Fi 预览"
      return
    }

    WifiDocLog.info("Step A Begin: 直播页准备 Wi-Fi 预览会话 imei=\(imei)")
    wifiPreviewSessionReady = false
    let discovered = await WifiDirectSessionStore.shared.prepareSessionByDiscover(imei: imei)
    WifiDocLog.info("Step A End: AP discover=\(discovered)")
    guard discovered else {
      playerErrorMessage = "Wi-Fi 预览会话准备失败，请确认手机已连接设备热点"
      return
    }

    if let session = WifiDirectSessionStore.shared.activeSession {
      WifiDocLog.info("Step A Data: did=\(session.did), spec=\(session.spec), wakeupMs=\(session.wakeupMs), ipaddr=\(session.ipaddr ?? "nil"), port=\(session.port)")
    }
    playerErrorMessage = nil
    wifiPreviewSessionReady = true
  }

  /// 从全局 store 同步当前直播设备与能力状态。
  func syncFromStore() {
    liveImei = vehiclesStore.liveImei
    currLiveVehicle = vehiclesStore.currLiveVehicle
    isLiveDualCameraEnabled = (currLiveVehicle?.ability?.rear ?? 0) > 0
    fixState()
    enforceLiveConnectionPolicy()

    if showModeBtn {
      let force = livePreviewModeLoadedImei != targetImei
      Task {
        await loadModeOptions(force: force)
      }
    } else {
      clearModeOptions()
    }
  }

  /// 强制执行连接策略：不允许连接时主动停止播放/对讲并释放连接。
  func enforceLiveConnectionPolicy() {
    if shouldAttemptLiveConnection == false || playerIsConnected == false || isAnyLivePlaying == false {
      stopWifiRecording(showResult: false)
    }
    guard shouldAttemptLiveConnection == false else { return }
    let hasActiveState = liveIsFrontPlaying || liveIsRearPlaying || liveIsTalking || liveIsTalkbackLoading || playerIsConnected
    guard hasActiveState else { return }
    liveIsFrontPlaying = false
    liveIsRearPlaying = false
    stopTalk()
    playerBridge.releaseAll()
  }

  var currentPlayerBridge: any XCBridgeProtocol {
    playerBridge
  }
}
