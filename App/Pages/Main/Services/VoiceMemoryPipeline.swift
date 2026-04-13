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
    switch plan.normalizedIntent {
    case .clarify:
      if !plan.clarificationQuestion.isEmpty {
        return plan.clarificationQuestion
      }
      return "我想先确认一下你的意思：你是要记录新内容，还是想查找之前的记忆？"
    case .store:
      return await handleStoreIntent(plan: plan, cleanedInput: cleaned, userId: userId)
    case .retrieve:
      return await handleRetrieveIntent(plan: plan, cleanedInput: cleaned, userId: userId)
    case .amend:
      return await handleAmendIntent(plan: plan, cleanedInput: cleaned, userId: userId)
    case .chat, .unknown:
      if !plan.directReply.isEmpty {
        return plan.directReply
      }
      return cleaned
    }
  }

  private func analyzeIntent(text: String) async -> MemoryIntentPlan {
    let system = """
    你是车载语音助手的意图路由器。
    只输出 JSON，不要输出其他文本。
    字段：
    - intent: string，值只能是 store/retrieve/amend/clarify/chat/unknown
    - should_store: bool
    - store_text: string
    - should_retrieve: bool
    - retrieve_query: string
    - amendment_text: string
    - amendment_target_query: string
    - clarification_question: string
    - requires_confirmation: bool
    - direct_reply: string
    规则：
    1) 新增备忘、提醒、待办 => intent=store。
    2) 查记忆、回忆历史 => intent=retrieve。
    3) 修改/更正/补充旧记忆 => intent=amend，并提取 amendment_text + amendment_target_query。
    4) 信息不完整、需要用户确认 => intent=clarify，clarification_question 必填。
    5) 非记忆类闲聊/问候 => intent=chat。
    6) store_text/retrieve_query 要是提炼后的短语。
    7) direct_reply 只写给用户看的自然口语，不超过30字。
    """
    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0.1) else {
      return MemoryIntentPlan.fallback(for: text)
    }
    return MemoryIntentPlan.parse(from: content) ?? MemoryIntentPlan.fallback(for: text)
  }

  private func handleStoreIntent(plan: MemoryIntentPlan, cleanedInput: String, userId: String) async -> String {
    let textToStore = plan.storeText.isEmpty ? cleanedInput : plan.storeText
    await persistMemory(text: textToStore, userId: userId)

    if plan.requiresConfirmation {
      return plan.clarificationQuestion.isEmpty
        ? "我先记录了这条信息。你要不要我再补上时间或地点？"
        : plan.clarificationQuestion
    }
    if !plan.directReply.isEmpty {
      return plan.directReply
    }
    return "好的，我已经帮你记下来了。"
  }

  private func handleRetrieveIntent(plan: MemoryIntentPlan, cleanedInput: String, userId: String) async -> String {
    let query = plan.retrieveQuery.isEmpty ? cleanedInput : plan.retrieveQuery
    let retrieved = await retrieveMemory(userId: userId, query: query)
    if retrieved.isEmpty {
      return "我暂时没有找到相关记忆。你可以先说“帮我记一下...”，我会立刻保存。"
    }
    if plan.requiresConfirmation {
      return "我找到了这些可能相关的记忆：\n\(formatCandidates(retrieved))\n请告诉我更接近哪一条。"
    }
    let reply = await generateAnswer(userInput: cleanedInput, memories: retrieved)
    if let reply, !reply.isEmpty {
      return reply
    }
    return "我找到了 \(retrieved.count) 条相关记忆，你想让我逐条念给你吗？"
  }

  private func handleAmendIntent(plan: MemoryIntentPlan, cleanedInput: String, userId: String) async -> String {
    let targetQuery = plan.amendmentTargetQuery.isEmpty
      ? (plan.retrieveQuery.isEmpty ? cleanedInput : plan.retrieveQuery)
      : plan.amendmentTargetQuery
    let candidates = await retrieveMemory(userId: userId, query: targetQuery)

    guard !candidates.isEmpty else {
      return "我没找到可修改的历史记忆。你可以先说完整内容，我帮你重新记录。"
    }

    let amendmentText = plan.amendmentText.isEmpty ? plan.storeText : plan.amendmentText
    guard !amendmentText.isEmpty else {
      return plan.clarificationQuestion.isEmpty
        ? "你想补充或修改成什么内容？可以直接告诉我。"
        : plan.clarificationQuestion
    }

    if candidates.count > 1 || plan.requiresConfirmation {
      return """
      我找到了可能要修改的记忆：
      \(formatCandidates(candidates))
      请告诉我要修改第几条，我再帮你完成更新。
      """
    }

    guard let target = candidates.first else {
      return "我需要先确认你要修改哪条记忆。"
    }
    let revisedText = composeRevisedMemory(from: target.text, amendmentText: amendmentText)
    await persistMemory(text: revisedText, userId: userId)

    if !plan.directReply.isEmpty {
      return plan.directReply
    }
    return "明白，我已经按你的补充更新记录：\(revisedText)"
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

  private func composeRevisedMemory(from original: String, amendmentText: String) -> String {
    let originalValue = original.trimmingCharacters(in: .whitespacesAndNewlines)
    let amendmentValue = amendmentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !originalValue.isEmpty else { return amendmentValue }
    guard !amendmentValue.isEmpty else { return originalValue }
    return "修订：原记录「\(originalValue)」，补充「\(amendmentValue)」"
  }

  private func formatCandidates(_ memories: [MemoryRecord], limit: Int = 3) -> String {
    let rows = memories.prefix(limit)
    return rows.enumerated().map { index, item in
      "\(index + 1). \(item.text)"
    }.joined(separator: "\n")
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
  enum Intent: String, Codable {
    case store
    case retrieve
    case amend
    case clarify
    case chat
    case unknown
  }

  let intent: Intent
  let shouldStore: Bool
  let storeText: String
  let shouldRetrieve: Bool
  let retrieveQuery: String
  let amendmentText: String
  let amendmentTargetQuery: String
  let clarificationQuestion: String
  let requiresConfirmation: Bool
  let directReply: String

  private enum CodingKeys: String, CodingKey {
    case intent
    case shouldStore = "should_store"
    case storeText = "store_text"
    case shouldRetrieve = "should_retrieve"
    case retrieveQuery = "retrieve_query"
    case amendmentText = "amendment_text"
    case amendmentTargetQuery = "amendment_target_query"
    case clarificationQuestion = "clarification_question"
    case requiresConfirmation = "requires_confirmation"
    case directReply = "direct_reply"
  }

  var normalizedIntent: Intent {
    if intent != .unknown {
      return intent
    }
    if shouldStore && shouldRetrieve {
      return .amend
    }
    if shouldStore {
      return .store
    }
    if shouldRetrieve {
      return .retrieve
    }
    if !clarificationQuestion.isEmpty || requiresConfirmation {
      return .clarify
    }
    if !directReply.isEmpty {
      return .chat
    }
    return .unknown
  }

  static func parse(from raw: String) -> MemoryIntentPlan? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard let data = extractJSONBlock(from: trimmed)?.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(MemoryIntentPlan.self, from: data)
  }

  static func fallback(for input: String) -> MemoryIntentPlan {
    let normalized = input.lowercased()
    let store = ["记一下", "记住", "提醒", "待办", "备忘", "帮我记"].contains { normalized.contains($0) }
    let retrieve = ["查一下", "回忆", "之前记", "我记了什么", "搜索", "找找"].contains { normalized.contains($0) }
    let amend = ["修改", "改成", "更正", "补充", "不是", "改为"].contains { normalized.contains($0) }
    let clarify = ["什么意思", "你确定", "不对", "没听清"].contains { normalized.contains($0) }
    let fallbackIntent: Intent = amend ? .amend : (store ? .store : (retrieve ? .retrieve : (clarify ? .clarify : .unknown)))
    return MemoryIntentPlan(
      intent: fallbackIntent,
      shouldStore: store,
      storeText: store ? input : "",
      shouldRetrieve: retrieve,
      retrieveQuery: retrieve ? input : "",
      amendmentText: amend ? input : "",
      amendmentTargetQuery: amend ? input : "",
      clarificationQuestion: clarify ? "你可以再具体说一下，我会按你的新指令处理。" : "",
      requiresConfirmation: amend,
      directReply: store ? "好的，我先帮你记下来了。" : ""
    )
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    intent = try container.decodeIfPresent(Intent.self, forKey: .intent) ?? .unknown
    shouldStore = try container.decodeIfPresent(Bool.self, forKey: .shouldStore) ?? false
    storeText = try container.decodeIfPresent(String.self, forKey: .storeText) ?? ""
    shouldRetrieve = try container.decodeIfPresent(Bool.self, forKey: .shouldRetrieve) ?? false
    retrieveQuery = try container.decodeIfPresent(String.self, forKey: .retrieveQuery) ?? ""
    amendmentText = try container.decodeIfPresent(String.self, forKey: .amendmentText) ?? ""
    amendmentTargetQuery = try container.decodeIfPresent(String.self, forKey: .amendmentTargetQuery) ?? ""
    clarificationQuestion = try container.decodeIfPresent(String.self, forKey: .clarificationQuestion) ?? ""
    requiresConfirmation = try container.decodeIfPresent(Bool.self, forKey: .requiresConfirmation) ?? false
    directReply = try container.decodeIfPresent(String.self, forKey: .directReply) ?? ""
  }

  init(
    intent: Intent,
    shouldStore: Bool,
    storeText: String,
    shouldRetrieve: Bool,
    retrieveQuery: String,
    amendmentText: String,
    amendmentTargetQuery: String,
    clarificationQuestion: String,
    requiresConfirmation: Bool,
    directReply: String
  ) {
    self.intent = intent
    self.shouldStore = shouldStore
    self.storeText = storeText
    self.shouldRetrieve = shouldRetrieve
    self.retrieveQuery = retrieveQuery
    self.amendmentText = amendmentText
    self.amendmentTargetQuery = amendmentTargetQuery
    self.clarificationQuestion = clarificationQuestion
    self.requiresConfirmation = requiresConfirmation
    self.directReply = directReply
  }

  private static func extractJSONBlock(from text: String) -> String? {
    guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return nil }
    guard start <= end else { return nil }
    return String(text[start ... end])
  }
}
