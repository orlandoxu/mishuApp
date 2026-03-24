import AVFoundation
import Combine
import Foundation

@MainActor
final class HomeVoiceRealtimeController: ObservableObject {
  @Published private(set) var isListening: Bool = false
  @Published private(set) var audioLevel: CGFloat = 0
  @Published private(set) var recognizedText: String = ""
  @Published private(set) var lastErrorMessage: String?

  private let captureService = HomeAudioStreamCapture()
  private let speechService = HomeVolcSpeechRecognitionService()

  private var committedFingerprints: Set<String> = []
  private var confirmedText: String = ""
  private var previewText: String = ""
  private var previewFingerprint: String = ""

  init() {
    bindServices()
  }

  // Step 1. 请求麦克风权限并激活音频会话
  // Step 2. 连接火山实时识别，连接成功后再开始推送音频流
  func startListening(completion: @escaping (Bool) -> Void) {
    recognizedText = ""
    lastErrorMessage = nil
    committedFingerprints.removeAll()
    confirmedText = ""
    previewText = ""
    previewFingerprint = ""

    requestMicPermissionAndConfigureSession { [weak self] granted in
      guard let self else {
        completion(false)
        return
      }

      guard granted else {
        self.lastErrorMessage = "麦克风权限未开启，请到系统设置中允许访问"
        completion(false)
        return
      }

      self.speechService.startRecording { [weak self] connected in
        guard let self else {
          completion(false)
          return
        }

        guard connected else {
          self.lastErrorMessage = self.speechService.connectionError.isEmpty
            ? "语音识别服务连接失败"
            : self.speechService.connectionError
          completion(false)
          return
        }

        self.captureService.startRecording { [weak self] audioStarted in
          guard let self else {
            completion(false)
            return
          }

          if audioStarted {
            self.isListening = true
            completion(true)
          } else {
            self.lastErrorMessage = "麦克风启动失败"
            self.speechService.stopRecording()
            completion(false)
          }
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
    completion(recognizedText.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  private func bindServices() {
    captureService.onAudioData = { [weak self] data in
      self?.speechService.sendAudio(data)
    }

    captureService.onRecordingStateChanged = { [weak self] started in
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

    captureService.$audioLevel
      .receive(on: RunLoop.main)
      .sink { [weak self] level in
        self?.audioLevel = level
      }
      .store(in: &cancellables)
  }

  private var cancellables: Set<AnyCancellable> = []

  private func consumeUtterances(_ utterances: [HomeASRUtterance]) {
    var latestPreview: (text: String, utterance: HomeASRUtterance)?

    for utterance in utterances {
      let normalized = utterance.text.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !normalized.isEmpty else { continue }

      if utterance.definite {
        commitDefiniteIfNeeded(normalized, utterance: utterance)
      } else {
        latestPreview = (normalized, utterance)
      }
    }

    if let latestPreview {
      updatePreview(latestPreview.text, utterance: latestPreview.utterance)
    } else {
      clearPreviewIfNeeded()
    }
  }

  private func commitDefiniteIfNeeded(_ text: String, utterance: HomeASRUtterance) {
    let fp = fingerprint(utterance: utterance, text: text)
    guard !committedFingerprints.contains(fp) else { return }

    committedFingerprints.insert(fp)
    confirmedText = mergeByOverlap(base: confirmedText, incoming: text)

    if previewFingerprint == fp || previewText == text {
      previewText = ""
      previewFingerprint = ""
    }

    publishRecognizedText()
  }

  private func updatePreview(_ text: String, utterance: HomeASRUtterance) {
    let fp = fingerprint(utterance: utterance, text: text)
    guard !committedFingerprints.contains(fp) else {
      clearPreviewIfNeeded()
      return
    }

    if fp == previewFingerprint, text == previewText {
      return
    }

    previewFingerprint = fp
    previewText = text
    publishRecognizedText()
  }

  private func fingerprint(utterance: HomeASRUtterance, text: String) -> String {
    let start = utterance.startMs.map(String.init) ?? "na"
    let end = utterance.endMs.map(String.init) ?? "na"
    return "\(start)|\(end)|\(text)"
  }

  private func clearPreviewIfNeeded() {
    guard !previewText.isEmpty || !previewFingerprint.isEmpty else { return }
    previewText = ""
    previewFingerprint = ""
    publishRecognizedText()
  }

  private func publishRecognizedText() {
    recognizedText = (confirmedText + previewText).trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func mergeByOverlap(base: String, incoming: String) -> String {
    guard !incoming.isEmpty else { return base }
    guard !base.isEmpty else { return incoming }

    if base.hasSuffix(incoming) {
      return base
    }

    let maxOverlap = min(base.count, incoming.count)
    if maxOverlap > 0 {
      for overlap in stride(from: maxOverlap, through: 1, by: -1) {
        let baseSuffix = String(base.suffix(overlap))
        let incomingPrefix = String(incoming.prefix(overlap))
        if baseSuffix == incomingPrefix {
          return base + incoming.dropFirst(overlap)
        }
      }
    }

    return base + incoming
  }

  private func requestMicPermissionAndConfigureSession(completion: @escaping (Bool) -> Void) {
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
