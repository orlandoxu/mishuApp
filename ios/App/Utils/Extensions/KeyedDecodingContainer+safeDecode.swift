import Foundation

/// 扩展 KeyedDecodingContainer，提供 safeDecode 和 safeDecodeDate 方法
extension KeyedDecodingContainer {
  // safeDecode: 处理异常，提供默认值
  func safeDecodeString(
    _ key: K,
    _ defaultValue: String
  ) -> String {
    do {
      return try decodeIfPresent(String.self, forKey: key) ?? defaultValue
    } catch {
      return defaultValue
    }
  }

  func safeDecodeInt(
    _ key: K,
    _ defaultValue: Int
  ) -> Int {
    do {
      if let value = try decodeIfPresent(Int.self, forKey: key) {
        return value
      }
      if let value = try decodeIfPresent(Int64.self, forKey: key) {
        return Int(value)
      }
      if let value = try decodeIfPresent(Double.self, forKey: key) {
        return Int(value)
      }
      if let value = try decodeIfPresent(String.self, forKey: key) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let parsed = Int(trimmed) {
          return parsed
        }
        if let parsed = Double(trimmed) {
          return Int(parsed)
        }
      }
      if let value = try decodeIfPresent(Bool.self, forKey: key) {
        return value ? 1 : 0
      }
      return defaultValue
    } catch {
      return defaultValue
    }
  }

  func safeDecodeInt64(
    _ key: K,
    _ defaultValue: Int64
  ) -> Int64 {
    do {
      if let value = try decodeIfPresent(Int64.self, forKey: key) {
        return value
      }
      if let value = try decodeIfPresent(Int.self, forKey: key) {
        return Int64(value)
      }
      if let value = try decodeIfPresent(Double.self, forKey: key) {
        return Int64(value)
      }
      if let value = try decodeIfPresent(String.self, forKey: key),
         let parsed = Int64(value)
      {
        return parsed
      }
      return defaultValue
    } catch {
      return defaultValue
    }
  }

  func safeDecodeDouble(
    _ key: K,
    _ defaultValue: Double,
    decimalPlaces: Int16 = 7
  ) -> Double {
    do {
      let decodedValue: Double
      if let value = try decodeIfPresent(Double.self, forKey: key) {
        decodedValue = value
      } else if let value = try decodeIfPresent(Int.self, forKey: key) {
        decodedValue = Double(value)
      } else if let value = try decodeIfPresent(Int64.self, forKey: key) {
        decodedValue = Double(value)
      } else if let value = try decodeIfPresent(String.self, forKey: key) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if let parsed = Double(trimmed) {
          decodedValue = parsed
        } else {
          decodedValue = defaultValue
        }
      } else if let value = try decodeIfPresent(Bool.self, forKey: key) {
        decodedValue = value ? 1 : 0
      } else {
        decodedValue = defaultValue
      }

      // 使用 NSDecimalNumber 进行四舍五入或精度控制
      let decimalValue = NSDecimalNumber(value: decodedValue)
      let roundingBehavior = NSDecimalNumberHandler(
        roundingMode: .plain,
        scale: decimalPlaces,
        raiseOnExactness: false,
        raiseOnOverflow: false,
        raiseOnUnderflow: false,
        raiseOnDivideByZero: false
      )

      // 将数值四舍五入并返回
      let roundedValue = decimalValue.rounding(
        accordingToBehavior: roundingBehavior
      )

      return roundedValue.doubleValue
    } catch {
      return defaultValue
    }
  }

  /// bool
  func safeDecodeBool(
    _ key: K,
    _ defaultValue: Bool
  ) -> Bool {
    do {
      return try decodeIfPresent(Bool.self, forKey: key) ?? defaultValue
    } catch {
      return defaultValue
    }
  }

  // safeDecodeDate: 将时间字符串解码成 Date，若失败则返回默认值
  func safeDecodeDate(
    _ key: K,
    _ defaultValue: Date? = Date()
  ) -> Date? {
    let dateFormats = [
      "yyyy-MM-dd'T'HH:mm:ssZ", // ISO8601 格式
      "yyyy-MM-dd HH:mm:ss", // 简单日期时间格式
      "yyyy/MM/dd HH:mm:ss", // 简单日期时间格式2
    ]

    do {
      if let dateString = try decodeIfPresent(String.self, forKey: key) {
        // 尝试将字符串 / 或者Int类型，解析为时间戳（整数）
        if let timestamp = Int(dateString) {
          return Date(timeIntervalSince1970: TimeInterval(timestamp))
        }

        // 遍历多个格式进行尝试
        for format in dateFormats {
          let formatter = DateFormatter()
          formatter.dateFormat = format
          if let date = formatter.date(from: dateString) {
            return date
          }
        }
      }
    } catch {
      // 解析错误或缺失字段时返回默认值
      return defaultValue
    }
    return defaultValue
  }

  /// 泛型安全解码方法
  func safeDecodeArray<T: Decodable>(
    _ key: K,
    _ defaultValue: [T] = []
  ) -> [T] {
    do {
      return try decodeIfPresent([T].self, forKey: key) ?? defaultValue
    } catch {
      return defaultValue
    }
  }

  /// 解析对象
  func safeDecodeObject<T: Decodable>(
    _ key: K,
    _ defaultValue: T
  ) -> T {
    do {
      return try decodeIfPresent(T.self, forKey: key) ?? defaultValue
    } catch {
      return defaultValue
    }
  }
}
