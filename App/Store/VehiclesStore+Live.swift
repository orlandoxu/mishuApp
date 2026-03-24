import AVFoundation
import Foundation

extension VehiclesStore {
  var currLiveVehicle: VehicleModel? {
    guard let imei = liveImei, imei.isEmpty == false else { return nil }
    return hashVehicles[imei] ?? vehicles.first(where: { $0.imei == imei })
  }

  var currLiveDid: String {
    currLiveVehicle?.did ?? ""
  }

  func setLiveImei(_ imei: String?) {
    liveImei = imei
  }
}

final class LiveTalkbackController: NSObject {
  enum TalkbackError: LocalizedError {
    case busy
    case connectFailed
    case talkbackStartFailed(code: Int)

    var errorDescription: String? {
      switch self {
      case .busy:
        return "对讲正在切换中，请稍后再试"
      case .connectFailed:
        return "连接设备失败"
      case let .talkbackStartFailed(code):
        if code == 1 { return "设备处于私密模式，无法对讲" }
        if code == 2 { return "设备连接数过多，无法对讲" }
        return "开启对讲失败"
      }
    }
  }

  private let writeQueue = DispatchQueue(label: "tuyun.live.talkback.write")
  private var connect: XCSDKConnect?
  private var audioCapture: XCAudioCapture?
  private var audioTranscodeTool: XCAudioTranscodeTool?
  private var talkCodecRawValue: Int = 0
  private var talkChannel: Int = 0
  private var isRunning = false

  private var previousAudioCategory: AVAudioSession.Category?
  private var previousAudioMode: AVAudioSession.Mode?
  private var previousAudioOptions: AVAudioSession.CategoryOptions?

  func start(did: String, channel: Int) async throws {
    // Step 1. 防重复启动/并发启动
    if isRunning { return }
    if connect != nil { throw TalkbackError.busy }

    // Step 2. 复用直播全局连接，避免连接数过多
    let connect = try await XCBridge4Network.shared.ensureConnectedForExternal(did: did)
    self.connect = connect
    talkChannel = channel

    // Step 3. 开启设备端对讲能力并获取设备要求的音频参数
    let model = try await talkbackPlay(connect, channel: channel)
    guard model.code == 0 else {
      stop()
      throw TalkbackError.talkbackStartFailed(code: Int(model.code))
    }

    talkCodecRawValue = Int(model.codec)

    // Step 4. 配置音频会话，并按设备参数启动麦克风采集/编码链路
    try configureAudioSessionForTalk()
    setupAudioPipeline(codec: Int(model.codec), rate: Int(model.rate), bit: Int(model.bit), track: Int(model.track))

    // Step 5. 启动采集（后续在 delegate 回调里持续写入 talkback 数据）
    isRunning = true
    audioCapture?.start()
  }

  func stop() {
    // Step 1. 先停采集与编码链路，避免继续写入
    guard let connect else {
      isRunning = false
      releaseAudioPipeline()
      restoreAudioSessionAfterTalk()
      return
    }

    isRunning = false
    audioCapture?.stop()
    releaseAudioPipeline()

    // Step 2. 通知设备停止对讲（不释放直播连接）
    connect.talkbackPauseAsync(withChannel: talkChannel) { _, _ in }
    self.connect = nil

    // Step 3. 恢复音频会话配置
    restoreAudioSessionAfterTalk()
  }

  private func setupAudioPipeline(codec: Int, rate: Int, bit: Int, track: Int) {
    let format = XCAVFormat(rawValue: codec) ?? XCAVFormat(rawValue: 121)!

    audioTranscodeTool = XCAudioTranscodeTool(rate: rate, channel: track)
    let capture = XCAudioCapture(audioCaptureWithRate: rate, bit: bit, channel: track, audioType: format)
    capture.delegate = self
    audioCapture = capture
  }

  private func releaseAudioPipeline() {
    audioCapture = nil
    audioTranscodeTool?.free()
    audioTranscodeTool = nil
    talkCodecRawValue = 0
    talkChannel = 0
  }

  private func configureAudioSessionForTalk() throws {
    let session = AVAudioSession.sharedInstance()
    previousAudioCategory = session.category
    previousAudioMode = session.mode
    previousAudioOptions = session.categoryOptions

    try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
    try session.setActive(true, options: [])
  }

  private func restoreAudioSessionAfterTalk() {
    guard let previousAudioCategory, let previousAudioMode, let previousAudioOptions else { return }
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(previousAudioCategory, mode: previousAudioMode, options: previousAudioOptions)
    try? session.setActive(true, options: [])
    self.previousAudioCategory = nil
    self.previousAudioMode = nil
    self.previousAudioOptions = nil
  }

  private func talkbackPlay(_ connect: XCSDKConnect, channel: Int) async throws -> TalkbackPlayModel {
    try await withCheckedThrowingContinuation { continuation in
      connect.talkbackPlayAsync(withChannel: channel) { model, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: model)
      }
    }
  }
}

extension LiveTalkbackController: XCAudioCaptureDelegate {
  func audioCaptureReturnPCMData(_ data: Data) {
    writeQueue.async { [weak self] in
      guard let self else { return }
      guard self.isRunning, let connect = self.connect else { return }

      let codec = self.talkCodecRawValue
      let talkData: Data?

      // Step 1. 按设备要求编码（设备返回 codec=PCM/G711/AAC 等）
      if codec == 21 || codec == 41 || codec == 101 {
        if let tool = self.audioTranscodeTool {
          let format = XCAVFormat(rawValue: codec) ?? XCAVFormat(rawValue: 121)!
          talkData = tool.audioEncode(with: format, withPCMData: data)
        } else {
          talkData = nil
        }
      } else if codec == 121 {
        talkData = data
      } else {
        talkData = nil
      }

      guard let talkData else { return }
      let mediaType = XCAVSDKMediaType(rawValue: UInt(codec)) ?? XCAVSDKMediaType(rawValue: 121)!
      // Step 2. 将编码后的音频包写入 SDK（内部负责发送到设备）
      connect.talkbackWriteDataSync(with: mediaType, channel: self.talkChannel, data: talkData) { _, _ in }
    }
  }
}
