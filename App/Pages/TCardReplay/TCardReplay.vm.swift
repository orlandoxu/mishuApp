import Combine
import Foundation

enum TCardDownloadResult {
  case success
  case cancelled
  case failed(String)
}

@MainActor
final class TCardReplayViewModel: ObservableObject {
  @Published var tCardImei: String? = nil
  @Published var tCardAvailableDates: [Date] = []
  @Published var tCardSelectedDate: Date = .init()
  @Published var tCardSelectedTimeMs: Int64 = 0
  @Published var tCardRanges: [TCardReplayRange] = []
  @Published var tCardSegments: [TCardReplaySegment] = []
  @Published var tCardIsPlaying: Bool = false
  @Published var tCardIsMuted: Bool = true // 产品要求：回放默认静音，用户手动打开声音
  @Published var tCardIsRecording: Bool = false
  @Published var tCardSpeed: TCardPlaybackSpeed = .x1
  @Published var tCardChannel: Int = 1 // DONE-AI: 默认使用前摄通道
  @Published var tCardIsFullscreen: Bool = false
  @Published var tCardIsLoading: Bool = false
  @Published var tCardErrorMessage: String? = nil
  @Published var tCardIsDownloading: Bool = false
  @Published var tCardDownloadProgress: Int = 0
  @Published var tCardAlbumSaveSignal: Int = 0
  @Published private(set) var tCardIsWifiConnected: Bool = false
  @Published private(set) var tCardIsBridgeConnected: Bool = false
  @Published private(set) var tCardReplayMapPoint: TCardReplayGpsPoint? = nil

  @Published private(set) var currTCardVehicle: VehicleModel? = nil

  let tCardPlaybackController = TCardPlaybackController()
  var tCardAllRanges: [TCardReplayRange] = []
  private var tCardSelectedTimeByDay: [Int64: Int64] = [:]
  private var tCardReplayGpsPointsByDay: [Int64: [TCardReplayGpsPoint]] = [:]
  private var tCardReplayGpsLoadTask: Task<Void, Never>?
  private var tCardIsScrubbing: Bool = false
  private var tCardWasPlayingBeforeScrub: Bool = false
  private var tCardFreezeTimelineUiByGesture: Bool = false // 对齐 Android：seek 过程中冻结时间轴回写，直到新播放建立。
  private var tCardIgnorePlaybackUntilUptimeMs: Int64 = 0 // seek 后最多忽略 1 秒设备回调，随后必须恢复读取。
  private var tCardLastTimelineSecondMs: Int64 = -1 // 时间轴节流：仅按秒更新，避免每包刷新。

  private let vehiclesStore: VehiclesStore
  private let replayGpsService: TCardReplayGpsService
  private let replayDownloadService: TCardReplayDownloadService
  private let wifiStore: WifiStore
  private let imei: String
  private var cancellables: Set<AnyCancellable> = []

  init(
    imei: String,
    vehiclesStore: VehiclesStore = .shared,
    replayGpsService: TCardReplayGpsService? = nil,
    replayDownloadService: TCardReplayDownloadService = TCardReplayDownloadService(),
    wifiStore: WifiStore = .shared
  ) {
    self.imei = imei
    self.vehiclesStore = vehiclesStore
    self.replayGpsService = replayGpsService ?? TCardReplayGpsService.shared
    self.replayDownloadService = replayDownloadService
    self.wifiStore = wifiStore
    bindStore()
    tCardIsWifiConnected = wifiStore.isTargetWifiConnected
    tCardPlaybackController.setPreferLocalWifiPlayback(tCardIsWifiConnected)
    syncBridgeConnectionState()
  }

  deinit {
    let playbackController = tCardPlaybackController
    Task { @MainActor in
      playbackController.release()
    }
  }

  var currTCardDid: String {
    currTCardVehicle?.did ?? ""
  }

  /// 当前摄像头标题（用于 Header 按钮文案）。
  var tCardCameraTitle: String {
    cameraTitle(for: tCardChannel)
  }

  /// 当前设备可选的摄像头（前摄/后摄）。
  var tCardAvailableCameraChannels: [Int] {
    buildAvailableCameraChannels(from: tCardAllRanges)
  }

  /// 是否允许切换摄像头（至少有两个摄像头可选）。
  var tCardCanSwitchCamera: Bool {
    tCardAvailableCameraChannels.count > 1
  }

  /// 指定通道的摄像头标题（供 Header 菜单使用）。
  func tCardCameraTitleForChannel(_ channel: Int) -> String {
    cameraTitle(for: channel)
  }

  /// Header 菜单中当前选中的摄像头（做 0/1 前摄归一化）。
  var tCardSelectedCameraForMenu: Int {
    normalizedCameraChannel(tCardChannel)
  }

  /// 当前时间点是否存在“上一个回放区间”。
  var tCardCanSeekPreviousRange: Bool {
    previousSegmentIndex() != nil
  }

  /// 当前时间点是否存在“下一个回放区间”。
  var tCardCanSeekNextRange: Bool {
    nextSegmentIndex() != nil
  }

  /// 仅 Wi-Fi 连接设备时允许显示“下载”按钮。
  var tCardCanDownloadInCurrentMode: Bool {
    tCardIsWifiConnected
  }

  /// 页面首次进入时准备数据：同步车辆信息并触发回放初始化。
  func prepare() async {
    openTCardReplay(imei: imei)
    if currTCardVehicle == nil {
      await vehiclesStore.refresh()
      syncFromStore()
    }
  }

  /// 打开 T 卡回放会话：重置状态、绑定回调并拉取可回放数据。
  func openTCardReplay(imei: String) {
    tCardImei = imei
    syncFromStore()
    let isWifiConnected = wifiStore.isTargetWifiConnected
    tCardIsWifiConnected = isWifiConnected
    tCardPlaybackController.setPreferLocalWifiPlayback(isWifiConnected)
    syncBridgeConnectionState()
    resetOpenState()
    TCardReplayLog.info("open imei=\(imei) did=\(currTCardDid) channel=\(tCardChannel)")

    tCardPlaybackController.onPlaybackTimeMs = { [weak self] timeMs in
      guard let self else { return }
      if self.tCardIsScrubbing || self.tCardFreezeTimelineUiByGesture {
        return
      }
      if self.currentUptimeMs() < self.tCardIgnorePlaybackUntilUptimeMs {
        return
      }
      let secondMs = (timeMs / 1000) * 1000
      if self.tCardLastTimelineSecondMs == secondMs {
        return
      }
      self.tCardLastTimelineSecondMs = secondMs
      self.updateSelectedTime(secondMs)
    }

    tCardPlaybackController.onPlaybackEnded = { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        await self.handleTCardPlaybackEnded()
      }
    }

    tCardPlaybackController.onDisconnected = { [weak self] did in
      guard let self else { return }
      self.tCardIsPlaying = false
      self.tCardIsScrubbing = false
      self.tCardWasPlayingBeforeScrub = false
      self.tCardFreezeTimelineUiByGesture = false
      self.tCardIgnorePlaybackUntilUptimeMs = 0
      self.tCardLastTimelineSecondMs = -1
      self.tCardErrorMessage = "设备连接已断开: \(did)"
      TCardReplayLog.error("disconnected did=\(did)")
    }

    Task { @MainActor in
      await refreshTCardDatesAndSegments()
    }
  }

  /// 关闭 T 卡回放会话并释放资源。
  func closeTCardReplay() {
    tCardReplayGpsLoadTask?.cancel()
    tCardReplayGpsLoadTask = nil
    replayDownloadService.cancelCurrentDownload()
    tCardPlaybackController.release()
    tCardImei = nil
    tCardRanges = []
    tCardSegments = []
    tCardAvailableDates = []
    tCardAllRanges = []
    tCardReplayGpsPointsByDay = [:]
    tCardReplayMapPoint = nil
    tCardIsPlaying = false
    tCardIsRecording = false
    tCardIsLoading = false
    tCardIsDownloading = false
    tCardDownloadProgress = 0
    tCardErrorMessage = nil
    tCardIsBridgeConnected = false
    tCardFreezeTimelineUiByGesture = false
    tCardIgnorePlaybackUntilUptimeMs = 0
    tCardLastTimelineSecondMs = -1
    if vehiclesStore.liveImei == nil {
      XCBridge4Network.shared.releaseAll()
    }
  }

  /// 拉取设备历史范围并生成“可选日期 + 当天片段”数据。
  func refreshTCardDatesAndSegments() async {
    let did = currTCardDid
    guard did.isEmpty == false else {
      tCardErrorMessage = "设备异常，未查询到DID"
      TCardReplayLog.error("refreshDatesAndSegments failed: empty did imei=\(tCardImei ?? "")")
      return
    }

    tCardIsLoading = true
    tCardErrorMessage = nil
    TCardReplayLog.info("refreshDatesAndSegments start did=\(did)")

    do {
      let connect = try await tCardPlaybackController.ensureConnected(deviceId: did)
      let ranges = try await fetchTCardAllRanges(connect: connect)
      tCardAllRanges = ranges
      let availableChannels = buildAvailableCameraChannels(from: ranges)
      if availableChannels.contains(normalizedCameraChannel(tCardChannel)) == false {
        tCardChannel = availableChannels.first ?? 1
      }
      let dates = buildTCardAvailableDates(from: ranges)
      tCardAvailableDates = dates
      if let first = dates.first { tCardSelectedDate = first }
      buildTCardSegmentsForSelectedDate()
      loadReplayGpsForSelectedDate()
      tCardIsLoading = false
      TCardReplayLog.info("refreshDatesAndSegments done segments=\(tCardSegments.count) selectedTimeMs=\(tCardSelectedTimeMs)")
    } catch {
      tCardIsLoading = false
      tCardErrorMessage = error.localizedDescription
      TCardReplayLog.error("refreshDatesAndSegments error: \(error.localizedDescription)")
    }
  }

  /// 选择某一天并刷新当天时间轴片段。
  func selectTCardDate(_ date: Date) {
    let currentDayStartMs = dayStartMs(for: tCardSelectedDate)
    tCardSelectedTimeByDay[currentDayStartMs] = tCardSelectedTimeMs
    tCardSelectedDate = date
    buildTCardSegmentsForSelectedDate()
    loadReplayGpsForSelectedDate()
  }

  /// 仅刷新当前已选日期的片段数据（不重新拉设备）。
  func refreshTCardSegmentsForSelectedDate() async {
    buildTCardSegmentsForSelectedDate()
    loadReplayGpsForSelectedDate()
  }

  /// 播放/暂停切换入口。
  func toggleTCardPlayback() {
    if tCardIsPlaying {
      Task { @MainActor in
        await pauseTCardPlayback()
      }
    } else {
      Task { @MainActor in
        await playTCardAtSelectedTime()
      }
    }
  }

  /// 静音开关：同步 UI 状态并通知播放控制器。
  func toggleTCardMute() {
    tCardIsMuted.toggle()
    tCardPlaybackController.setAudioEnabled(!tCardIsMuted)
  }

  /// 设置回放倍速并下发到控制器。
  func setTCardSpeed(_ speed: TCardPlaybackSpeed) {
    tCardSpeed = speed
    Task { @MainActor in
      await tCardPlaybackController.setPlaybackRate(speed.rawValue)
    }
  }

  /// 拖动到指定时间点；若正在播放则从新时间继续播。
  func seekTCard(to timeMs: Int64) {
    updateSelectedTime(timeMs)
    lockPlaybackCallbackForOneSecond()
    if tCardIsScrubbing {
      return
    }
    if tCardIsPlaying {
      tCardFreezeTimelineUiByGesture = true
      Task { @MainActor in
        await restartPlaybackAtSelectedTime()
      }
    }
  }

  /// 时间轴开始拖拽时先暂停播放，避免播放器在 seek 过程中重入导致卡死。
  func beginTimelineScrub() {
    guard tCardIsScrubbing == false else { return }
    tCardIsScrubbing = true
    tCardFreezeTimelineUiByGesture = true
    lockPlaybackCallbackForOneSecond()
    tCardWasPlayingBeforeScrub = tCardIsPlaying
    guard tCardWasPlayingBeforeScrub else { return }
    Task { @MainActor in
      await pauseTCardPlayback()
    }
  }

  /// 时间轴结束拖拽：定位到最终时间点，并在原本播放状态下恢复播放。
  func endTimelineScrub(at timeMs: Int64) {
    updateSelectedTime(timeMs)
    lockPlaybackCallbackForOneSecond()
    let shouldResume = tCardWasPlayingBeforeScrub
    tCardIsScrubbing = false
    tCardWasPlayingBeforeScrub = false
    guard shouldResume else {
      tCardFreezeTimelineUiByGesture = false
      return
    }
    Task { @MainActor in
      await restartPlaybackAtSelectedTime()
    }
  }

  /// 切换回放摄像头（仅当设备支持多摄像头时生效）。
  func switchTCardCamera(to channel: Int) {
    guard tCardAvailableCameraChannels.contains(channel) else { return }
    guard normalizedCameraChannel(tCardChannel) != normalizedCameraChannel(channel) else { return }
    tCardChannel = channel
    buildTCardSegmentsForSelectedDate()
    if resolveSegment(for: tCardSelectedTimeMs) == nil, let first = tCardSegments.first {
      updateSelectedTime(first.startTimeMs)
    }
    if tCardIsPlaying {
      Task { @MainActor in
        if self.tCardSegments.isEmpty {
          await self.pauseTCardPlayback()
          self.tCardErrorMessage = "当前摄像头暂无回放数据"
          return
        }
        await self.playTCardAtSelectedTime()
      }
    }
  }

  /// 跳转到上一个回放区间起点。
  func seekToPreviousRange() {
    guard let index = previousSegmentIndex() else { return }
    seekTCard(to: tCardSegments[index].startTimeMs)
  }

  /// 跳转到下一个回放区间起点。
  func seekToNextRange() {
    guard let index = nextSegmentIndex() else { return }
    seekTCard(to: tCardSegments[index].startTimeMs)
  }

  /// 暂停回放并重置播放中/录制中状态。
  func pauseTCardPlayback() async {
    tCardIsPlaying = false
    tCardIsRecording = false
    tCardIgnorePlaybackUntilUptimeMs = 0
    tCardLastTimelineSecondMs = -1
    await tCardPlaybackController.pauseHistory()
  }

  /// 从当前选中时间点发起回放。
  func playTCardAtSelectedTime() async {
    let did = currTCardDid
    guard did.isEmpty == false else {
      tCardErrorMessage = "设备异常，未查询到DID"
      TCardReplayLog.error("play failed: empty did imei=\(tCardImei ?? "")")
      return
    }

    guard let segment = resolveSegment(for: tCardSelectedTimeMs) ?? tCardSegments.first else {
      tCardErrorMessage = "当前时间点无回放数据"
      TCardReplayLog.error("play failed: no segment at timeMs=\(tCardSelectedTimeMs) segments=\(tCardSegments.count)")
      return
    }

    tCardErrorMessage = nil
    tCardIsPlaying = true
    if tCardChannel != segment.channel {
      tCardChannel = segment.channel
    }
    TCardReplayLog.info("play start did=\(did) channel=\(segment.channel) fileId=\(segment.fileId) startMs=\(tCardSelectedTimeMs) endMs=\(segment.endTimeMs) muted=\(tCardIsMuted)")
    do {
      try await tCardPlaybackController.playHistory(
        deviceId: did,
        channel: segment.channel,
        fileId: segment.fileId,
        startTimeMs: tCardSelectedTimeMs,
        endTimeMs: segment.endTimeMs,
        audioEnabled: !tCardIsMuted
      )
      await tCardPlaybackController.setPlaybackRate(tCardSpeed.rawValue)
      tCardFreezeTimelineUiByGesture = false
      if tCardLastTimelineSecondMs < 0 {
        tCardLastTimelineSecondMs = (tCardSelectedTimeMs / 1000) * 1000
      }
      TCardReplayLog.info("play ok rate=\(tCardSpeed.rawValue)")
    } catch {
      tCardIsPlaying = false
      tCardFreezeTimelineUiByGesture = false
      tCardErrorMessage = error.localizedDescription
      TCardReplayLog.error("play error: \(error.localizedDescription)")
    }
  }

  /// 稳态重播：先停后播，避免历史流在同一会话上重复拉起导致播放状态错乱。
  private func restartPlaybackAtSelectedTime() async {
    // 拖拽后切流仅做“后台快速 pause->play”，不额外等待，避免体感停顿。
    tCardIsRecording = false
    await tCardPlaybackController.pauseHistory()
    await playTCardAtSelectedTime()
  }

  /// 截图并保存到本地相册。
  func captureTCardScreenshot() async -> Bool {
    guard let image = tCardPlaybackController.screenshot() else { return false }
    guard let data = image.jpegData(compressionQuality: 0.95) else { return false }
    let ok = await LocalAlbumStore.shared.saveImageData(data)
    if ok {
      notifyAlbumSaved(kind: "snapshot")
    }
    return ok
  }

  /// 录像开关：开始录制或停止并保存。
  func toggleTCardRecording() async -> Bool {
    if tCardIsRecording {
      let ok = await tCardPlaybackController.stopRecording()
      tCardIsRecording = false
      if ok {
        notifyAlbumSaved(kind: "record")
      }
      return ok
    }

    do {
      try tCardPlaybackController.startRecording()
      tCardIsRecording = true
      return true
    } catch {
      tCardErrorMessage = error.localizedDescription
      tCardIsRecording = false
      return false
    }
  }

  /// 下载当前时间点对应的视频文件并保存到本地相册。
  func downloadCurrentTCardVideo() async -> TCardDownloadResult {
    guard tCardCanDownloadInCurrentMode else {
      return .failed("仅 Wi-Fi 模式支持下载")
    }
    if tCardIsDownloading {
      return .failed("下载任务进行中")
    }
    guard tCardIsLoading == false else {
      return .failed("正在加载回放，请稍后")
    }
    guard let segment = resolveSegment(for: tCardSelectedTimeMs) else {
      return .failed("当前时间点无可下载视频")
    }
    let did = currTCardDid
    guard did.isEmpty == false else {
      return .failed("设备信息缺失")
    }

    tCardIsDownloading = true
    tCardDownloadProgress = 0
    defer {
      tCardIsDownloading = false
      tCardDownloadProgress = 0
    }

    do {
      let connect = try await tCardPlaybackController.ensureConnected(deviceId: did)
      let candidateURLs = try await replayDownloadService.fetchTimelineDownloadVideoURLs(
        connect: connect,
        did: did,
        channel: segment.channel,
        timeMs: tCardSelectedTimeMs
      )
      TCardReplayLog.info("download candidates count=\(candidateURLs.count) did=\(did) channel=\(segment.channel) timeMs=\(tCardSelectedTimeMs)")
      var lastError: Error?
      for (index, candidate) in candidateURLs.enumerated() {
        do {
          TCardReplayLog.info("download candidate[\(index + 1)/\(candidateURLs.count)] url=\(candidate)")
          let localURL = try await replayDownloadService.downloadVideo(from: candidate) { [weak self] progress in
            Task { @MainActor in
              self?.tCardDownloadProgress = progress
            }
          }
          let fileSize = (try? localURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
          TCardReplayLog.info("download success tempFile=\(localURL.lastPathComponent) ext=\(localURL.pathExtension) size=\(fileSize)")
          let saveResult = await LocalAlbumStore.shared.saveVideoFileDetailed(localURL)
          try? FileManager.default.removeItem(at: localURL)
          if case .success = saveResult {
            TCardReplayLog.info("save album success file=\(localURL.lastPathComponent)")
            notifyAlbumSaved(kind: "download")
            return .success
          }
          if case let .failed(message) = saveResult {
            TCardReplayLog.error("save album failed msg=\(message) sourceURL=\(candidate)")
            return .failed(message.isEmpty ? "保存失败" : message)
          }
          return .failed("保存失败")
        } catch is CancellationError {
          return .cancelled
        } catch {
          lastError = error
          TCardReplayLog.error("download candidate failed url=\(candidate) err=\(error.localizedDescription)")
          continue
        }
      }
      if let lastError {
        return .failed(lastError.localizedDescription)
      }
      return .failed("下载失败，请稍后重试")
    } catch is CancellationError {
      return .cancelled
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  func cancelTCardDownload() {
    replayDownloadService.cancelCurrentDownload()
  }

  /// 当前片段播放结束后的续播策略：有下一段则跳转，否则暂停。
  private func handleTCardPlaybackEnded() async {
    guard tCardIsPlaying else { return }
    guard let next = nextSegmentStart(after: tCardSelectedTimeMs) else {
      await pauseTCardPlayback()
      return
    }
    tCardSelectedTimeMs = next
    await playTCardAtSelectedTime()
  }

  /// 查找某个时间点之后的下一段起点。
  private func nextSegmentStart(after timeMs: Int64) -> Int64? {
    let threshold = timeMs + 1000
    return tCardSegments
      .sorted(by: { $0.startTimeMs < $1.startTimeMs })
      .first(where: { $0.startTimeMs > threshold })?
      .startTimeMs
  }

  /// 从历史范围数据中提取“有回放数据的日期”列表。
  private func buildTCardAvailableDates(from ranges: [TCardReplayRange]) -> [Date] {
    var dateSet: Set<Date> = []
    for item in ranges {
      let day = Date(timeIntervalSince1970: Double(item.startTimeMs) / 1000).startOfDay
      dateSet.insert(day)
    }
    return Array(dateSet).sorted(by: { $0 > $1 }).prefix(10).map { $0 }
  }

  /// 根据选中日期生成时间轴片段（含空白补齐）并更新默认选中时间。
  private func buildTCardSegmentsForSelectedDate() {
    let day = tCardSelectedDate.startOfDay
    let dayStartMs = Int64(day.timeIntervalSince1970 * 1000)
    let dayEndMs = dayStartMs + 86_400_000
    let selectedCameraChannel = normalizedCameraChannel(tCardChannel)

    let raw = tCardAllRanges
      .compactMap { r -> TCardReplayRange? in
        if let channel = r.channel, normalizedCameraChannel(channel) != selectedCameraChannel {
          return nil
        }
        let start = max(dayStartMs, r.startTimeMs)
        let end = min(dayEndMs, r.endTimeMs)
        if end <= start { return nil }
        return TCardReplayRange(
          id: r.id,
          startTimeMs: start,
          endTimeMs: end,
          kind: r.kind,
          fileId: r.fileId,
          historyType: r.historyType,
          channel: r.channel
        )
      }
      .sorted(by: { $0.startTimeMs < $1.startTimeMs })

    var filled: [TCardReplayRange] = []
    var cursor = dayStartMs
    for r in raw {
      let start = max(cursor, r.startTimeMs)
      if start > cursor {
        filled.append(TCardReplayRange(id: "empty|\(cursor)|\(start)", startTimeMs: cursor, endTimeMs: start, kind: .empty, fileId: nil, historyType: nil, channel: nil))
      }
      if r.endTimeMs > start {
        filled.append(TCardReplayRange(id: r.id, startTimeMs: start, endTimeMs: r.endTimeMs, kind: r.kind, fileId: r.fileId, historyType: r.historyType, channel: r.channel))
        cursor = max(cursor, r.endTimeMs)
      }
      if cursor >= dayEndMs { break }
    }
    if cursor < dayEndMs {
      filled.append(TCardReplayRange(id: "empty|\(cursor)|\(dayEndMs)", startTimeMs: cursor, endTimeMs: dayEndMs, kind: .empty, fileId: nil, historyType: nil, channel: nil))
    }
    if filled.isEmpty {
      filled = [TCardReplayRange(id: "empty|\(dayStartMs)|\(dayEndMs)", startTimeMs: dayStartMs, endTimeMs: dayEndMs, kind: .empty, fileId: nil, historyType: nil, channel: nil)]
    }

    tCardRanges = filled

    let segments: [TCardReplaySegment] = filled.compactMap { r in
      guard r.kind != .empty else { return nil }
      guard let fileId = r.fileId, let historyType = r.historyType else { return nil }
      let channel = r.channel ?? tCardChannel
      return TCardReplaySegment(
        id: "\(fileId)|\(r.startTimeMs)|\(r.endTimeMs)",
        fileId: fileId,
        startTimeMs: r.startTimeMs,
        endTimeMs: r.endTimeMs,
        historyType: historyType,
        channel: channel
      )
    }
    tCardSegments = segments

    if let stored = tCardSelectedTimeByDay[dayStartMs] {
      tCardSelectedTimeMs = clampTime(stored, dayStartMs: dayStartMs)
      tCardSelectedTimeByDay[dayStartMs] = tCardSelectedTimeMs
      syncReplayMapPoint(for: tCardSelectedTimeMs)
      return
    }
    if let last = segments.last {
      let defaultTime = last.startTimeMs
      tCardSelectedTimeMs = clampTime(defaultTime, dayStartMs: dayStartMs)
    } else {
      tCardSelectedTimeMs = dayStartMs + 12 * 3_600_000
    }
    tCardSelectedTimeByDay[dayStartMs] = tCardSelectedTimeMs
    syncReplayMapPoint(for: tCardSelectedTimeMs)
  }

  /// 通过 SDK 拉取设备历史范围并转换成回放区间模型。
  private func fetchTCardAllRanges(connect: XCSDKConnect) async throws -> [TCardReplayRange] {
    let historyTypes: [NSNumber] = [255, 121, 122, 123]
    let model = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HistoryDayListModel, Error>) in
      connect.historyDayListAsync(
        withChannel: 0,
        day: 0,
        order: 1,
        page: 1,
        pageSize: 50,
        startTime: Int(Date().timeIntervalSince1970) * 1000,
        historyTypeArr: historyTypes,
        rType: 2
      ) { resp, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: resp)
      }
    }
    let ranges = model.historyRange
    TCardReplayLog.info("historyDayList(all) ch=0 rangeCount=\(ranges.count) fileCount=\(model.historys.count)")
    let dayStartMs: Int64 = 0
    return ranges.compactMap { item in
      let startMs = normalizeTimestampMs(Int64(item.startTime), dayStartMs: dayStartMs)
      let lengthMs = normalizeLengthMs(Int64(item.length))
      let endMs = startMs + lengthMs
      if endMs <= startMs { return nil }
      let historyType = Int(item.historyType)
      let kind: TCardReplayRangeKind = (historyType == 121 || historyType == 122 || historyType == 123) ? .event : .normal
      let fileId = Int(item.fileId)
      let channel = Int(item.channel)
      let id = "\(fileId)|\(startMs)|\(endMs)|\(historyType)"
      return TCardReplayRange(
        id: id,
        startTimeMs: startMs,
        endTimeMs: endMs,
        kind: kind,
        fileId: fileId,
        historyType: historyType,
        channel: channel
      )
    }
  }

  /// 根据时间戳查找对应的可播放片段。
  private func resolveSegment(for timeMs: Int64) -> TCardReplaySegment? {
    tCardSegments.first(where: { timeMs >= $0.startTimeMs && timeMs < $0.endTimeMs })
  }

  /// 计算当前时间点所在区间的索引（不在任何区间时返回 nil）。
  private func currentSegmentIndex() -> Int? {
    tCardSegments.firstIndex(where: { tCardSelectedTimeMs >= $0.startTimeMs && tCardSelectedTimeMs < $0.endTimeMs })
  }

  /// 计算“上一个区间”索引（支持当前时间不在区间内时回退到最近区间）。
  private func previousSegmentIndex() -> Int? {
    if let current = currentSegmentIndex() {
      let previous = current - 1
      return previous >= 0 ? previous : nil
    }
    return tCardSegments.lastIndex(where: { $0.endTimeMs <= tCardSelectedTimeMs })
  }

  /// 计算“下一个区间”索引（支持当前时间不在区间内时前进到最近区间）。
  private func nextSegmentIndex() -> Int? {
    if let current = currentSegmentIndex() {
      let next = current + 1
      return next < tCardSegments.count ? next : nil
    }
    return tCardSegments.firstIndex(where: { $0.startTimeMs > tCardSelectedTimeMs })
  }

  /// 订阅全局车辆数据变化，保持当前页面数据同步。
  private func bindStore() {
    vehiclesStore.$vehicles
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.syncFromStore()
      }
      .store(in: &cancellables)

    wifiStore.$currentSSID
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        guard let self else { return }
        let isWifiConnected = self.wifiStore.isTargetWifiConnected
        self.tCardIsWifiConnected = isWifiConnected
        self.tCardPlaybackController.setPreferLocalWifiPlayback(isWifiConnected)
        self.syncBridgeConnectionState()
      }
      .store(in: &cancellables)

    XCBridge4Network.shared.isConnectedPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.syncBridgeConnectionState()
      }
      .store(in: &cancellables)

    XCBridge4Wifi.shared.isConnectedPublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.syncBridgeConnectionState()
      }
      .store(in: &cancellables)
  }

  private func syncBridgeConnectionState() {
    tCardIsBridgeConnected = tCardIsWifiConnected ? XCBridge4Wifi.shared.isConnected : XCBridge4Network.shared.isConnected
  }

  /// 按 imei 从全局 store 同步当前车辆对象。
  private func syncFromStore() {
    guard let imei = tCardImei, imei.isEmpty == false else {
      currTCardVehicle = nil
      return
    }
    currTCardVehicle = vehiclesStore.hashVehicles[imei] ?? vehiclesStore.vehicles.first(where: { $0.imei == imei })
  }

  /// 统一设备返回的时间戳单位（秒/毫秒/日内偏移）到毫秒时间戳。
  private func normalizeTimestampMs(_ value: Int64, dayStartMs: Int64) -> Int64 {
    if value <= 0 { return dayStartMs }
    if value > 1_500_000_000_000 { return value }
    if value > 1_500_000_000 { return value * 1000 }
    if value > 86_400_000 { return dayStartMs + value }
    return dayStartMs + value * 1000
  }

  /// 统一设备返回的时长单位到毫秒。
  private func normalizeLengthMs(_ value: Int64) -> Int64 {
    if value <= 0 { return 0 }
    if value > 86_400_000 { return value }
    return value * 1000
  }

  /// 打开页面时重置回放 UI/数据状态。
  private func resetOpenState() {
    tCardSelectedDate = Date()
    tCardChannel = 1
    tCardIsMuted = true
    tCardSpeed = .x1
    tCardSelectedTimeMs = Int64(Date().timeIntervalSince1970 * 1000)
    tCardRanges = []
    tCardSegments = []
    tCardAllRanges = []
    tCardReplayGpsPointsByDay = [:]
    tCardReplayMapPoint = nil
    tCardReplayGpsLoadTask?.cancel()
    tCardReplayGpsLoadTask = nil
    tCardSelectedTimeByDay = [:]
    tCardAvailableDates = []
    tCardIsPlaying = false
    tCardIsFullscreen = false
    tCardIsLoading = false
    tCardIsDownloading = false
    tCardDownloadProgress = 0
    tCardErrorMessage = nil
    tCardFreezeTimelineUiByGesture = false
    tCardIgnorePlaybackUntilUptimeMs = 0
    tCardLastTimelineSecondMs = -1
  }

  /// 更新当前选中时间，并记住该日期下的最后一次选中点。
  private func updateSelectedTime(_ timeMs: Int64) {
    tCardSelectedTimeMs = timeMs
    let dayStartMs = dayStartMs(for: tCardSelectedDate)
    tCardSelectedTimeByDay[dayStartMs] = timeMs
    syncReplayMapPoint(for: timeMs)
  }

  /// 计算某天 00:00:00 的毫秒时间戳。
  private func dayStartMs(for date: Date) -> Int64 {
    Int64(date.startOfDay.timeIntervalSince1970 * 1000)
  }

  private func currentUptimeMs() -> Int64 {
    Int64(DispatchTime.now().uptimeNanoseconds / 1_000_000)
  }

  private func lockPlaybackCallbackForOneSecond() {
    tCardIgnorePlaybackUntilUptimeMs = currentUptimeMs() + 1_000
    tCardLastTimelineSecondMs = (tCardSelectedTimeMs / 1000) * 1000
  }

  /// 把时间钳制到当天范围内，避免越界。
  private func clampTime(_ timeMs: Int64, dayStartMs: Int64) -> Int64 {
    min(max(dayStartMs, timeMs), dayStartMs + 86_399_000)
  }

  /// 构建可选摄像头列表（前摄=1，后摄=2），用于 Header 菜单。
  private func buildAvailableCameraChannels(from ranges: [TCardReplayRange]) -> [Int] {
    var channels = Set(ranges.compactMap { range -> Int? in
      guard let channel = range.channel else { return nil }
      return normalizedCameraChannel(channel)
    })
    if (currTCardVehicle?.ability?.rear ?? 0) > 0 {
      channels.insert(2)
    }
    if channels.isEmpty {
      channels.insert(1)
    }
    return Array(channels).sorted()
  }

  /// 归一化摄像头通道：把 0/1 统一看作前摄，2 看作后摄。
  private func normalizedCameraChannel(_ channel: Int) -> Int {
    channel == 2 ? 2 : 1
  }

  /// 摄像头通道展示文案。
  private func cameraTitle(for channel: Int) -> String {
    normalizedCameraChannel(channel) == 2 ? "后摄" : "前摄"
  }

  /// 根据当前选中日期拉取轨迹点（命中缓存时直接复用）。
  private func loadReplayGpsForSelectedDate() {
    let dayKey = dayStartMs(for: tCardSelectedDate)
    if tCardReplayGpsPointsByDay[dayKey] != nil {
      syncReplayMapPoint(for: tCardSelectedTimeMs)
      return
    }

    let did = currTCardDid
    guard did.isEmpty == false else {
      tCardReplayMapPoint = nil
      return
    }

    tCardReplayGpsLoadTask?.cancel()
    tCardReplayGpsLoadTask = Task { [weak self] in
      guard let self else { return }
      do {
        let points = try await replayGpsService.fetchHistoryPoints(did: did, dayStartMs: dayKey)
        guard Task.isCancelled == false else { return }
        tCardReplayGpsPointsByDay[dayKey] = points
        TCardReplayLog.info("loadReplayGps done dayStartMs=\(dayKey) points=\(points.count)")
      } catch {
        guard Task.isCancelled == false else { return }
        tCardReplayGpsPointsByDay[dayKey] = []
        TCardReplayLog.error("loadReplayGps failed dayStartMs=\(dayKey) msg=\(error.localizedDescription)")
      }

      guard dayKey == dayStartMs(for: tCardSelectedDate) else { return }
      syncReplayMapPoint(for: tCardSelectedTimeMs)
    }
  }

  private func notifyAlbumSaved(kind: String) {
    tCardAlbumSaveSignal &+= 1
    TCardReplayLog.info("album save signal kind=\(kind) signal=\(tCardAlbumSaveSignal)")
  }

  /// 用当前播放时间匹配最近轨迹点，驱动地图车辆位置。
  private func syncReplayMapPoint(for timeMs: Int64) {
    let dayStartMs = dayStartMs(for: tCardSelectedDate)
    guard let points = tCardReplayGpsPointsByDay[dayStartMs], points.isEmpty == false else {
      tCardReplayMapPoint = nil
      return
    }
    tCardReplayMapPoint = nearestReplayGpsPoint(in: points, around: timeMs)
  }

  /// 二分查找“最接近当前时间”的轨迹点，保证地图跟随平滑。
  private func nearestReplayGpsPoint(in points: [TCardReplayGpsPoint], around targetMs: Int64) -> TCardReplayGpsPoint {
    var low = 0
    var high = points.count
    while low < high {
      let mid = (low + high) / 2
      if points[mid].timeMs < targetMs {
        low = mid + 1
      } else {
        high = mid
      }
    }

    if low <= 0 { return points[0] }
    if low >= points.count { return points[points.count - 1] }

    let left = points[low - 1]
    let right = points[low]
    let leftDistance = abs(targetMs - left.timeMs)
    let rightDistance = abs(right.timeMs - targetMs)
    return leftDistance <= rightDistance ? left : right
  }
}

final class TCardReplayDownloadService: NSObject {
  private enum DownloadError: LocalizedError {
    case invalidRequest
    case emptyURL
    case invalidURL
    case emptyResponse
    case noDownloadCandidate

    var errorDescription: String? {
      switch self {
      case .invalidRequest:
        return "下载请求构建失败"
      case .emptyURL:
        return "下载链接为空"
      case .invalidURL:
        return "下载链接无效"
      case .emptyResponse:
        return "未获取到下载信息"
      case .noDownloadCandidate:
        return "当前时间点无可下载视频"
      }
    }
  }

  private enum Const {
    static let historyDownloadVideoCid = 579
    static let fallbackHost = "http://192.168.42.129"
  }

  private var session: URLSession?
  private var activeTask: URLSessionDownloadTask?
  private var pendingContinuation: CheckedContinuation<URL, Error>?
  private var progressHandler: ((Int) -> Void)?
  private var hasResumed: Bool = false

  func cancelCurrentDownload() {
    activeTask?.cancel()
  }

  /// 请求设备生成“当前时间点对应视频”的下载链接候选列表。
  func fetchTimelineDownloadVideoURLs(
    connect: XCSDKConnect,
    did: String,
    channel: Int,
    timeMs: Int64
  ) async throws -> [String] {
    TCardReplayLog.info("fetchDownloadURLs start did=\(did) channel=\(channel) timeMs=\(timeMs)")
    let requestJson = XCAVSDKCommon.cmdString(
      withCid: Const.historyDownloadVideoCid,
      did: did,
      pint: [NSNumber(value: channel), NSNumber(value: 0), NSNumber(value: timeMs)],
      pstr: [],
      pbs: "",
      answer: true
    )
    guard requestJson.isEmpty == false else {
      throw DownloadError.invalidRequest
    }
    TCardReplayLog.info("fetchDownloadURLs request cid=\(Const.historyDownloadVideoCid) bodyLen=\(requestJson.count)")

    let response = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
      connect.execIOTCMDAsync(withReqJson: requestJson) { respJson, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: respJson)
      }
    }

    guard response.isEmpty == false else { throw DownloadError.emptyResponse }
    TCardReplayLog.info("fetchDownloadURLs responseLen=\(response.count)")
    let candidates = parseVideoCandidates(from: response)
    guard candidates.isEmpty == false else { throw DownloadError.noDownloadCandidate }
    TCardReplayLog.info("fetchDownloadURLs parsed candidates=\(candidates)")
    return candidates
  }

  /// 下载视频到临时目录，并实时回传百分比进度。
  func downloadVideo(
    from rawURL: String,
    onProgress: @escaping (Int) -> Void
  ) async throws -> URL {
    guard rawURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      throw DownloadError.emptyURL
    }
    let normalized = normalizeDownloadURL(rawURL)
    guard let url = URL(string: normalized) else {
      throw DownloadError.invalidURL
    }
    TCardReplayLog.info("downloadVideo start raw=\(rawURL) normalized=\(normalized)")

    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
      cleanupDownloadState()
      progressHandler = onProgress
      pendingContinuation = continuation
      hasResumed = false

      let config = URLSessionConfiguration.default
      session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
      let task = session?.downloadTask(with: url)
      activeTask = task
      let expectedName = url.lastPathComponent.isEmpty ? "unknown" : url.lastPathComponent
      TCardReplayLog.info("download task resume expectedName=\(expectedName) url=\(url.absoluteString)")
      task?.resume()
    }
  }

  private func parseVideoCandidates(from responseJson: String) -> [String] {
    guard
      let data = responseJson.data(using: .utf8),
      let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    else {
      return []
    }

    var videoCandidates = Set<String>()

    func addCandidate(_ raw: String?) {
      let trimmed = (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard trimmed.isEmpty == false else { return }
      let normalized = normalizeDownloadURL(trimmed)
      guard looksLikeImageURL(normalized) == false else { return }
      videoCandidates.insert(normalized)
    }

    if
      let iotCmds = root["iot_cmds"] as? [String: Any],
      let cmds = iotCmds["cmds"] as? [[String: Any]],
      let cmd0 = cmds.first
    {
      if let pstr = cmd0["pstr"] as? [String] {
        pstr.forEach { addCandidate($0) }
      }
      addCandidate(cmd0["url"] as? String)
    }

    addCandidate(root["url"] as? String)
    return Array(videoCandidates)
  }

  private func looksLikeImageURL(_ url: String) -> Bool {
    let lower = url.lowercased()
    return lower.contains(".jpg")
      || lower.contains(".jpeg")
      || lower.contains(".png")
      || lower.contains(".webp")
      || lower.contains(".bmp")
  }

  private func normalizeDownloadURL(_ rawURL: String) -> String {
    let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else { return "" }
    if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
      return trimmed
    }
    if trimmed.hasPrefix("/") {
      return "\(Const.fallbackHost)\(trimmed)"
    }
    return "\(Const.fallbackHost)/\(trimmed)"
  }

  private func cleanupDownloadState() {
    activeTask = nil
    progressHandler = nil
    pendingContinuation = nil
    hasResumed = false
    session?.invalidateAndCancel()
    session = nil
  }

  private func resolveSuccess(location: URL) {
    guard hasResumed == false, let continuation = pendingContinuation else { return }
    hasResumed = true
    pendingContinuation = nil

    continuation.resume(returning: location)
    cleanupDownloadState()
  }

  private func resolveFailure(_ error: Error) {
    guard hasResumed == false, let continuation = pendingContinuation else { return }
    hasResumed = true
    pendingContinuation = nil

    if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
      continuation.resume(throwing: CancellationError())
    } else {
      continuation.resume(throwing: error)
    }
    cleanupDownloadState()
  }

  private func resolvePreferredExtension(downloadTask: URLSessionDownloadTask) -> String {
    if let ext = downloadTask.originalRequest?.url?.pathExtension, ext.isEmpty == false {
      return ext.lowercased()
    }
    if let ext = downloadTask.currentRequest?.url?.pathExtension, ext.isEmpty == false {
      return ext.lowercased()
    }
    if let suggested = downloadTask.response?.suggestedFilename {
      let ext = (suggested as NSString).pathExtension.lowercased()
      if ext.isEmpty == false {
        return ext
      }
    }
    return "mp4"
  }

  private func moveToStableTemporaryFile(location: URL, preferredExtension: String) throws -> URL {
    let ext = preferredExtension.isEmpty ? "mp4" : preferredExtension
    let filename = "tcard_download_\(Int(Date().timeIntervalSince1970 * 1000)).\(ext)"
    let target = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

    if FileManager.default.fileExists(atPath: target.path) {
      try FileManager.default.removeItem(at: target)
    }
    try FileManager.default.moveItem(at: location, to: target)
    let size = (try? target.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
    TCardReplayLog.info("download file moved src=\(location.lastPathComponent) dst=\(target.lastPathComponent) ext=\(ext) size=\(size)")
    return target
  }
}

extension TCardReplayDownloadService: URLSessionDownloadDelegate, URLSessionTaskDelegate {
  nonisolated func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    if let http = response as? HTTPURLResponse {
      let suggested = response.suggestedFilename ?? "nil"
      let mime = response.mimeType ?? "nil"
      let contentLength = http.value(forHTTPHeaderField: "Content-Length") ?? "unknown"
      TCardReplayLog.info("download response status=\(http.statusCode) mime=\(mime) suggested=\(suggested) contentLength=\(contentLength) url=\(response.url?.absoluteString ?? "nil")")
    } else {
      TCardReplayLog.info("download response mime=\(response.mimeType ?? "nil") suggested=\(response.suggestedFilename ?? "nil") url=\(response.url?.absoluteString ?? "nil")")
    }
    completionHandler(.allow)
  }

  nonisolated func urlSession(
    _: URLSession,
    downloadTask _: URLSessionDownloadTask,
    didWriteData _: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64
  ) {
    guard totalBytesExpectedToWrite > 0 else { return }
    let ratio = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
    let progress = max(0, min(100, Int(ratio * 100)))
    Task { @MainActor in
      self.progressHandler?(progress)
    }
  }

  nonisolated func urlSession(
    _: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    let tempSize = (try? location.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
    TCardReplayLog.info("download finished tempName=\(location.lastPathComponent) tempSize=\(tempSize) tmpPath=\(location.path)")
    let preferredExt = resolvePreferredExtension(downloadTask: downloadTask)
    TCardReplayLog.info("download preferredExt=\(preferredExt) suggested=\(downloadTask.response?.suggestedFilename ?? "nil") originalURL=\(downloadTask.originalRequest?.url?.absoluteString ?? "nil")")
    let stableURL: URL
    do {
      stableURL = try moveToStableTemporaryFile(location: location, preferredExtension: preferredExt)
    } catch {
      Task { @MainActor in
        self.resolveFailure(error)
      }
      return
    }

    Task { @MainActor in
      self.resolveSuccess(location: stableURL)
    }
  }

  nonisolated func urlSession(
    _: URLSession,
    task _: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    guard let error else { return }
    TCardReplayLog.error("download complete with error code=\((error as NSError).code) msg=\(error.localizedDescription)")
    Task { @MainActor in
      self.resolveFailure(error)
    }
  }
}
