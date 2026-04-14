import Foundation

// 扩展Double
extension Double {
  func randomBetween(_ num: Double) -> Double {
    // 在self 和 num之间，随机生成数
    let min = Swift.min(self, num)
    let max = Swift.max(self, num)

    return Double.random(in: min...max)
  }

  // 采样次数
  func randomBetweenToCenter(_ num: Double, times: Int = 4) -> Double {
    // 在self 和 num之间，随机生成数
    let min = Swift.min(self, num)
    let max = Swift.max(self, num)

    // 在min和max之间，随机生成times个随机数
    var result = [Double]()
    for _ in 0..<times {
      result.append(Double.random(in: min...max))
    }

    // 计算平均值
    let average = result.reduce(0, +) / Double(times)

    return average
  }

  // 精确到小数点后n位
  func roundTo(_ n: Int = 10) -> Double {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = n
    // 使用 formatter 格式化数字并返回 Double
    if let formattedString = formatter.string(from: NSNumber(value: self)),
      let roundedValue = Double(formattedString) {
      return roundedValue
    }
    return self  // 如果格式化失败，则返回原始值
  }
}
