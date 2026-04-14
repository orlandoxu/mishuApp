import Foundation

extension Date {
  /// 获取今天的 23:59:59 时间
  static func endOfDay(for date: Date = Date()) -> Date {
    let calendar = Calendar.current
    // 获取指定日期的起始时间（00:00:00）
    let startOfDay = calendar.startOfDay(for: date)

    // 设置时间为 23:59:59
    return calendar.date(byAdding: .second, value: 86399, to: startOfDay)!
  }

  /// 获取指定日期的开始时间 00:00:00
  static func startOfDay(for date: Date = Date()) -> Date {
    let calendar = Calendar.current
    return calendar.startOfDay(for: date)
  }

  /// 获取明天的 00:00:00
  static var startOfTomorrow: Date {
    let calendar = Calendar.current
    let now = Date()
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
    return calendar.startOfDay(for: tomorrow)
  }

  /// 获取昨天的 23:59:59
  static var endOfYesterday: Date {
    let calendar = Calendar.current
    let now = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    return endOfDay(for: yesterday)
  }

  /// 获取指定日期的开始时间 00:00:00
  var startOfDay: Date {
    return Date.startOfDay(for: self)
  }

  /// 获取指定日期的结束时间 23:59:59
  var endOfDay: Date {
    return Date.endOfDay(for: self)
  }

  var startOfMonth: Date {
    Calendar.current.date(
      from: Calendar.current.dateComponents([.year, .month], from: self)
    ) ?? self
  }

  var endOfMonth: Date {
    Calendar.current.date(
      byAdding: DateComponents(month: 1, day: -1),
      to: startOfMonth
    ) ?? self
  }

  /// 返回不带小数部分的时间戳
  var timestamp: Int {
    return Int(timeIntervalSince1970)
  }

  static func messageRelativeTimeText(from timestamp: Int) -> String {
    if timestamp <= 0 { return "" }

    let seconds: TimeInterval
    if timestamp > 1_000_000_000_000 {
      seconds = TimeInterval(timestamp) / 1000.0
    } else {
      seconds = TimeInterval(timestamp)
    }

    let date = Date(timeIntervalSince1970: seconds)
    let delta = Int(Date().timeIntervalSince(date))

    if delta < 60 { return "刚刚" }
    if delta < 3600 { return "\(delta / 60)分钟前" }
    if delta < 86400 { return "\(delta / 3600)小时前" }
    if delta < 86400 * 7 { return "\(delta / 86400)天前" }

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
