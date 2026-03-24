import UIKit

enum TimelineZoomLevel: Int {
  case coarse = 0
  case fine = 1

  var hourWidth: CGFloat {
    // Step 1. 返回每小时的宽度
    switch self {
    case .coarse: 120
    case .fine: 120
    }
  }

  var ticksPerHour: Int {
    // Step 1. 返回每小时刻度数量
    switch self {
    case .coarse: 6
    case .fine: 6
    }
  }

  var secondsPerTick: Int {
    // Step 1. 返回每个刻度对应秒数
    switch self {
    case .coarse: 600
    case .fine: 600
    }
  }

  var pixelsPerSecond: CGFloat {
    // Step 1. 计算每秒像素密度
    hourWidth / 3600.0
  }

  func toggled() -> TimelineZoomLevel {
    // Step 1. 切换缩放级别
    self == .coarse ? .fine : .coarse
  }
}
