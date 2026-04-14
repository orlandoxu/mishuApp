import AVFoundation
import Foundation

@MainActor
final class VoiceRealtimeCtrl: ObservableObject {
  @Published private(set) var isListening: Bool = false
  @Published private(set) var recognizedText: String = ""
  @Published private(set) var lastErrorMessage: String?

  private let captureService = AudioStreamCapture()
  private let speechService: SpeechRecognitionService
  private let memoryPipeline = VoiceMemoryPipeline.shared

  private var transcriptAssembler = VoiceTextAssembler()

  init() {
    speechService = SpeechRecognitionServiceFactory.makeService()
    bindServices()
  }

  // Step 1. 请求麦克风权限并激活音频会话
  // Step 2. 连接火山实时识别，连接成功后再开始推送音频流
  func startListening(completion: @escaping (Bool) -> Void) {
    resetSessionState()

    requestMicAuth { [weak self] granted in
      guard let self else {
        completion(false)
        return
      }

      guard granted else {
        self.failStart("麦克风权限未开启，请到系统设置中允许访问", completion: completion)
        return
      }

      self.speechService.startRecording { [weak self] connected in
        guard let self else {
          completion(false)
          return
        }

        guard connected else {
          self.failStart(self.serviceErrorText, completion: completion)
          return
        }

        self.captureService.startRecording { [weak self] audioStarted in
          guard let self else {
            completion(false)
            return
          }

          guard audioStarted else {
            self.speechService.stopRecording()
            self.failStart("麦克风启动失败", completion: completion)
            return
          }

          self.isListening = true
          completion(true)
        }
      }
    }
  }

  // Step 1. 停止本地采集并通知服务端结束
  // Step 2. 返回最终识别文本给页面渲染
  func stopListening(completion: @escaping (String) -> Void) {
    captureService.stopRecording()
    speechService.stopRecording()

    isListening = false
    let finalText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !finalText.isEmpty else {
      completion(recognizedText)
      return
    }
    Task {
      let reply = await memoryPipeline.processUserInput(finalText)
      await MainActor.run {
        completion(reply)
      }
    }
  }

  func processTextInputForTesting(_ text: String, completion: @escaping (String) -> Void) {
    let finalText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !finalText.isEmpty else {
      completion("请输入测试文本")
      return
    }
    Task {
      let reply = await memoryPipeline.processUserInput(finalText)
      await MainActor.run {
        completion(reply)
      }
    }
  }

  private func bindServices() {
    captureService.onAudioData = { [weak self] data in
      self?.speechService.sendAudio(data)
    }

    captureService.onRecordState = { [weak self] started in
      if !started {
        self?.isListening = false
      }
    }

    speechService.onUtterancesRecognized = { [weak self] utterances in
      self?.consumeUtterances(utterances)
    }

    speechService.onRecordingStopped = { [weak self] _ in
      self?.isListening = false
    }
  }

  private var serviceErrorText: String {
    speechService.connectionError.isEmpty ? "语音识别服务连接失败" : speechService.connectionError
  }

  private func consumeUtterances(_ utterances: [AsrUtterance]) {
    recognizedText = transcriptAssembler.consume(utterances)
  }

  private func resetSessionState() {
    recognizedText = ""
    lastErrorMessage = nil
    transcriptAssembler.reset()
  }

  private func failStart(_ message: String, completion: @escaping (Bool) -> Void) {
    lastErrorMessage = message
    completion(false)
  }

  private func requestMicAuth(completion: @escaping (Bool) -> Void) {
    let session = AVAudioSession.sharedInstance()

    switch session.recordPermission {
    case .granted:
      configureSession(completion: completion)
    case .denied:
      completion(false)
    case .undetermined:
      session.requestRecordPermission { granted in
        DispatchQueue.main.async {
          if granted {
            self.configureSession(completion: completion)
          } else {
            completion(false)
          }
        }
      }
    @unknown default:
      completion(false)
    }
  }

  private func configureSession(completion: @escaping (Bool) -> Void) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      completion(true)
    } catch {
      completion(false)
    }
  }
}
