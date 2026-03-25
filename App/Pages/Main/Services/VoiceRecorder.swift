import AVFoundation
import Foundation

@MainActor
final class HomeVoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
  @Published private(set) var isRecording: Bool = false
  @Published private(set) var normalizedPower: CGFloat = 0
  @Published private(set) var permissionDenied: Bool = false
  @Published private(set) var lastErrorMessage: String?
  @Published private(set) var latestRecordingURL: URL?

  private var recorder: AVAudioRecorder?
  private var meterTimer: Timer?

  deinit {
    meterTimer?.invalidate()
  }

  // Step 1. 统一对外入口：申请权限并启动录音
  // Step 2. 启动成功后通过回调通知页面更新状态
  func startRecording(completion: @escaping (Bool) -> Void) {
    permissionDenied = false
    lastErrorMessage = nil

    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      startRecorderInternal(completion: completion)
    case .denied:
      permissionDenied = true
      completion(false)
    case .undetermined:
      session.requestRecordPermission { [weak self] granted in
        DispatchQueue.main.async {
          guard let self else { return }
          if granted {
            self.startRecorderInternal(completion: completion)
          } else {
            self.permissionDenied = true
            completion(false)
          }
        }
      }
    @unknown default:
      lastErrorMessage = "麦克风权限状态异常"
      completion(false)
    }
  }

  // Step 1. 停止录音并返回录音文件地址
  // Step 2. 同时关闭电平采样定时器
  func stopRecording() -> URL? {
    meterTimer?.invalidate()
    meterTimer = nil

    recorder?.stop()
    let outputURL = recorder?.url

    recorder = nil
    isRecording = false
    normalizedPower = 0

    latestRecordingURL = outputURL
    return outputURL
  }

  private func startRecorderInternal(completion: @escaping (Bool) -> Void) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true, options: .notifyOthersOnDeactivation)

      let outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("home-voice-\(UUID().uuidString).m4a")

      let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ]

      let recorder = try AVAudioRecorder(url: outputURL, settings: settings)
      recorder.delegate = self
      recorder.isMeteringEnabled = true

      guard recorder.prepareToRecord(), recorder.record() else {
        lastErrorMessage = "录音启动失败"
        completion(false)
        return
      }

      self.recorder = recorder
      isRecording = true
      latestRecordingURL = nil
      startMetering()
      completion(true)
    } catch {
      lastErrorMessage = "录音初始化失败：\(error.localizedDescription)"
      completion(false)
    }
  }

  private func startMetering() {
    meterTimer?.invalidate()
    meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      guard let self, let recorder = self.recorder else { return }
      recorder.updateMeters()

      let power = recorder.averagePower(forChannel: 0)
      let linear = pow(10, power / 20)
      let boosted = min(max(CGFloat(linear) * 1.6, 0), 1)
      self.normalizedPower = boosted
    }
  }

  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    lastErrorMessage = error?.localizedDescription ?? "录音编码失败"
    _ = stopRecording()
  }
}
