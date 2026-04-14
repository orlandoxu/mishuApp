import Foundation

enum SpeechRecognitionProvider {
  case speechAnalyzer
  case volc
}

enum SpeechRecognitionSettings {
  // 当前尚未接入用户设置，先默认优先本地 SpeechAnalyzer。
  static var preferredProvider: SpeechRecognitionProvider {
    .speechAnalyzer
  }
}

protocol SpeechRecognitionService: AnyObject {
  var connectionError: String { get }

  var onUtterancesRecognized: (([AsrUtterance]) -> Void)? { get set }
  var onConnState: ((Bool) -> Void)? { get set }
  var onRecordingStarted: (() -> Void)? { get set }
  var onRecordingStopped: ((SpeechStopReason) -> Void)? { get set }

  func startRecording(completion: @escaping (Bool) -> Void)
  func stopRecording()
  func sendAudio(_ data: Data)
}
