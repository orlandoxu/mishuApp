import Foundation

struct DetectedDateTime: Equatable {
  let matchedText: String
  let nsRange: NSRange
  let date: Date
  let timeZone: TimeZone?
  let duration: TimeInterval
}

enum NaturalDateTimeDetector {
  private static let detector: NSDataDetector? = try? NSDataDetector(
    types: NSTextCheckingResult.CheckingType.date.rawValue
  )

  static func detect(in text: String) -> [DetectedDateTime] {
    guard let detector, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return []
    }

    let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
    return detector.matches(in: text, options: [], range: fullRange).compactMap { result in
      guard
        result.resultType == .date,
        let date = result.date,
        let range = Range(result.range, in: text)
      else {
        return nil
      }
      return DetectedDateTime(
        matchedText: String(text[range]),
        nsRange: result.range,
        date: date,
        timeZone: result.timeZone,
        duration: result.duration
      )
    }
    .sorted { $0.nsRange.location < $1.nsRange.location }
  }
}
