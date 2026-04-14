import Foundation

/// 语音入口主流水线：将意图路由与执行委托给 RouteEngine。
final class VoiceMemoryPipeline {
  static let shared = VoiceMemoryPipeline()

  private let embeddingAPI: DoubaoEmbeddingAPI
  private let chatAPI: DoubaoChatAPI
  private let memoryAPI: MemoryAPI
  private let routeEngine: RouteEngine

  /// 构造流水线，并注入可替换的 API 与路由依赖。
  init(
    embeddingAPI: DoubaoEmbeddingAPI = .shared,
    chatAPI: DoubaoChatAPI = .shared,
    memoryAPI: MemoryAPI = .shared,
    routeEngine: RouteEngine = RouteEngine()
  ) {
    self.embeddingAPI = embeddingAPI
    self.chatAPI = chatAPI
    self.memoryAPI = memoryAPI
    self.routeEngine = routeEngine
  }

  /// 处理一轮用户文本输入，返回最终回复内容。
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

    let routeContext = RouteContext(
      userId: userId,
      sessionId: userId,
      rawText: cleaned,
      normalizedText: cleaned,
      createdAtMs: Int64(Date().timeIntervalSince1970 * 1000)
    )

    let result = await routeEngine.run(context: routeContext, runtime: self)
    return result.message
  }
}

extension VoiceMemoryPipeline: RouteRuntime {
  /// 调用对话模型生成结构化意图计划 JSON。
  func planIntent(text: String, acts: [RouteAction]) async -> IntentPlan {
    let candidatesText = acts.map(\.rawValue).joined(separator: ",")

    let system = """
    你是车载语音助手的意图路由器。
    你只允许在候选意图集合里做判断。
    只输出 JSON，不要输出其他文本。

    候选意图集合：\(candidatesText)

    字段：
    - intent: string，必须属于候选意图集合；若都不符合则输出 clarify
    - should_store: bool
    - store_text: string
    - should_retrieve: bool
    - retrieve_query: string
    - amendment_text: string
    - amendment_target_query: string
    - clarification_question: string
    - requires_confirmation: bool
    - direct_reply: string

    要求：
    1) store_text/retrieve_query 要是提炼后的短语。
    2) 不确定时 intent=clarify，并给 clarification_question。
    3) direct_reply 只写给用户看的自然口语，不超过30字。
    """
    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0.1) else {
      return IntentPlan.fallback(for: text)
    }
    return IntentPlan.parse(from: content) ?? IntentPlan.fallback(for: text)
  }

  /// 计算文本 embedding，用于路由初筛与检索。
  func embedText(_ text: String) async -> [Double]? {
    await embeddingAPI.embed(text: text)
  }

  /// 将跟进回复分类为 cancel/confirm/reject/other。
  func classifyFollow(_ text: String) async -> FollowIntent {
    let system = """
    你是后续对话分类器。
    只输出 JSON：{"intent":"cancel|confirm|reject|other"}
    定义：
    - cancel：取消/算了/不改了
    - confirm：是的/好的/继续/要
    - reject：不要/不用/否定补充
    - other：其余内容
    """

    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0) else {
      return .other
    }

    let intent = extractIntentField(from: content)
    return FollowIntent(rawValue: intent) ?? .other
  }

  /// 从跟进输入中提取候选序号。
  func pickIndex(_ text: String, max: Int) async -> Int? {
    guard max > 0 else { return nil }

    let system = """
    你是候选项选择解析器。
    任务：从用户输入中判断他想选择第几条候选。
    只输出 JSON：{"selected_index":0}
    规则：
    - selected_index 使用 1-based（第一条=1）
    - 若用户没有明确选择，输出 0
    - 值不能超过 \(max)
    """

    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0) else {
      return nil
    }

    guard let selected = extractIntField(from: content, key: "selected_index") else {
      return nil
    }
    guard selected >= 1, selected <= max else { return nil }
    return selected - 1
  }

  /// 从跟进输入中抽取“修改内容”文本。
  func extractEditText(_ text: String) async -> String {
    let system = """
    你是信息抽取器。
    从用户句子里抽取“新的修改内容”。
    只输出 JSON：{"amendment_text":"..."}
    如果没提到明确修改内容，返回空字符串。
    """

    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: text, temperature: 0) else {
      return ""
    }

    return extractTextField(from: content, key: "amendment_text")
  }

  /// 为每个动作生成种子短句，用于 embedding 初筛索引初始化。
  func seedTexts() async -> [RouteAction: [String]] {
    let system = """
    你是语义路由样本生成器。
    生成用于 embedding 路由的中文短句样本。
    只输出 JSON，格式：
    {
      "store": ["..."],
      "retrieve": ["..."],
      "amend": ["..."],
      "clarify": ["..."],
      "chat": ["..."]
    }
    每个数组给4条简短样本。
    """

    guard let content = await chatAPI.chat(systemPrompt: system, userPrompt: "生成路由样本", temperature: 0.2) else {
      return [:]
    }

    guard let data = extractJSONBlock(from: content)?.data(using: .utf8),
          let map = try? JSONDecoder().decode([String: [String]].self, from: data)
    else {
      return [:]
    }

    var result: [RouteAction: [String]] = [:]
    for (key, values) in map {
      guard let action = RouteAction(rawValue: key) else { continue }
      let cleaned = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
      if !cleaned.isEmpty {
        result[action] = cleaned
      }
    }
    return result
  }

  /// 保存记忆到本地向量库，并触发后端入库。
  func saveMemory(text: String, userId: String) async {
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

  /// 基于向量相似度检索相关记忆。
  func findMemory(userId: String, query: String) async -> [MemoryRecord] {
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

  /// 根据检索记忆与当前输入生成回复。
  func makeAnswer(userInput: String, memories: [MemoryRecord]) async -> String? {
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

  /// 组合修订后的记忆文本。
  func makeRevised(from original: String, editText: String) -> String {
    let originalValue = original.trimmingCharacters(in: .whitespacesAndNewlines)
    let amendmentValue = editText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !originalValue.isEmpty else { return amendmentValue }
    guard !amendmentValue.isEmpty else { return originalValue }
    return "修订：原记录「\(originalValue)」，补充「\(amendmentValue)」"
  }

  /// 组合补充后的记忆文本。
  func makeSupplement(from original: String, addTxt: String) -> String {
    let originalValue = original.trimmingCharacters(in: .whitespacesAndNewlines)
    let supplementValue = addTxt.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !supplementValue.isEmpty else { return originalValue }
    return "补充：原记录「\(originalValue)」，新增「\(supplementValue)」"
  }

  /// 将候选记忆格式化为可读列表，供用户选择。
  func formatList(_ memories: [MemoryRecord], limit: Int) -> String {
    let rows = memories.prefix(limit)
    return rows.enumerated().map { index, item in
      "\(index + 1). \(item.text)"
    }.joined(separator: "\n")
  }

  /// 从模型 JSON 输出中提取 `intent` 字段。
  private func extractIntentField(from raw: String) -> String {
    extractTextField(from: raw, key: "intent")
  }

  /// 从模型 JSON 输出中提取任意字符串字段。
  private func extractTextField(from raw: String, key: String) -> String {
    guard let data = extractJSONBlock(from: raw)?.data(using: .utf8),
          let map = try? JSONDecoder().decode([String: String].self, from: data)
    else {
      return ""
    }
    return map[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
  }

  /// 从模型 JSON 输出中提取任意整数字段。
  private func extractIntField(from raw: String, key: String) -> Int? {
    guard let data = extractJSONBlock(from: raw)?.data(using: .utf8),
          let map = try? JSONDecoder().decode([String: Int].self, from: data)
    else {
      return nil
    }
    return map[key]
  }

  /// 从混合文本输出中提取最外层 JSON 对象。
  private func extractJSONBlock(from text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let start = trimmed.firstIndex(of: "{"), let end = trimmed.lastIndex(of: "}") else { return nil }
    guard start <= end else { return nil }
    return String(trimmed[start ... end])
  }
}
