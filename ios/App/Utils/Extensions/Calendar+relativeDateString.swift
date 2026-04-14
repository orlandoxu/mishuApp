import Foundation

extension Calendar {
  func relativeDateString(_ date: Date?, dateFormat: String = "MM月dd日")
    -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat

    guard let date = date else {
      return "无限"
    }

    if isDateInToday(date) {
      return "今天"
    } else if isDateInTomorrow(date) {
      return "明天"
    } else if isDateInYesterday(date) {
      return "昨天"
    } else if isDate(
      date,
      inSameDayAs: self.date(byAdding: .day, value: -2, to: Date())!
    ) {
      return "前天"
    } else if isDate(
      date,
      inSameDayAs: self.date(byAdding: .day, value: 2, to: Date())!
    ) {
      return "后天"
    } else {
      return dateFormatter.string(from: date)
    }
  }
}
