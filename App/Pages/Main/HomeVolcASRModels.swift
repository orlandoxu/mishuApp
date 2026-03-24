import Foundation

struct HomeASRUtterance: Equatable {
  let text: String
  let definite: Bool
  let startMs: Int?
  let endMs: Int?
}

enum HomeSpeechStopReason {
  case userStopped
  case disconnected
  case completed
}
