import Foundation

enum TCardPlaybackSpeed: Int, CaseIterable {
  case x0_5 = 0
  case x1 = 1
  case x2 = 2

  var title: String {
    switch self {
    case .x0_5: "0.5X"
    case .x1: "1X"
    case .x2: "2X"
    }
  }
}

enum TCardReplayRangeKind: Int, Equatable {
  case empty = 0
  case normal = 1
  case event = 2
}

struct TCardReplayRange: Identifiable, Equatable {
  let id: String
  let startTimeMs: Int64
  let endTimeMs: Int64
  let kind: TCardReplayRangeKind
  let fileId: Int?
  let historyType: Int?
  let channel: Int?
}

struct TCardReplaySegment: Identifiable, Equatable {
  let id: String
  let fileId: Int
  let startTimeMs: Int64
  let endTimeMs: Int64
  let historyType: Int
  let channel: Int
}
