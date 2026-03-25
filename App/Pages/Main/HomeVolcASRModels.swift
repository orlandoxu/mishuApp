import Foundation

struct AsrUtterance: Equatable {
  let text: String
  let definite: Bool
  let startMs: Int?
  let endMs: Int?
}

enum SpeechStopReason {
  case userStopped
  case disconnected
  case completed
}
