import Foundation

/**
 * 对String的扩展（注：该扩展，和业务逻辑紧密相关）
 * 用于判断时间是否有效，以及比较两个时间字符串的大小
 */

extension String {
  // 比较两个时间之间的大小
  // 有多种格式：
  // 1. HH:mm
  // 2. 周一 HH:mm / 周二 HH:mm / 周三 HH:mm / 周四 HH:mm / 周五 HH:mm / 周六 HH:mm / 周日 HH:mm
  // 3. 21号 HH:mm
  // 4. 01/24 HH:mm
  // 返回nil表示无法比较
  func timeBiggerThan(_ otherTime: String) -> Bool? {
    // 1. HH:mm
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    if let date1 = dateFormatter.date(from: self),
      let date2 = dateFormatter.date(from: otherTime) {
      print("分支1")
      return date1 > date2
    }

    // 2. 周一 HH:mm / 周二 HH:mm / 周三 HH:mm / 周四 HH:mm / 周五 HH:mm / 周六 HH:mm / 周日 HH:mm
    // 如果以"周"开头，则需要比较周几
    print(self, otherTime)
    if self.hasPrefix("周") && otherTime.hasPrefix("周") {
      let week1 = self.prefix(2)
      let week2 = otherTime.prefix(2)
      // 比较week1和week2，"周一" < "周二" < "周三" < "周四" < "周五" < "周六" < "周日"
      let weekOrder = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]

      if week1 != week2 {
        if let index1 = weekOrder.firstIndex(of: String(week1)),
          let index2 = weekOrder.firstIndex(of: String(week2)) {
          print("index1: \(index1), index2: \(index2)")
          return index1 > index2
        } else {
          print("周 nil")
          return nil
        }
      } else {
        // 如果周几相同，则比较时间
        if let date1 = dateFormatter.date(from: String(self.suffix(5))),
          let date2 = dateFormatter.date(from: String(otherTime.suffix(5))) {
          print("分支22")
          return date1 > date2
        } else {
          print("分支23")
          return nil
        }
      }
    }

    // 3. 21号 HH:mm
    // Step 3.1 先比较多少号谁大
    if self.contains("号") && otherTime.contains("号") {
      print("分支1")
      let date1 = self.prefix(while: { $0.isNumber })
      let date2 = otherTime.prefix(while: { $0.isNumber })

      if let day1 = Int(date1), let day2 = Int(date2) {
        if day1 != day2 {
          return day1 > day2
        } else {
          // Step 3.2 如果都是一个号，则比较时间
          let time1 = self.suffix(
            from: self.index(self.firstIndex(of: " ")!, offsetBy: 1)
          )
          let time2 = otherTime.suffix(
            from: otherTime.index(otherTime.firstIndex(of: " ")!, offsetBy: 1)
          )
          if let date1 = dateFormatter.date(from: String(time1)),
            let date2 = dateFormatter.date(from: String(time2)) {
            return date1 > date2
          } else {
            return nil
          }
        }
      } else {
        return nil
      }
    }

    // 4. 01/24 HH:mm 格式
    dateFormatter.dateFormat = "MM/dd HH:mm"
    if let date1 = dateFormatter.date(from: self),
      let date2 = dateFormatter.date(from: otherTime) {
      print("分支4")
      return date1 > date2
    }

    print("分支5")

    return nil  // 无法比较时返回 nil
  }

  // 和业务逻辑有关的代码：
  // 符合HH:mm格式，则返回true
  func isValidDayString() -> Bool {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "HH:mm"
    return dateFormatter.date(from: self) != nil
  }

  // "周几 HH:mm" 格式
  func isValidWeekString() -> Bool {
    // 1. 先判断是否以"周"开头
    if !self.hasPrefix("周") {
      return false
    }

    // 2. 再判断是否符合HH:mm格式
    return String(self.suffix(5)).isValidDayString()
  }

  // "2号 HH:mm" 格式
  func isValidMonthString() -> Bool {
    // 1. 先判断是否包含"号"
    if !self.contains("号") {
      return false
    }

    // 2. 再判断是否符合HH:mm格式
    // 通过号分隔开
    let parts = self.split(separator: " ")
    if parts.count != 2 {
      return false
    }

    return String(parts[1]).isValidDayString()
  }

  // "01/24 HH:mm" 格式
  // 不能通过dateFormatter："MM/dd HH:mm" 来判断
  // 因为默认是使用当前年份，可能会有问题
  func isValidYearString() -> Bool {
    // 采用正则匹配来判断
    // 这儿判断比较宽泛，其实符合格式就行了
    let regex = "^\\d{2}/\\d{2} \\d{2}:\\d{2}$"
    return self.range(of: regex, options: .regularExpression) != nil
  }
}
