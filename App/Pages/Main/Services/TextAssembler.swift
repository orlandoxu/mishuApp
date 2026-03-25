import Foundation

struct VoiceTextAssembler {
  private var committedFingerprints: Set<String> = []
  private var confirmedText: String = ""
  private var previewText: String = ""
  private var previewFingerprint: String = ""

  var currentText: String {
    confirmedText + previewText
  }

  mutating func reset() {
    committedFingerprints.removeAll()
    confirmedText = ""
    previewText = ""
    previewFingerprint = ""
  }

  mutating func consume(_ utterances: [AsrUtterance]) -> String {
    var latestPreview: (text: String, utterance: AsrUtterance)?

    for utterance in utterances {
      let normalized = utterance.text
      guard !normalized.isEmpty else { continue }

      if utterance.definite {
        commitDefiniteIfNeeded(normalized, utterance: utterance)
      } else {
        latestPreview = (normalized, utterance)
      }
    }

    if let latestPreview {
      updatePreview(latestPreview.text, utterance: latestPreview.utterance)
    } else {
      clearPreviewIfNeeded()
    }

    return currentText
  }

  private mutating func commitDefiniteIfNeeded(_ text: String, utterance: AsrUtterance) {
    let fp = fingerprint(utterance: utterance, text: text)
    guard !committedFingerprints.contains(fp) else { return }

    committedFingerprints.insert(fp)
    confirmedText = mergeByOverlap(base: confirmedText, incoming: text)

    if previewFingerprint == fp || previewText == text {
      previewText = ""
      previewFingerprint = ""
    }
  }

  private mutating func updatePreview(_ text: String, utterance: AsrUtterance) {
    let fp = fingerprint(utterance: utterance, text: text)
    guard !committedFingerprints.contains(fp) else {
      clearPreviewIfNeeded()
      return
    }

    if fp == previewFingerprint, text == previewText {
      return
    }

    previewFingerprint = fp
    previewText = text
  }

  private mutating func clearPreviewIfNeeded() {
    guard !previewText.isEmpty || !previewFingerprint.isEmpty else { return }
    previewText = ""
    previewFingerprint = ""
  }

  private func fingerprint(utterance: AsrUtterance, text: String) -> String {
    let start = utterance.startMs.map(String.init) ?? "na"
    let end = utterance.endMs.map(String.init) ?? "na"
    return "\(start)|\(end)|\(text)"
  }

  private func mergeByOverlap(base: String, incoming: String) -> String {
    guard !incoming.isEmpty else { return base }
    guard !base.isEmpty else { return incoming }

    if base.hasSuffix(incoming) {
      return base
    }

    let maxOverlap = min(base.count, incoming.count)
    if maxOverlap > 0 {
      for overlap in stride(from: maxOverlap, through: 1, by: -1) {
        let baseSuffix = String(base.suffix(overlap))
        let incomingPrefix = String(incoming.prefix(overlap))
        if baseSuffix == incomingPrefix {
          return base + incoming.dropFirst(overlap)
        }
      }
    }

    return base + incoming
  }
}
