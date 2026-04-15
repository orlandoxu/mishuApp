import Foundation
import NaturalLanguage

struct DetectedPersonName: Equatable {
  let name: String
  let nsRange: NSRange
}

struct DetectedEntities: Equatable {
  let personNames: [DetectedPersonName]
  let dateTimes: [DetectedDateTime]

  var isEmpty: Bool {
    personNames.isEmpty && dateTimes.isEmpty
  }
}

enum NaturalEntityDetector {
  private static let trimScalars = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
  private static let chineseNameIntentPrefixes = ["联系一下", "联系", "提醒", "通知", "给", "叫", "约", "找", "告诉"]
  private static let chineseNameStopWords = ["开会", "发消息", "打电话", "电话", "消息", "一下"]
  private static let chineseNameTrailingNoise = ["下午", "上午", "晚上", "中午", "早上"]
  private static let englishFullNameRegex = try? NSRegularExpression(
    pattern: #"\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+\b"#,
    options: []
  )
  private static let trailingVerbCandidates: Set<Character> = [
    "发", "打", "说", "讲", "问", "聊", "喊", "叫", "约", "找", "通知", "联", "系"
  ].flatMap(\.description).reduce(into: Set<Character>()) { partial, char in
    partial.insert(char)
  }

  static func detect(in text: String) -> DetectedEntities {
    DetectedEntities(
      personNames: detectPersonNames(in: text),
      dateTimes: detectDateTimes(in: text)
    )
  }

  static func detectPersonNames(in text: String) -> [DetectedPersonName] {
    let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !input.isEmpty else { return [] }

    var seen: Set<String> = []
    var results: [DetectedPersonName] = []
    appendDeduped(
      detectPersonNamesWithTagger(in: input),
      to: &results,
      seen: &seen
    )
    appendDeduped(
      detectPersonNamesWithRules(in: input),
      to: &results,
      seen: &seen
    )

    return results.sorted { $0.nsRange.location < $1.nsRange.location }
  }

  private static func detectPersonNamesWithTagger(in input: String) -> [DetectedPersonName] {
    let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
    tagger.string = input

    let nsText = input as NSString
    var results: [DetectedPersonName] = []
    let fullRange = input.startIndex..<input.endIndex

    tagger.enumerateTags(
      in: fullRange,
      unit: .word,
      scheme: .nameTypeOrLexicalClass,
      options: [.omitWhitespace, .omitPunctuation, .joinNames]
    ) { tag, tokenRange in
      guard tag == .personalName else { return true }

      let raw = String(input[tokenRange])
      let cleaned = sanitize(rawName: raw)
      guard isLikelyName(cleaned) else { return true }

      let rawNSRange = NSRange(tokenRange, in: input)
      let localRange = nsText.range(of: cleaned, options: [], range: rawNSRange)
      let finalRange = localRange.location != NSNotFound ? localRange : rawNSRange
      results.append(DetectedPersonName(name: cleaned, nsRange: finalRange))
      return true
    }

    return results
  }

  private static func detectPersonNamesWithRules(in input: String) -> [DetectedPersonName] {
    let nsInput = input as NSString
    var results: [DetectedPersonName] = []

    for prefix in chineseNameIntentPrefixes {
      var searchRange = NSRange(location: 0, length: nsInput.length)
      while true {
        let hit = nsInput.range(of: prefix, options: [], range: searchRange)
        guard hit.location != NSNotFound else { break }
        let start = hit.location + hit.length
        guard start < nsInput.length else { break }

        let tailRange = NSRange(location: start, length: nsInput.length - start)
        let tail = nsInput.substring(with: tailRange)
        let extracted = extractChineseNameCandidates(fromTail: tail)

        for candidate in extracted {
          let clean = sanitize(rawName: candidate)
          guard isLikelyName(clean) else { continue }
          let candidateRange = nsInput.range(of: clean, options: [], range: tailRange)
          guard candidateRange.location != NSNotFound else { continue }
          results.append(DetectedPersonName(name: clean, nsRange: candidateRange))
        }

        let nextStart = hit.location + 1
        guard nextStart < nsInput.length else { break }
        searchRange = NSRange(location: nextStart, length: nsInput.length - nextStart)
      }
    }

    if let englishFullNameRegex {
      let fullRange = NSRange(location: 0, length: nsInput.length)
      for match in englishFullNameRegex.matches(in: input, options: [], range: fullRange) {
        guard match.range.location != NSNotFound else { continue }
        let matched = nsInput.substring(with: match.range)
        let clean = sanitize(rawName: matched)
        guard isLikelyName(clean) else { continue }
        results.append(DetectedPersonName(name: clean, nsRange: match.range))
      }
    }

    return results
  }

  private static func extractChineseNameCandidates(fromTail tail: String) -> [String] {
    guard !tail.isEmpty else { return [] }
    var segment = tail

    for marker in ["，", ",", "。", "！", "!", "？", "?", "\n"] {
      if let index = segment.firstIndex(of: Character(marker)) {
        segment = String(segment[..<index])
      }
    }

    for stopWord in chineseNameStopWords {
      if let range = segment.range(of: stopWord) {
        segment = String(segment[..<range.lowerBound])
      }
    }

    let normalized = segment.replacingOccurrences(of: "一下", with: "")
      .trimmingCharacters(in: trimScalars)
    guard !normalized.isEmpty else { return [] }

    return normalized
      .split(separator: "和")
      .map { String($0).trimmingCharacters(in: trimScalars) }
      .filter { !$0.isEmpty }
  }

  private static func appendDeduped(
    _ items: [DetectedPersonName],
    to results: inout [DetectedPersonName],
    seen: inout Set<String>
  ) {
    for item in items {
      let lookup = item.name.lowercased()
      guard !seen.contains(lookup) else { continue }
      seen.insert(lookup)
      results.append(item)
    }
  }

  private static func sanitize(rawName: String) -> String {
    var cleaned = rawName.trimmingCharacters(in: trimScalars)
    guard !cleaned.isEmpty else { return cleaned }

    // 中文场景中 NLTagger 有时会把动词尾巴并入人名（如“张三发”）。
    if containsChinese(cleaned), cleaned.count >= 3, let tail = cleaned.last, trailingVerbCandidates.contains(tail) {
      cleaned.removeLast()
    }
    if containsChinese(cleaned) {
      for noise in chineseNameTrailingNoise where cleaned.hasSuffix(noise) {
        cleaned.removeLast(noise.count)
      }
    }

    return cleaned.trimmingCharacters(in: trimScalars)
  }

  private static func isLikelyName(_ text: String) -> Bool {
    guard !text.isEmpty else { return false }
    if containsChinese(text) {
      return text.count >= 2 && text.count <= 5
    }
    let latinCount = text.unicodeScalars.reduce(into: 0) { partial, scalar in
      if CharacterSet.letters.contains(scalar) {
        partial += 1
      }
    }
    return latinCount >= 2
  }

  private static func containsChinese(_ text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
      scalar.value >= 0x4E00 && scalar.value <= 0x9FFF
    }
  }
}
