import Foundation

@MainActor
extension VehicleLiveViewModel {
  /// 处理 4G 模式抓拍动作并展示结果。
  func onTapSnapshot() {
    guard targetImei.isEmpty == false else {
      ToastCenter.shared.show("设备信息缺失")
      return
    }

    isSnapshotLoading = true
    let camera = preferredCamera
    let camMode = captureCameraMode
    let mode = isEagleSnapshotEnabled ? "eagle" : "normal"
    let imei = targetImei
    Task {
      let result = await ActionAPI.shared.realTimePhoto(imei: imei, camera: camera, mode: mode)
      await MainActor.run {
        isSnapshotLoading = false

        guard
          let item = result?.first,
          let urlString = item.url ?? item.urlThumb,
          let url = URL(string: urlString)
        else {
          return
        }

        showPreview(LiveCapturePreview(kind: .photo, url: url, id: item.id, cam: camMode))
      }
    }
  }

  /// 处理 4G 模式抓视频动作并展示结果。
  func onTapRecord() {
    guard isRecordEnabled else { return }
    guard targetImei.isEmpty == false else {
      ToastCenter.shared.show("设备信息缺失")
      return
    }

    if isAnyLivePlaying {
      ToastCenter.shared.show("本地录像暂未开放")
      return
    }

    isVideoCaptureLoading = true
    let camera = preferredCamera
    let camMode = captureCameraMode
    let imei = targetImei
    Task {
      let result = await ActionAPI.shared.realTimeVideo(imei: imei, camera: camera, duration: 15)
      await MainActor.run {
        isVideoCaptureLoading = false

        guard
          let item = result?.first,
          let urlString = item.url ?? item.urlThumb,
          let url = URL(string: urlString)
        else {
          ToastCenter.shared.show("抓视频失败，请稍后再试")
          return
        }

        showPreview(LiveCapturePreview(kind: .video, url: url, id: item.id, cam: camMode))
      }
    }
  }

  /// 处理 Wi-Fi 模式主按钮点击，并按当前模式分发动作。
  func onTapWifiCaptureAction() {
    switch wifiCaptureActionMode {
    case .photo:
      onTapWifiSnapshot()
    case .video:
      onTapWifiRecord()
    }
  }

  /// 处理 Wi-Fi 模式截帧动作。
  func onTapWifiSnapshot() {
    WifiDocLog.info("Step C1 Begin: Wi-Fi 本地截帧")
    guard isWifiCaptureEnabled else {
      if isAnyLivePlaying == false {
        ToastCenter.shared.show("请先播放视频后再截帧")
      }
      WifiDocLog.info("Step C1 End: failed, capture disabled")
      return
    }
    if isWifiRecording {
      ToastCenter.shared.show("录制中，请先停止录制")
      WifiDocLog.info("Step C1 End: failed, recording in progress")
      return
    }

    isSnapshotLoading = true
    let channel = preferredCamera
    defer {
      isSnapshotLoading = false
    }

    guard let image = currentPlayerBridge.screenshot(channel: channel) else {
      ToastCenter.shared.show("截帧失败，请确认视频已出画面")
      WifiDocLog.info("Step C1 End: failed, screenshot nil, channel=\(channel)")
      return
    }
    guard let data = image.jpegData(compressionQuality: 0.92) else {
      ToastCenter.shared.show("截帧失败，请稍后再试")
      WifiDocLog.info("Step C1 End: failed, jpeg encode error")
      return
    }
    do {
      let outputURL = makeWifiCaptureOutputURL(prefix: "wifi_snapshot", ext: "jpg")
      try data.write(to: outputURL, options: .atomic)
      showPreview(LiveCapturePreview(kind: .photo, url: outputURL, id: nil, cam: captureCameraMode))
      WifiDocLog.info("Step C1 End: success, path=\(outputURL.path)")
    } catch {
      ToastCenter.shared.show("截帧失败，请稍后再试")
      WifiDocLog.info("Step C1 End: failed, write error=\(error.localizedDescription)")
    }
  }

  /// 处理 Wi-Fi 模式录制动作。
  func onTapWifiRecord() {
    if isWifiRecording {
      WifiDocLog.info("Step C2 End: stop Wi-Fi local recording")
      stopWifiRecording(showResult: true)
      return
    }
    WifiDocLog.info("Step C2 Begin: start Wi-Fi local recording")
    guard isWifiCaptureEnabled else {
      if isAnyLivePlaying == false {
        ToastCenter.shared.show("请先播放视频后再录制")
      }
      WifiDocLog.info("Step C2 End: failed, capture disabled")
      return
    }
    startWifiRecording()
  }

  var preferredCamera: Int {
    captureCameraMode == .rear ? 2 : 1
  }

  func stopWifiRecording(showResult: Bool) {
    if let consumerId = wifiRecordConsumerId, let wifiBridge = currentPlayerBridge as? XCBridge4Wifi {
      wifiBridge.removeExternalConsumer(consumerId)
    }
    wifiRecordConsumerId = nil

    let outputURL = wifiRecordFileURL
    let startedAt = wifiRecordStartTime
    let hasRecorder = (wifiRecorder != nil)
    wifiRecorder?.stop()
    clearWifiRecordState()

    guard showResult else { return }
    guard hasRecorder, let outputURL else {
      ToastCenter.shared.show("录制失败，请稍后再试")
      WifiDocLog.info("Step C2 End: failed, recorder missing")
      return
    }

    let duration = Date().timeIntervalSince(startedAt ?? Date())
    if duration < 0.8 {
      ToastCenter.shared.show("录制时间过短")
      WifiDocLog.info("Step C2 End: failed, too short duration=\(duration)")
      return
    }

    if FileManager.default.fileExists(atPath: outputURL.path) == false {
      ToastCenter.shared.show("录制失败，请稍后再试")
      WifiDocLog.info("Step C2 End: failed, file missing path=\(outputURL.path)")
      return
    }

    showPreview(LiveCapturePreview(kind: .video, url: outputURL, id: nil, cam: captureCameraMode))
    WifiDocLog.info("Step C2 End: success, path=\(outputURL.path)")
  }

  private func startWifiRecording() {
    guard isLiveWifiMode else { return }
    guard let wifiBridge = currentPlayerBridge as? XCBridge4Wifi else {
      ToastCenter.shared.show("当前不是 Wi-Fi 预览会话")
      return
    }
    guard wifiRecordConsumerId == nil else { return }

    let outputURL = makeWifiCaptureOutputURL(prefix: "wifi_record", ext: "mp4")
    wifiRecordFileURL = outputURL
    wifiRecordStartTime = Date()
    wifiRecordKeyFrameReady = false
    wifiRecorder = nil
    wifiRecordAudioFormatHint = nil

    let consumerId = wifiBridge.addExternalConsumer(
      onVideo: { [weak self] model in
        Task { @MainActor in
          self?.handleWifiRecordVideoPacket(model)
        }
      },
      onAudio: { [weak self] model in
        Task { @MainActor in
          self?.handleWifiRecordAudioPacket(model)
        }
      },
      onDisconnect: { [weak self] _ in
        Task { @MainActor in
          self?.stopWifiRecording(showResult: false)
        }
      }
    )
    wifiRecordConsumerId = consumerId
    isWifiRecording = true
    WifiDocLog.info("Step C2 Data: recording=true, file=\(outputURL.lastPathComponent)")
  }

  private func handleWifiRecordVideoPacket(_ packet: CallAVPacketModel) {
    guard isWifiRecording else { return }
    guard packet.source == 0 || packet.source == 1 else { return }
    guard packet.isVideo else { return }
    guard let payload = packet.payload, !payload.isEmpty else { return }
    guard let outputURL = wifiRecordFileURL else { return }

    if wifiRecorder == nil {
      let recorder = XCAVRecord(
        avFilePath: outputURL.path,
        audioRate: 8000,
        audioChannel: 1,
        videoFormat: XCAVFormat(rawValue: Int(packet.avFormat)) ?? .H264,
        audioFormat: wifiRecordAudioFormatHint ?? .G711a,
        fps: 15
      )
      wifiRecorder = recorder
      wifiRecordKeyFrameReady = false
    }

    if packet.aviFrame == 1 {
      wifiRecordKeyFrameReady = true
    }
    guard wifiRecordKeyFrameReady, let recorder = wifiRecorder else { return }
    recorder.writeAVData(
      withAVData: payload,
      streamType: XCAVFormat(rawValue: Int(packet.avFormat)) ?? .H264,
      iFrame: Int(packet.aviFrame),
      timestamp: Int(packet.timestamp)
    )
  }

  private func handleWifiRecordAudioPacket(_ packet: CallAVPacketModel) {
    guard isWifiRecording else { return }
    guard packet.source == 0 || packet.source == 1 else { return }
    guard packet.isVideo == false else { return }
    wifiRecordAudioFormatHint = XCAVFormat(rawValue: Int(packet.avFormat))
    guard let payload = packet.payload, !payload.isEmpty else { return }
    guard let recorder = wifiRecorder else { return }

    recorder.writeAVData(
      withAVData: payload,
      streamType: XCAVFormat(rawValue: Int(packet.avFormat)) ?? .G711a,
      iFrame: Int(packet.aviFrame),
      timestamp: Int(packet.timestamp)
    )
  }

  private func clearWifiRecordState() {
    isWifiRecording = false
    wifiRecorder = nil
    wifiRecordKeyFrameReady = false
    wifiRecordFileURL = nil
    wifiRecordStartTime = nil
    wifiRecordAudioFormatHint = nil
  }

  private func makeWifiCaptureOutputURL(prefix: String, ext: String) -> URL {
    let folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("wifi_live_capture", isDirectory: true)
    if FileManager.default.fileExists(atPath: folder.path) == false {
      try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "\(prefix)_\(formatter.string(from: Date()))_\(UUID().uuidString.prefix(6)).\(ext)"
    return folder.appendingPathComponent(fileName)
  }
}
