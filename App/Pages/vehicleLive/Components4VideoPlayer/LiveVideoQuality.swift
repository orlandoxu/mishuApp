import Foundation

enum LiveVideoQuality: String, CaseIterable, Identifiable {
  case hd = "高清"
  case uhd = "超清"
  case bluray = "蓝光"

  var id: String {
    rawValue
  }

  var qos: Int {
    switch self {
    case .hd:
      1
    case .uhd:
      2
    case .bluray:
      3
    }
  }
}
