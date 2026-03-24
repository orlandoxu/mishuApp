import Foundation
import UIKit

@MainActor
final class TCardPlaybackController {
  enum ControllerError: LocalizedError {
    case missingLoginInfo
    case sdkInitFailed
    case connectFailed
    case notPrepared
    case playFailed

    var errorDescription: String? {
      switch self {
      case .missingLoginInfo:
        return "缺少直播登录信息"
      case .sdkInitFailed:
        return "直播SDK初始化失败"
      case .connectFailed:
        return "连接设备失败"
      case .notPrepared:
        return "播放器未初始化"
      case .playFailed:
        return "回放失败"
      }
    }
  }

  var onPlaybackTimeMs: ((Int64) -> Void)?
  var onPlaybackEnded: (() -> Void)?
  var onDisconnected: ((String) -> Void)?

  private var did: String?

  private var playerView: XCPlayerView?
  /// 渲染通道（播放器显示的画面通道：前摄/后摄）。
  private var acceptedChannel: Int = 0
  // 回放控制通道（historyPlay/historyPause/historyPlayFast 使用的通道）。
  // 注意：按 fileId 回放时，SDK 侧通常要求传 0。
  private var historyControlChannel: Int = 0
  private var bridgeConsumerId: UUID?
  private var bridgeConsumerUsesWifi: Bool = false
  private var prefersLocalWifiPlayback: Bool = false

  private var firstPacketTimestampMs: Int64 = 0 // 当前播放会话收到的首帧时间戳（用于计算播放进度增量）。
  private var anchorPlayTimeMs: Int64 = 0 // 业务时间轴锚点：当前回放开始时对应的业务时间（毫秒）。
  private var playbackEndTimeMs: Int64 = 0 // 当前片段的业务结束时间（毫秒），用于触发“片段播完”。
  private var currentFileId: Int = 0 // 正在播放的历史文件 ID（用于 pause/日志/录制关联）。
  private var historyPlayInfo: HistoryPlayModel? // historyPlay 返回的音视频参数（fps、codec、rate 等）。
  private var videoFormat: Int = -1 // 当前视频编码格式（首帧确定；-1 表示未确定）。
  private var playbackGeneration: Int = 0 // 回放会话代号：用于丢弃过期异步回调，避免退出后误处理旧会话。
  private var isAudioEnabled: Bool = false // 当前是否允许本地扬声器输出音频。
  private var recorder: XCAVRecord? // 本地录像器实例（nil 表示未处于录制会话）。
  private var isRecording: Bool = false // 录制状态开关。
  private var keyFrameReady: Bool = false // 录制门控：收到关键帧后才允许写入视频数据。
  private var hasLoggedFirstVideoPacket: Bool = false // 首个视频包日志是否已打印（防止重复刷日志）。
  private var hasLoggedFirstAudioPacket: Bool = false // 首个音频包日志是否已打印（防止重复刷日志）。
  private var hasNotifiedPlaybackEnded: Bool = false // 当前回放会话是否已触发过结束回调。
  private var isHistoryPacketAccepted: Bool = false // 历史回放收包门控：暂停/释放后立即丢包，避免残留帧误渲染。
  private var lastVideoPacketTimestampMs: Int64 = -1 // 诊断用：记录上一帧视频原始时间戳，便于排查跳变/停滞。

  /// 设置回放连接模式：`true` 走 Wi-Fi 本地桥，`false` 走 4G/云桥。
  func setPreferLocalWifiPlayback(_ enabled: Bool) {
    guard prefersLocalWifiPlayback != enabled else { return }
    prefersLocalWifiPlayback = enabled
    unregisterBridgeConsumer()
    ensureBridgeConsumerRegistered()
    TCardReplayLog.info("setPreferLocalWifiPlayback enabled=\(enabled)")
  }

  /// 注册桥接层回调，直接分发历史回放音视频包（仅注册一次）。
  private func ensureBridgeConsumerRegistered() {
    guard bridgeConsumerId == nil else { return }
    let register: (
      @escaping (CallAVPacketModel) -> Void,
      @escaping (CallAVPacketModel) -> Void,
      @escaping (String) -> Void
    ) -> UUID

    if prefersLocalWifiPlayback {
      register = { onVideo, onAudio, onDisconnect in
        XCBridge4Wifi.shared.addExternalConsumer(
          onVideo: onVideo,
          onAudio: onAudio,
          onDisconnect: onDisconnect
        )
      }
    } else {
      register = { onVideo, onAudio, onDisconnect in
        XCBridge4Network.shared.addExternalConsumer(
          onVideo: onVideo,
          onAudio: onAudio,
          onDisconnect: onDisconnect
        )
      }
    }

    bridgeConsumerUsesWifi = prefersLocalWifiPlayback
    bridgeConsumerId = register(
      { [weak self] model in
        guard let self else { return }
        // 对齐 Android：仅在非本地模式时限定 source=2；本地模式放开 source 过滤。
        if self.prefersLocalWifiPlayback == false, model.source != 2 { return }
        self.handleIncomingPacket(model)
      },
      { [weak self] model in
        guard let self else { return }
        if self.prefersLocalWifiPlayback == false, model.source != 2 { return }
        self.handleIncomingPacket(model)
      },
      { [weak self] did in
        guard let self else { return }
        self.dispatchToMain {
          self.onDisconnected?(did)
        }
      }
    )
  }

  /// 取消桥接层回调注册，页面退出或切设备时调用，避免重复收包。
  private func unregisterBridgeConsumer() {
    guard let id = bridgeConsumerId else { return }
    if bridgeConsumerUsesWifi {
      XCBridge4Wifi.shared.removeExternalConsumer(id)
    } else {
      XCBridge4Network.shared.removeExternalConsumer(id)
    }
    bridgeConsumerId = nil
  }

  /// 绑定播放器渲染视图并初始化基础状态（切设备时会先释放旧资源）。
  func bindAndInit(deviceId: String, channel: Int, renderView: UIView) {
    TCardReplayLog.info("bindAndInit did=\(deviceId) channel=\(channel) hasPlayer=\(playerView != nil)")
    if did != deviceId {
      release()
      did = deviceId
    }

    acceptedChannel = channel
    ensureBridgeConsumerRegistered()

    if let playerView {
      if playerView.superview !== renderView {
        playerView.removeFromSuperview()
        playerView.frame = renderView.bounds
        playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView.addSubview(playerView)
      }
      playerView.setChannel([NSNumber(value: channel)])
      updateLayout(in: renderView)
      return
    }

    let player = XCPlayerView(did: deviceId, zoomType: 1, osd: 1)
    player.setPlayAudio(false)
    player.setChannel([NSNumber(value: channel)])
    player.frame = renderView.bounds
    player.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    renderView.addSubview(player)
    playerView = player
    updateLayout(in: renderView)
  }

  /// 同步播放器内部渲染层布局到当前容器尺寸。
  func updateLayout(in renderView: UIView) {
    guard let playerView else { return }
    let bounds = renderView.bounds
    guard bounds.width > 0, bounds.height > 0 else { return }
    playerView.frame = bounds
    playerView.layoutRenderChild(bounds)
    playerView.shouldReload(true)
  }

  /// 确保设备连接可用，返回可执行回放命令的 `XCSDKConnect`。
  func ensureConnected(deviceId: String) async throws -> XCSDKConnect {
    TCardReplayLog.info("ensureConnected start did=\(deviceId)")
    if did != deviceId {
      release()
      did = deviceId
    }
    ensureBridgeConsumerRegistered()
    do {
      let connect: XCSDKConnect
      if prefersLocalWifiPlayback {
        XCBridge4Wifi.shared.setConnectionPolicy(.localLan)
        connect = try await XCBridge4Wifi.shared.ensureConnectedForExternal(did: deviceId)
      } else {
        connect = try await XCBridge4Network.shared.ensureConnectedForExternal(did: deviceId)
      }
      TCardReplayLog.info("ensureConnected done did=\(deviceId)")
      return connect
    } catch {
      TCardReplayLog.error("ensureConnected error did=\(deviceId) msg=\(error.localizedDescription)")
      throw error
    }
  }

  /// 发起历史回放：设置音视频参数，并开始接收历史流数据（直通渲染，不经过 PlayQueue）。
  func playHistory(
    deviceId: String,
    channel: Int,
    fileId: Int,
    startTimeMs: Int64,
    endTimeMs: Int64,
    audioEnabled: Bool
  ) async throws {
    guard let playerView else { throw ControllerError.notPrepared }
    _ = playerView.clearCurrentFrame()

    // renderChannel 用于“画面显示”；controlChannel 用于“回放控制命令”。
    // 两者可能不同（典型：fileId 回放时 controlChannel=0）。
    let controlChannel = resolveHistoryControlChannel(renderChannel: channel, fileId: fileId)
    TCardReplayLog.info("playHistory start did=\(deviceId) renderChannel=\(channel) controlChannel=\(controlChannel) fileId=\(fileId) startMs=\(startTimeMs) endMs=\(endTimeMs) audio=\(audioEnabled)")
    let connect = try await ensureConnected(deviceId: deviceId)
    playbackGeneration &+= 1
    let playGeneration = playbackGeneration

    isAudioEnabled = audioEnabled
    playerView.setPlayAudio(false)
    acceptedChannel = channel
    historyControlChannel = controlChannel
    playerView.setChannel([NSNumber(value: channel)])

    firstPacketTimestampMs = 0
    anchorPlayTimeMs = startTimeMs
    playbackEndTimeMs = endTimeMs
    currentFileId = fileId
    historyPlayInfo = nil
    videoFormat = -1
    hasLoggedFirstVideoPacket = false
    hasLoggedFirstAudioPacket = false
    hasNotifiedPlaybackEnded = false
    isHistoryPacketAccepted = false
    lastVideoPacketTimestampMs = -1

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      connect.historyPlayAsync(withChannel: controlChannel, fileID: fileId, startTime: Int(startTimeMs)) { [weak self] model, error in
        guard let self else { return }
        guard self.playbackGeneration == playGeneration else {
          TCardReplayLog.info("historyPlayAsync ignored stale callback fileId=\(fileId) generation=\(playGeneration) current=\(self.playbackGeneration)")
          continuation.resume(returning: ())
          return
        }
        if let error {
          TCardReplayLog.error("historyPlayAsync error did=\(deviceId) fileId=\(fileId) msg=\(error.localizedDescription)")
          continuation.resume(throwing: error)
          return
        }
        self.historyPlayInfo = model
        if model.fps == 0 { model.fps = 15 }
        playerView.setVideoFps(Int(model.fps))
        self.configureAudioPlayer(playerView: playerView, with: model)
        playerView.setPlayAudio(self.isAudioEnabled)
        self.isHistoryPacketAccepted = true
        TCardReplayLog.info("historyPlayAsync ok did=\(deviceId) fileId=\(fileId) fps=\(model.fps) rate=\(model.rate) track=\(model.track) bit=\(model.bit) codec=\(model.codec)")
        continuation.resume(returning: ())
      }
    }
  }

  /// 暂停历史回放，保留连接以便快速恢复。
  func pauseHistory() async {
    playbackGeneration &+= 1
    let targetDid = did
    let targetFileId = currentFileId
    let targetControlChannel = historyControlChannel
    if isRecording {
      _ = await stopRecording()
    }
    isHistoryPacketAccepted = false
    hasNotifiedPlaybackEnded = false
    guard let targetDid, targetDid.isEmpty == false else { return }
    await sendHistoryPause(deviceId: targetDid, fileId: targetFileId, controlChannel: targetControlChannel)
    TCardReplayLog.info("pauseHistory done fileId=\(targetFileId) controlChannel=\(targetControlChannel)")
  }

  /// 开关本地音频输出（只影响播放，不重新发起回放命令）。
  func setAudioEnabled(_ enabled: Bool) {
    isAudioEnabled = enabled
    playerView?.setPlayAudio(enabled)
  }

  /// 设置历史回放倍速（发送控制命令到设备）。
  func setPlaybackRate(_ rate: Int) async {
    guard let did, did.isEmpty == false else { return }
    let connect: XCSDKConnect
    if prefersLocalWifiPlayback {
      guard let wifiConnect = try? await XCBridge4Wifi.shared.ensureConnectedForExternal(did: did) else { return }
      connect = wifiConnect
    } else {
      guard let networkConnect = try? await XCBridge4Network.shared.ensureConnectedForExternal(did: did) else { return }
      connect = networkConnect
    }
    await withCheckedContinuation { continuation in
      connect.historyPlayFastAsync(withChannel: historyControlChannel, inrate: rate) { _, _, _ in
        continuation.resume()
      }
    }
    TCardReplayLog.info("setPlaybackRate rate=\(rate) controlChannel=\(historyControlChannel)")
  }

  /// 截取当前播放器画面帧。
  func screenshot() -> UIImage? {
    playerView?.screenshort()
  }

  /// 开始本地录制：基于当前回放参数创建录制器并准备写帧。
  func startRecording() throws {
    guard recorder == nil else { return }
    guard let did else { throw ControllerError.notPrepared }
    guard let historyPlayInfo else { throw ControllerError.playFailed }
    guard videoFormat != -1 else { throw ControllerError.playFailed }

    let avRecorder = XCAVRecord(
      avFilePath: nil,
      audioRate: Int(historyPlayInfo.rate),
      audioChannel: Int(historyPlayInfo.track),
      videoFormat: XCAVFormat(rawValue: videoFormat) ?? .H264,
      audioFormat: XCAVFormat(rawValue: Int(historyPlayInfo.codec)) ?? .G711a,
      fps: Int(historyPlayInfo.fps)
    )
    avRecorder.setPrintLog()
    recorder = avRecorder
    isRecording = true
    keyFrameReady = false
    _ = did
    TCardReplayLog.info("startRecording did=\(did)")
  }

  /// 停止本地录制并保存到系统相册，返回是否保存成功。
  func stopRecording() async -> Bool {
    guard let recorder else { return false }
    isRecording = false
    keyFrameReady = false
    recorder.stop()
    self.recorder = nil

    let fileName = did
    return await withCheckedContinuation { continuation in
      XCFileTool.saveAVFile(withAlbumName: nil, avFilePath: nil, fileName: fileName, shouldMoveFile: true) { succeed, _ in
        continuation.resume(returning: succeed)
      }
    }
  }

  /// 彻底释放回放资源（播放器、录制器、桥接回调）。
  func release() {
    playbackGeneration &+= 1
    let targetDid = did
    let targetFileId = currentFileId
    let targetControlChannel = historyControlChannel
    isHistoryPacketAccepted = false
    if let targetDid, targetDid.isEmpty == false {
      Task { @MainActor in
        await self.sendHistoryPause(deviceId: targetDid, fileId: targetFileId, controlChannel: targetControlChannel)
      }
    }
    if let playerView {
      playerView.setPlayAudio(false)
      playerView.releaseVideo()
      playerView.removeFromSuperview()
    }
    playerView = nil
    acceptedChannel = 0
    historyControlChannel = 0
    firstPacketTimestampMs = 0
    anchorPlayTimeMs = 0
    playbackEndTimeMs = 0
    currentFileId = 0
    historyPlayInfo = nil
    videoFormat = -1
    isAudioEnabled = false
    recorder = nil
    isRecording = false
    keyFrameReady = false
    hasLoggedFirstVideoPacket = false
    hasLoggedFirstAudioPacket = false
    hasNotifiedPlaybackEnded = false
    lastVideoPacketTimestampMs = -1
    did = nil
    unregisterBridgeConsumer()
    TCardReplayLog.info("release done")
  }

  /// 处理桥接回调的单帧数据：视频负责渲染与时间推进，音频按开关播放。
  private func handleIncomingPacket(_ avModel: CallAVPacketModel) {
    guard isHistoryPacketAccepted else { return }
    guard let playerView else { return }
    if currentFileId > 0, avModel.fileID > 0, Int(avModel.fileID) != currentFileId {
      return
    }

    if avModel.isVideo {
      // 视频包必须匹配当前渲染通道，否则可能出现串画面。
      guard acceptedChannel == 0 || acceptedChannel == Int(avModel.avChannel) else { return }
      if videoFormat == -1 {
        videoFormat = Int(avModel.avFormat)
        playerView.setVideoFormat(videoFormat, render: 0)
      }
      playerView.isRenderVideo = true
      playerView.playVideo(withData: avModel)

      if firstPacketTimestampMs == 0 {
        firstPacketTimestampMs = Int64(avModel.timestamp)
      }
      if hasLoggedFirstVideoPacket == false {
        hasLoggedFirstVideoPacket = true
        TCardReplayLog.info("firstVideoPacket source=\(avModel.source) channel=\(avModel.avChannel) format=\(avModel.avFormat) ts=\(avModel.timestamp) iFrame=\(avModel.aviFrame) fileId=\(currentFileId)")
      }
      let rawPacketTs = Int64(avModel.timestamp)
      let playTimeMs = resolvePlaybackTimeMs(rawPacketTs: rawPacketTs)
      let elapsedMs = max(0, rawPacketTs - firstPacketTimestampMs)
      logTimelineTrace(avModel: avModel, rawPacketTs: rawPacketTs, playTimeMs: playTimeMs, elapsedMs: elapsedMs)
      dispatchToMain {
        self.onPlaybackTimeMs?(playTimeMs)
      }
      if playbackEndTimeMs > 0, playTimeMs >= playbackEndTimeMs, hasNotifiedPlaybackEnded == false {
        hasNotifiedPlaybackEnded = true
        dispatchToMain {
          self.onPlaybackEnded?()
        }
      }

      if isRecording {
        if avModel.aviFrame == 1 {
          keyFrameReady = true
        }
        if keyFrameReady, let recorder {
          guard let payload = avModel.payload else { return }
          recorder.writeAVData(
            withAVData: payload,
            streamType: XCAVFormat(rawValue: Int(avModel.avFormat)) ?? .H264,
            iFrame: Int(avModel.aviFrame),
            timestamp: Int(avModel.timestamp)
          )
        }
      }
      return
    }

    guard isAudioEnabled else { return }
    let audioChannel = Int(avModel.avChannel)
    // 音频允许 channel=0（不少设备历史音频固定走 0），
    // 同时兼容“与渲染通道一致”的音频包。
    guard acceptedChannel == 0 || acceptedChannel == audioChannel || audioChannel == 0 else { return }
    if hasLoggedFirstAudioPacket == false {
      hasLoggedFirstAudioPacket = true
      TCardReplayLog.info("firstAudioPacket source=\(avModel.source) channel=\(avModel.avChannel) format=\(avModel.avFormat) ts=\(avModel.timestamp) fileId=\(avModel.fileID)")
    }
    playerView.playAudio(withData: avModel)
  }

  /// 计算历史回放控制通道：fileId 回放固定 0，其它场景回退到渲染通道。
  private func resolveHistoryControlChannel(renderChannel: Int, fileId: Int) -> Int {
    // 按文件回放：沿用 Android 逻辑，固定控制通道为 0。
    // 非 fileId 场景：退回渲染通道。
    if fileId > 0 { return 0 }
    return max(renderChannel, 0)
  }

  /// 按历史回放返回参数配置音频解码器，并对异常值做兜底。
  private func configureAudioPlayer(playerView: XCPlayerView, with model: HistoryPlayModel) {
    // 历史回放返回的音频参数偶发为 0，做兜底避免播放器无法初始化音频解码。
    let codec = model.codec > 0 ? Int(model.codec) : 21
    let rate = model.rate > 0 ? Int(model.rate) : 8000
    let bit = model.bit > 0 ? Int(model.bit) : 16
    let track = model.track > 0 ? Int(model.track) : 1
    if model.codec <= 0 || model.rate <= 0 || model.bit <= 0 || model.track <= 0 {
      TCardReplayLog.error("historyPlay audio params invalid codec=\(model.codec) rate=\(model.rate) bit=\(model.bit) track=\(model.track), fallback codec=\(codec) rate=\(rate) bit=\(bit) track=\(track)")
    }
    playerView.setAudioRate(rate, track: track, bit: bit, codec: codec, needCache: true)
  }

  /// 向设备发送 historyPause，通知设备端停止当前历史回放。
  private func sendHistoryPause(deviceId: String, fileId: Int, controlChannel: Int) async {
    let connect: XCSDKConnect
    if prefersLocalWifiPlayback {
      guard let wifiConnect = try? await XCBridge4Wifi.shared.ensureConnectedForExternal(did: deviceId) else { return }
      connect = wifiConnect
    } else {
      guard let networkConnect = try? await XCBridge4Network.shared.ensureConnectedForExternal(did: deviceId) else { return }
      connect = networkConnect
    }
    await withCheckedContinuation { continuation in
      connect.historyPauseAsync(withChannel: controlChannel, fileID: fileId) { _, _ in
        continuation.resume()
      }
    }
  }

  private func dispatchToMain(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async(execute: block)
    }
  }

  /// 计算 UI 播放时间：优先使用设备绝对时间；仅在相对时间戳场景走 anchor 映射。
  private func resolvePlaybackTimeMs(rawPacketTs: Int64) -> Int64 {
    if rawPacketTs > 1_500_000_000_000 {
      return rawPacketTs
    }
    if rawPacketTs > 1_500_000_000 {
      return rawPacketTs * 1000
    }
    let elapsedMs = max(0, rawPacketTs - firstPacketTimestampMs)
    return anchorPlayTimeMs + elapsedMs
  }

  /// 时间链路诊断日志（按帧打印）：设备原始 ts + 本地映射后的业务时间。
  private func logTimelineTrace(avModel: CallAVPacketModel, rawPacketTs: Int64, playTimeMs: Int64, elapsedMs: Int64) {
    let packetTs = rawPacketTs
    let deltaFromPrev = lastVideoPacketTimestampMs < 0 ? 0 : (packetTs - lastVideoPacketTimestampMs)
    let deltaFromFirst = packetTs - firstPacketTimestampMs
    let mappingMode: String
    if rawPacketTs > 1_500_000_000_000 {
      mappingMode = "device_abs_ms"
    } else if rawPacketTs > 1_500_000_000 {
      mappingMode = "device_abs_sec"
    } else {
      mappingMode = "relative_anchor"
    }
    let direction: String
    if lastVideoPacketTimestampMs < 0 {
      direction = "init"
    } else if deltaFromPrev > 0 {
      direction = "forward"
    } else if deltaFromPrev == 0 {
      direction = "same"
    } else {
      direction = "backward"
    }
    lastVideoPacketTimestampMs = packetTs

    TCardReplayLog.info(
      "TS_TRACE did=\(did ?? "") fileId=\(currentFileId) channel=\(avModel.avChannel) iFrame=\(avModel.aviFrame) " +
        "packetTs=\(packetTs) packetClock=\(formatDeviceTimestampForTrace(packetTs)) " +
        "mode=\(mappingMode) deltaPrev=\(deltaFromPrev) deltaFirst=\(deltaFromFirst) direction=\(direction) " +
        "anchorMs=\(anchorPlayTimeMs) elapsedMs=\(elapsedMs) mappedPlayMs=\(playTimeMs) mappedPlay=\(formatTimeForTrace(playTimeMs))"
    )
  }

  /// 把设备回包 timestamp 转成人类可读时间（自动识别秒/毫秒；否则标记为相对时间）。
  private func formatDeviceTimestampForTrace(_ ts: Int64) -> String {
    if ts > 1_500_000_000_000 {
      return formatTimeForTrace(ts)
    }
    if ts > 1_500_000_000 {
      return formatTimeForTrace(ts * 1000)
    }
    return "relative(\(ts))"
  }

  private func formatTimeForTrace(_ timeMs: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timeMs) / 1000)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    return formatter.string(from: date)
  }
}
