import Foundation

// DONE-AI: LLM 路由输出结构已统一，并带有兼容旧字段解析。

/// 从 LLM JSON 响应解析得到的意图计划结构。
struct IntentPlan: Codable, Equatable {
  /// 规划器返回的意图类别。
  enum Intent: String, Codable {
    case store
    case retrieve
    case amend
    case clarify
    case chat
    case unknown
  }

  let intent: Intent
  let shouldSave: Bool
  let saveText: String
  let shouldFind: Bool
  let findQuery: String
  let editText: String
  let editQuery: String
  let askText: String
  let needConfirm: Bool
  let replyText: String

  private enum CodingKeys: String, CodingKey {
    case intent
    case shouldSave = "should_store"
    case saveText = "store_text"
    case shouldFind = "should_retrieve"
    case findQuery = "retrieve_query"
    case editText = "amendment_text"
    case editQuery = "amendment_target_query"
    case askText = "clarification_question"
    case needConfirm = "requires_confirmation"
    case replyText = "direct_reply"
  }

  /// 当 `intent` 为 unknown 时，使用兼容字段推导标准意图。
  var normalizedIntent: Intent {
    if intent != .unknown {
      return intent
    }
    if shouldSave && shouldFind {
      return .amend
    }
    if shouldSave {
      return .store
    }
    if shouldFind {
      return .retrieve
    }
    if !askText.isEmpty || needConfirm {
      return .clarify
    }
    if !replyText.isEmpty {
      return .chat
    }
    return .unknown
  }

  /// 从模型原始输出解析意图计划（允许 JSON 外层混有文本）。
  static func parse(from raw: String) -> IntentPlan? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    guard let data = extractJSONBlock(from: trimmed)?.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(IntentPlan.self, from: data)
  }

  /// 当模型输出缺失或无效时的安全兜底计划。
  static func fallback(for _: String) -> IntentPlan {
    IntentPlan(
      intent: .clarify,
      shouldSave: false,
      saveText: "",
      shouldFind: false,
      findQuery: "",
      editText: "",
      editQuery: "",
      askText: "我需要再确认你的意图。你是要记录、检索，还是修改记忆？",
      needConfirm: true,
      replyText: ""
    )
  }

  /// 自定义解码：字段缺失时使用防御性默认值。
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    intent = try container.decodeIfPresent(Intent.self, forKey: .intent) ?? .unknown
    shouldSave = try container.decodeIfPresent(Bool.self, forKey: .shouldSave) ?? false
    saveText = try container.decodeIfPresent(String.self, forKey: .saveText) ?? ""
    shouldFind = try container.decodeIfPresent(Bool.self, forKey: .shouldFind) ?? false
    findQuery = try container.decodeIfPresent(String.self, forKey: .findQuery) ?? ""
    editText = try container.decodeIfPresent(String.self, forKey: .editText) ?? ""
    editQuery = try container.decodeIfPresent(String.self, forKey: .editQuery) ?? ""
    askText = try container.decodeIfPresent(String.self, forKey: .askText) ?? ""
    needConfirm = try container.decodeIfPresent(Bool.self, forKey: .needConfirm) ?? false
    replyText = try container.decodeIfPresent(String.self, forKey: .replyText) ?? ""
  }

  /// 指定构造器，供解析、兜底与测试复用。
  init(
    intent: Intent,
    shouldSave: Bool,
    saveText: String,
    shouldFind: Bool,
    findQuery: String,
    editText: String,
    editQuery: String,
    askText: String,
    needConfirm: Bool,
    replyText: String
  ) {
    self.intent = intent
    self.shouldSave = shouldSave
    self.saveText = saveText
    self.shouldFind = shouldFind
    self.findQuery = findQuery
    self.editText = editText
    self.editQuery = editQuery
    self.askText = askText
    self.needConfirm = needConfirm
    self.replyText = replyText
  }

  /// 从混合文本中提取最外层 JSON 对象。
  private static func extractJSONBlock(from text: String) -> String? {
    guard let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") else { return nil }
    guard start <= end else { return nil }
    return String(text[start ... end])
  }
}
