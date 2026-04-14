import Foundation

enum SpeechRecognitionServiceFactory {
  static func makeService() -> SpeechRecognitionService {
    switch SpeechRecognitionSettings.preferredProvider {
    case .speechAnalyzer:
      if #available(iOS 26.0, *) {
        return FallbackSpeechRecognitionService(
          primary: SpeechAnalyzerService(),
          fallback: VolcSpeechService()
        )
      }
      return VolcSpeechService()
    case .volc:
      return VolcSpeechService()
    }
  }
}

final class FallbackSpeechRecognitionService: SpeechRecognitionService {
  var connectionError: String {
    activeService.connectionError
  }

  var onUtterancesRecognized: (([AsrUtterance]) -> Void)? {
    didSet { bindCallbacks() }
  }

  var onConnState: ((Bool) -> Void)? {
    didSet { bindCallbacks() }
  }

  var onRecordingStarted: (() -> Void)? {
    didSet { bindCallbacks() }
  }

  var onRecordingStopped: ((SpeechStopReason) -> Void)? {
    didSet { bindCallbacks() }
  }

  private let primary: SpeechRecognitionService
  private let fallback: SpeechRecognitionService
  private var activeService: SpeechRecognitionService
  private var didFallback = false

  init(primary: SpeechRecognitionService, fallback: SpeechRecognitionService) {
    self.primary = primary
    self.fallback = fallback
    activeService = primary
    bindCallbacks()
  }

  func startRecording(completion: @escaping (Bool) -> Void) {
    activeService.startRecording { [weak self] success in
      guard let self else {
        completion(success)
        return
      }

      guard !success, !self.didFallback else {
        completion(success)
        return
      }

      self.didFallback = true
      self.activeService = self.fallback
      self.bindCallbacks()
      self.activeService.startRecording(completion: completion)
    }
  }

  func stopRecording() {
    activeService.stopRecording()
  }

  func sendAudio(_ data: Data) {
    activeService.sendAudio(data)
  }

  private func bindCallbacks() {
    activeService.onUtterancesRecognized = onUtterancesRecognized
    activeService.onConnState = onConnState
    activeService.onRecordingStarted = onRecordingStarted
    activeService.onRecordingStopped = onRecordingStopped
  }
}
