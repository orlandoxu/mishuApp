import Foundation

final class VoiceMemoryPipeline {
  static let shared = VoiceMemoryPipeline()

  private let embeddingAPI: DoubaoEmbeddingAPI
  private let memoryAPI: MemoryAPI

  init(
    embeddingAPI: DoubaoEmbeddingAPI = .shared,
    memoryAPI: MemoryAPI = .shared
  ) {
    self.embeddingAPI = embeddingAPI
    self.memoryAPI = memoryAPI
  }

  func processIfNeeded(text: String) async {
    let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return }
    guard VoiceMemoryIntentDetector.shouldRecord(cleaned) else {
      LKLog("memory skipped: intent not matched text=\(cleaned)", type: "memory", label: "debug")
      return
    }

    guard let embedding = await embeddingAPI.embed(text: cleaned) else {
      LKLog("memory skipped: embedding failed", type: "memory", label: "warning")
      return
    }

    let userId = await MainActor.run { SelfStore.shared.selfUser?.userId ?? "" }
    guard !userId.isEmpty else {
      LKLog("memory skipped: missing user id", type: "memory", label: "warning")
      return
    }

    let payload = MemoryIngestPayload(
      userId: userId,
      text: cleaned,
      embedding: embedding,
      embeddingModel: AppConst.doubaoEmbeddingModel,
      embeddingDimension: embedding.count,
      source: "voice",
      createdAtMs: Int64(Date().timeIntervalSince1970 * 1000)
    )

    let saved = await memoryAPI.ingest(payload: payload)
    LKLog(
      "memory ingest \(saved ? "success" : "failed") text=\(cleaned.prefix(48)) dim=\(embedding.count)",
      type: "memory",
      label: saved ? "info" : "warning"
    )
  }
}

enum VoiceMemoryIntentDetector {
  // 仅在“明显是要记录/提醒”的语句下触发，避免把普通闲聊都写入记忆。
  static func shouldRecord(_ text: String) -> Bool {
    let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard normalized.count >= 2 else { return false }

    let keywords = [
      "记一下", "记住", "帮我记", "记到", "备忘", "待办", "提醒我", "别忘",
      "todo", "memo", "remind me", "note this", "remember this",
    ]

    if keywords.contains(where: { normalized.contains($0) }) {
      return true
    }

    // 兜底规则：带明确时间词 + 可执行事项词，视为待记录事项。
    let timeMarkers = ["今天", "明天", "后天", "下周", "下个月", " tonight", " tomorrow", " next week"]
    let actionMarkers = ["要", "需要", "安排", "去", "买", "缴", "处理", "完成", "call", "pay", "buy", "schedule"]
    let hasTime = timeMarkers.contains { normalized.contains($0) }
    let hasAction = actionMarkers.contains { normalized.contains($0) }
    return hasTime && hasAction
  }
}
