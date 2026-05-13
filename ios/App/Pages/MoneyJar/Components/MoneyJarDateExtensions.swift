import Foundation

extension Calendar {
  static var moneyJar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 2
    return calendar
  }
}

extension Date {
  static var mishuMoneyJarSeed: Date {
    Calendar.moneyJar.date(from: DateComponents(year: 2024, month: 4, day: 24)) ?? Date()
  }

  var moneyJarMonthStart: Date {
    Calendar.moneyJar.date(from: Calendar.moneyJar.dateComponents([.year, .month], from: self)) ?? self
  }

  var moneyJarWeekStart: Date {
    Calendar.moneyJar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
  }

  var moneyJarWeekTitle: String {
    let calendar = Calendar.moneyJar
    let start = moneyJarWeekStart
    let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "MM.dd"

    if calendar.isDate(start, inSameDayAs: Date.mishuMoneyJarSeed.moneyJarWeekStart) {
      return "\(formatter.string(from: start)) - \(formatter.string(from: end)) (本周)"
    }
    if let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date.mishuMoneyJarSeed),
       calendar.isDate(start, inSameDayAs: lastWeek.moneyJarWeekStart) {
      return "\(formatter.string(from: start)) - \(formatter.string(from: end)) (上周)"
    }
    return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
  }

  func addingMoneyJarWeeks(_ value: Int) -> Date {
    Calendar.moneyJar.date(byAdding: .weekOfYear, value: value, to: self) ?? self
  }

  func settingMoneyJarYear(_ year: Int) -> Date {
    var comps = Calendar.moneyJar.dateComponents([.month, .day], from: self)
    comps.year = year
    return Calendar.moneyJar.date(from: comps) ?? self
  }

  func moneyJarMockAmount(mode: String) -> Int? {
    let dayNumber = Int(timeIntervalSince1970 / 86_400)
    let raw = abs(sin(Double(dayNumber)) * 10_000)
    let fraction = raw - floor(raw)
    guard self <= Date(), fraction > 0.4 else { return nil }
    if mode == "expense" {
      return Int(fraction * 200) + 10
    }
    return Int(fraction * 500) + 50
  }
}
