import Foundation
import NaturalLanguage

struct DetectedPersonName: Equatable {
  let name: String
  let nsRange: NSRange
}

enum PersonNameDetector {
  private static let trimScalars = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
  private static let trailingVerbCandidates: Set<Character> = [
    "发", "打", "说", "讲", "问", "聊", "喊", "叫", "约", "找", "通知", "联", "系"
  ].flatMap(\.description).reduce(into: Set<Character>()) { partial, char in
    partial.insert(char)
  }

  static func detect(in text: String) -> [DetectedPersonName] {
    let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !input.isEmpty else { return [] }

    let tagger = NLTagger(tagSchemes: [.nameTypeOrLexicalClass])
    tagger.string = input

    let nsText = input as NSString
    var seen: Set<String> = []
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

      let lookup = cleaned.lowercased()
      guard !seen.contains(lookup) else { return true }
      seen.insert(lookup)

      let rawNSRange = NSRange(tokenRange, in: input)
      let localRange = nsText.range(of: cleaned, options: [], range: rawNSRange)
      let finalRange = localRange.location != NSNotFound ? localRange : rawNSRange
      results.append(DetectedPersonName(name: cleaned, nsRange: finalRange))
      return true
    }

    return results.sorted { $0.nsRange.location < $1.nsRange.location }
  }

  private static func sanitize(rawName: String) -> String {
    var cleaned = rawName.trimmingCharacters(in: trimScalars)
    guard !cleaned.isEmpty else { return cleaned }

    // 中文场景中 NLTagger 有时会把动词尾巴并入人名（如“张三发”）。
    if containsChinese(cleaned), cleaned.count >= 3, let tail = cleaned.last, trailingVerbCandidates.contains(tail) {
      cleaned.removeLast()
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
