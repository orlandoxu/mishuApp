import Foundation

final class VoiceMemoryPipeline {
  static let shared = VoiceMemoryPipeline()

  private let embeddingAPI: DoubaoEmbeddingAPI
  private let chatAPI: DoubaoChatAPI
  private let memoryAPI: MemoryAPI

  init(
    embeddingAPI: DoubaoEmbeddingAPI = .shared,
    chatAPI: DoubaoChatAPI = .shared,
    memoryAPI: MemoryAPI = .shared
  ) {
    self.embeddingAPI = embeddingAPI
    self.chatAPI = chatAPI
    self.memoryAPI = memoryAPI
  }

  func processUserInput(_ text: String) async -> String {
    let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return "我没有听清楚，请再说一次。" }

    let userId = await MainActor.run { SelfStore.shared.selfUser?.userId ?? "" }
    guard !userId.isEmpty else {
      return cleaned
    }

    do {
      try AppDatabase.shared.setupIfNeeded(userId: userId)
    } catch {
      LKLog("memory db setup failed: \(error.localizedDescription)", type: "memory", label: "error")
      return cleaned
    }

    let plan = await analyzeIntent(text: cleaned)
    var retrieved: [MemoryRecord] = []

    if plan.shouldStore {
      let textToStore = plan.storeText.isEmpty ? cleaned : plan.storeText
      await persistMemory(text: textToStore, userId: userId)
    }

    if plan.shouldRetrieve {
      let query = plan.retrieveQuery.isEmpty ? cleaned : plan.retrieveQuery
      retrieved = await retrieveMemory(userId: userId, query: query)
    }

    if plan.shouldRetrieve {
      let reply = await generateAnswer(userInput: cleaned, memories: retrieved)
      if let reply, !reply.isEmpty { return reply }
    }

    if !plan.directReply.isEmpty {
      return plan.directReply
    }
    return cleaned
  }

  private func analyzeIntent(text: String) async -> MemoryIntentPlan {
    let system = """
    你是车载语音助手的意图分类器。
    只输出 JSON，不要输出其他文本。
    字段：
    - should_store: bool
    - store_text: string
    - should_retrieve: bool
    - retrieve_query: string
    - direct_reply: string
    规则：
    1) 当用户在新增备忘、提醒、待办时 should_store=true。
    2) 当用户在问“之前记了什么/帮我回忆/查一下我记过的内容”等时 should_retrieve=true。
    3) store_text/retrieve_query 需是提炼后的简洁文本。
    4) direct_reply 只在不需要检索时给，简短自然。
    """
    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0.1) else {
      return MemoryIntentPlan.fallback(for: text)
    }
    return MemoryIntentPlan.parse(from: content) ?? MemoryIntentPlan.fallback(for: text)
  }

  private func persistMemory(text: String, userId: String) async {
    guard let embedding = await embeddingAPI.embed(text: text) else {
      LKLog("memory store skipped: embedding failed", type: "memory", label: "warning")
      return
    }
    let createdAtMs = Int64(Date().timeIntervalSince1970 * 1000)
    do {
      try MemoryVectorStore.shared.insert(
        userId: userId,
        text: text,
        source: "voice",
        embedding: embedding,
        createdAtMs: createdAtMs
      )
    } catch {
      LKLog("memory local insert failed: \(error.localizedDescription)", type: "memory", label: "error")
    }

    let payload = MemoryIngestPayload(
      userId: userId,
      text: text,
      embedding: embedding,
      embeddingModel: AppConst.doubaoEmbeddingModel,
      embeddingDimension: embedding.count,
      source: "voice",
      createdAtMs: createdAtMs
    )
    let saved = await memoryAPI.ingest(payload: payload)
    LKLog(
      "memory ingest \(saved ? "success" : "failed") text=\(text.prefix(48)) dim=\(embedding.count)",
      type: "memory",
      label: saved ? "info" : "warning"
    )
  }

  private func retrieveMemory(userId: String, query: String) async -> [MemoryRecord] {
    guard let queryEmbedding = await embeddingAPI.embed(text: query) else {
      return []
    }
    do {
      return try MemoryVectorStore.shared.search(userId: userId, queryEmbedding: queryEmbedding, limit: 5)
    } catch {
      LKLog("memory search failed: \(error.localizedDescription)", type: "memory", label: "error")
      return []
    }
  }

  private func generateAnswer(userInput: String, memories: [MemoryRecord]) async -> String? {
    let memoryText: String
    if memories.isEmpty {
      memoryText = "没有检索到相关记忆。"
    } else {
      memoryText = memories.enumerated().map { index, item in
        "\(index + 1). \(item.text)"
      }.joined(separator: "\n")
    }

    let system = """
    你是车载语音助手。请结合“检索记忆”回答用户。
    要求：中文、简洁、口语化；若没有相关记忆，明确告诉用户并建议他重新记录。
    """
    let user = """
    用户输入：\(userInput)
    检索记忆：
    \(memoryText)
    """
    return await chatAPI.chat(systemPrompt: system, userPrompt: user, temperature: 0.4)
  }
}

struct MemoryIntentPlan: Codable, Equatable {
  let shouldStore: Bool
  let storeText: String
  let shouldRetrieve: Bool
  let retrieveQuery: String
  let directReply: String

  private enum CodingKeys: String, CodingKey {
    case shouldStore = "should_store"
    case storeText = "store_text"
    case shouldRetrieve = "should_retrieve"
    case retrieveQuery = "retrieve_query"
    case directReply = "direct_reply"
  }

  static func parse(from raw: String) -> MemoryIntentPlan? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard let data = extractJSONBlock(from: trimmed)?.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(MemoryIntentPlan.self, from: data)
  }

  static func fallback(for input: String) -> MemoryIntentPlan {
    let normalized = input.lowercased()
    let store = ["记一下", "记住", "提醒", "待办", "备忘"].contains { normalized.contains($0) }
    let retrieve = ["查一下", "回忆", "之前记", "我记了什么", "搜索"].contains { normalized.contains($0) }
    return MemoryIntentPlan(
      shouldStore: store,
      storeText: store ? input : "",
      shouldRetrieve: retrieve,
      retrieveQuery: retrieve ? input : "",
      directReply: store ? "好的，我先帮你记下来了。" : ""
    )
  }

  private static func extractJSONBlock(from text: String) -> String? {
    guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return nil }
    guard start <= end else { return nil }
    return String(text[start ... end])
  }
}
