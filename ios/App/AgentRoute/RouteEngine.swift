import Foundation

/// 路由引擎依赖的运行时协议，负责 AI 调用与数据读写。
protocol RouteRuntime: AnyObject {
  /// 让模型根据用户输入生成结构化意图计划。
  func planIntent(text: String, acts: [RouteAction]) async -> IntentPlan
  /// 计算文本 embedding，用于动作初筛。
  func embedText(_ text: String) async -> [Double]?
  /// 当存在待处理会话状态时，分类用户跟进回复意图。
  func classifyFollow(_ text: String) async -> FollowIntent
  /// 从跟进输入中提取候选序号（1..N）。
  func pickIndex(_ text: String, max: Int) async -> Int?
  /// 从跟进输入中提取修改或补充文本。
  func extractEditText(_ text: String) async -> String
  /// 提供各动作的种子文本，用于 embedding 索引初始化。
  func seedTexts() async -> [RouteAction: [String]]
  /// 保存一条记忆文本。
  func saveMemory(text: String, userId: String) async
  /// 按查询语义检索相关记忆。
  func findMemory(userId: String, query: String) async -> [MemoryRecord]
  /// 结合用户输入和检索结果生成最终回复。
  func makeAnswer(userInput: String, memories: [MemoryRecord]) async -> String?
  /// 根据原文本和修改文本生成修订内容。
  func makeRevised(from original: String, editText: String) -> String
  /// 根据原文本和补充文本生成补充内容。
  func makeSupplement(from original: String, addTxt: String) -> String
  /// 将候选记忆格式化为可读列表。
  func formatList(_ memories: [MemoryRecord], limit: Int) -> String
}

/// 主路由引擎：标准化 -> 待处理状态 -> embedding 初筛 -> 意图规划 -> 守卫 -> 执行。
final class RouteEngine {
  private let sessionStore: SessionStore
  private let logSink: RouteLogSink
  private let embedIndex: IntentEmbedIndex

  /// 构造引擎，并注入可替换的会话/日志/向量索引依赖。
  init(
    sessionStore: SessionStore = .shared,
    logSink: RouteLogSink = DefaultRouteLogSink(),
    embedIndex: IntentEmbedIndex = .shared
  ) {
    self.sessionStore = sessionStore
    self.logSink = logSink
    self.embedIndex = embedIndex
  }

  /// 执行一轮完整路由，并返回用户可直接看到的结果。
  func run(context: RouteContext, runtime: RouteRuntime) async -> RouteResult {
    let traceId = UUID().uuidString
    let startAt = CFAbsoluteTimeGetCurrent()
    var trace = RouteTrace(traceId: traceId, userId: context.userId)

    // 本轮统一使用标准化文本，避免后续阶段理解不一致。
    let normalized = normalizeText(context.rawText)
    trace.stages.append(.init(name: "normalize", ms: elapsedMs(since: startAt), detail: normalized))

    guard !normalized.isEmpty else {
      let result = RouteResult(action: .clarify, message: "我没有听清楚，请再说一次。", needsFollowUp: false, followState: nil, traceId: traceId)
      trace.finalAction = .clarify
      trace.message = result.message
      logSink.record(trace: trace)
      return result
    }

    if let pending = await runPending(input: normalized, userId: context.userId, traceId: traceId, runtime: runtime) {
      trace.stages.append(.init(name: "pending", ms: elapsedMs(since: startAt), detail: String(describing: pending.action)))
      trace.finalAction = pending.action
      trace.message = pending.message
      trace.totalMs = elapsedMs(since: startAt)
      logSink.record(trace: trace)
      return pending
    }

    let prefAt = CFAbsoluteTimeGetCurrent()
    let candidates = await embedIndex.pickActions(text: normalized, runtime: runtime, topK: 3)
    trace.stages.append(.init(name: "embedding_prefilter", ms: elapsedMs(since: prefAt), detail: candidates.map(\.rawValue).joined(separator: ",")))

    let intentAt = CFAbsoluteTimeGetCurrent()
    let decision = await pickIntent(input: normalized, candidates: candidates, runtime: runtime)
    trace.stages.append(.init(name: "intent_router", ms: elapsedMs(since: intentAt), detail: "\(decision.action.rawValue):\(decision.reason)"))

    let guarded = guardDecision(decision: decision, norm: normalized)
    trace.stages.append(.init(name: "policy_guard", ms: elapsedMs(since: startAt), detail: "\(guarded.action.rawValue)"))

    let execAt = CFAbsoluteTimeGetCurrent()
    let result = await execute(decision: guarded, norm: normalized, userId: context.userId, traceId: traceId, runtime: runtime)
    trace.stages.append(.init(name: "executor", ms: elapsedMs(since: execAt), detail: result.followState ?? "none"))

    trace.finalAction = result.action
    trace.message = result.message
    trace.totalMs = elapsedMs(since: startAt)
    logSink.record(trace: trace)
    return result
  }

  /// 在路由前标准化用户原始文本。
  private func normalizeText(_ text: String) -> String {
    text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "  ", with: " ")
  }

  /// 结合候选动作约束，从模型计划中生成路由决策。
  private func pickIntent(
    input: String,
    candidates: [RouteAction],
    runtime: RouteRuntime
  ) async -> RouteDecision {
    // 意图判断由 AI 完成，并受 embedding 候选集约束。
    let plan = await runtime.planIntent(text: input, acts: candidates)
    var decision = RouteDecision.from(plan: plan, reason: "llm_embedding_prefilter")

    if decision.action == .unknown {
      decision = RouteDecision(
        action: .clarify,
        confidence: 0.5,
        reason: "llm_unknown",
        slots: ["clarification_question": "我还不太确定你的意图。你是要记录、检索还是修改记忆？"],
        needConfirm: true
      )
      return decision
    }

    if !candidates.contains(decision.action), decision.action != .clarify {
      return RouteDecision(
        action: .clarify,
        confidence: decision.confidence,
        reason: "candidate_guard",
        slots: ["clarification_question": "我理解了一个方向，但还需要你再确认一下是记录、检索还是修改。"],
        needConfirm: true
      )
    }

    return decision
  }

  /// 执行前做安全与策略守卫，兜底异常决策。
  private func guardDecision(decision: RouteDecision, norm: String) -> RouteDecision {
    // 守卫只处理安全与歧义，不做关键词规则路由。
    if decision.action == .unknown || norm.count <= 1 {
      return RouteDecision(
        action: .clarify,
        confidence: 1,
        reason: "policy_short_or_unknown",
        slots: ["clarification_question": "你可以再说完整一点，比如“帮我记一下…”或“帮我查一下…”。"],
        needConfirm: true
      )
    }
    return decision
  }

  /// 按决策动作执行具体分支，并输出统一结果结构。
  private func execute(
    decision: RouteDecision,
    norm: String,
    userId: String,
    traceId: String,
    runtime: RouteRuntime
  ) async -> RouteResult {
    switch decision.action {
    case .clarify:
      let question = decision.slots["clarification_question"]?.trimmingCharacters(in: .whitespacesAndNewlines)
      let response = (question?.isEmpty == false)
        ? question!
        : "我想先确认一下你的意思：你是要记录新内容，还是想查找之前的记忆？"
      await sessionStore.set(.waitAsk(originInput: norm, question: response), for: userId)
      return buildResult(action: .clarify, message: response, followUp: true, followState: "awaiting_clarification", traceId: traceId)

    case .store:
      return await runStore(decision: decision, clean: norm, userId: userId, traceId: traceId, runtime: runtime)

    case .retrieve:
      return await runRetrieve(decision: decision, clean: norm, userId: userId, traceId: traceId, runtime: runtime)

    case .amend:
      return await runAmend(decision: decision, clean: norm, userId: userId, traceId: traceId, runtime: runtime)

    case .chat, .unknown:
      await sessionStore.clear(for: userId)
      let replyText = decision.slots["direct_reply"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if !replyText.isEmpty {
        return buildResult(action: .chat, message: replyText, followUp: false, followState: nil, traceId: traceId)
      }
      return buildResult(action: .unknown, message: norm, followUp: false, followState: nil, traceId: traceId)
    }
  }

  /// 执行“记录记忆”分支。
  private func runStore(
    decision: RouteDecision,
    clean: String,
    userId: String,
    traceId: String,
    runtime: RouteRuntime
  ) async -> RouteResult {
    let textToStore = decision.slots["store_text"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let valueToStore = (textToStore?.isEmpty == false) ? textToStore! : clean
    await runtime.saveMemory(text: valueToStore, userId: userId)

    if decision.needConfirm {
      let question = decision.slots["clarification_question"]?.trimmingCharacters(in: .whitespacesAndNewlines)
      let prompt = (question?.isEmpty == false) ? question! : "我先记录了这条信息。你要不要我再补上时间或地点？"
      await sessionStore.set(.waitAdd(baseText: valueToStore), for: userId)
      return buildResult(action: .store, message: prompt, followUp: true, followState: "awaiting_store_supplement", traceId: traceId)
    }

    await sessionStore.clear(for: userId)
    let replyText = decision.slots["direct_reply"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !replyText.isEmpty {
      return buildResult(action: .store, message: replyText, followUp: false, followState: nil, traceId: traceId)
    }
    return buildResult(action: .store, message: "好的，我已经帮你记下来了。", followUp: false, followState: nil, traceId: traceId)
  }

  /// 执行“检索记忆”分支。
  private func runRetrieve(
    decision: RouteDecision,
    clean: String,
    userId: String,
    traceId: String,
    runtime: RouteRuntime
  ) async -> RouteResult {
    let query = decision.slots["retrieve_query"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let findQuery = (query?.isEmpty == false) ? query! : clean
    let retrieved = await runtime.findMemory(userId: userId, query: findQuery)

    if retrieved.isEmpty {
      await sessionStore.clear(for: userId)
      return buildResult(action: .retrieve, message: "我暂时没有找到相关记忆。你可以先说“帮我记一下...”，我会立刻保存。", followUp: false, followState: nil, traceId: traceId)
    }

    if decision.needConfirm {
      let question = "我找到了这些可能相关的记忆：\n\(runtime.formatList(retrieved, limit: 3))\n你想先听第几条，还是继续缩小范围？"
      await sessionStore.set(.waitAsk(originInput: clean, question: question), for: userId)
      return buildResult(action: .retrieve, message: question, followUp: true, followState: "awaiting_clarification", traceId: traceId)
    }

    await sessionStore.clear(for: userId)
    let reply = await runtime.makeAnswer(userInput: clean, memories: retrieved)
    if let reply, !reply.isEmpty {
      return buildResult(action: .retrieve, message: reply, followUp: false, followState: nil, traceId: traceId)
    }
    return buildResult(action: .retrieve, message: "我找到了 \(retrieved.count) 条相关记忆，你想让我逐条念给你吗？", followUp: false, followState: nil, traceId: traceId)
  }

  /// 执行“修改记忆”分支。
  private func runAmend(
    decision: RouteDecision,
    clean: String,
    userId: String,
    traceId: String,
    runtime: RouteRuntime
  ) async -> RouteResult {
    let editQuery = decision.slots["amendment_target_query"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let findQuery = decision.slots["retrieve_query"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let findKey = (editQuery?.isEmpty == false)
      ? editQuery!
      : ((findQuery?.isEmpty == false) ? findQuery! : clean)

    let candidates = await runtime.findMemory(userId: userId, query: findKey)
    guard !candidates.isEmpty else {
      await sessionStore.clear(for: userId)
      return buildResult(action: .amend, message: "我没找到可修改的历史记忆。你可以先说完整内容，我帮你重新记录。", followUp: false, followState: nil, traceId: traceId)
    }

    let editOne = decision.slots["amendment_text"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let saveBak = decision.slots["store_text"]?.trimmingCharacters(in: .whitespacesAndNewlines)
    let editText = (editOne?.isEmpty == false) ? editOne! : (saveBak ?? "")

    if editText.isEmpty {
      await sessionStore.set(.waitPick(candidates: candidates, editText: ""), for: userId)
      return buildResult(action: .amend, message: "我找到了可能要修改的记忆：\n\(runtime.formatList(candidates, limit: 3))\n请先告诉我修改第几条。", followUp: true, followState: "awaiting_amend_target", traceId: traceId)
    }

    if candidates.count > 1 || decision.needConfirm {
      await sessionStore.set(.waitPick(candidates: candidates, editText: editText), for: userId)
      return buildResult(action: .amend, message: "我找到了可能要修改的记忆：\n\(runtime.formatList(candidates, limit: 3))\n请告诉我要修改第几条，我再帮你完成更新。", followUp: true, followState: "awaiting_amend_target", traceId: traceId)
    }

    guard let target = candidates.first else {
      await sessionStore.clear(for: userId)
      return buildResult(action: .amend, message: "我需要先确认你要修改哪条记忆。", followUp: false, followState: nil, traceId: traceId)
    }

    let newTxt = runtime.makeRevised(from: target.text, editText: editText)
    await runtime.saveMemory(text: newTxt, userId: userId)
    await sessionStore.clear(for: userId)

    let replyText = decision.slots["direct_reply"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !replyText.isEmpty {
      return buildResult(action: .amend, message: replyText, followUp: false, followState: nil, traceId: traceId)
    }
    return buildResult(action: .amend, message: "明白，我已经按你的补充更新记录：\(newTxt)", followUp: false, followState: nil, traceId: traceId)
  }

  /// 在常规路由前，优先处理多轮会话的待处理状态。
  private func runPending(
    input: String,
    userId: String,
    traceId: String,
    runtime: RouteRuntime
  ) async -> RouteResult? {
    guard let pending = await sessionStore.get(for: userId) else {
      return nil
    }

    let next = await runtime.classifyFollow(input)

    switch pending {
    case let .waitAsk(originInput, _):
      if next == .cancel {
        await sessionStore.clear(for: userId)
        return buildResult(action: .clarify, message: "好的，这次先取消。你随时可以重新告诉我。", followUp: false, followState: nil, traceId: traceId)
      }
      await sessionStore.clear(for: userId)
      let mix = TextClean.joinAsk(originInput: originInput, supplementInput: input)
      let candidates = await embedIndex.pickActions(text: mix, runtime: runtime, topK: 3)
      let decision = await pickIntent(input: mix, candidates: candidates, runtime: runtime)
      return await execute(decision: decision, norm: mix, userId: userId, traceId: traceId, runtime: runtime)

    case let .waitAdd(baseText):
      if next == .cancel || next == .reject {
        await sessionStore.clear(for: userId)
        return buildResult(action: .store, message: "好的，先保留原记录。", followUp: false, followState: nil, traceId: traceId)
      }

      if next == .confirm {
        return buildResult(action: .store, message: "好的，请告诉我你要补充的具体内容。", followUp: true, followState: "awaiting_store_supplement", traceId: traceId)
      }

      let newTxt = runtime.makeSupplement(from: baseText, addTxt: input)
      await runtime.saveMemory(text: newTxt, userId: userId)
      await sessionStore.clear(for: userId)
      return buildResult(action: .store, message: "收到，我已经把补充信息也记录好了。", followUp: false, followState: nil, traceId: traceId)

    case let .waitPick(candidates, editText):
      if next == .cancel {
        await sessionStore.clear(for: userId)
        return buildResult(action: .amend, message: "好的，已取消这次修改。", followUp: false, followState: nil, traceId: traceId)
      }

      if let index = await runtime.pickIndex(input, max: candidates.count),
         candidates.indices.contains(index)
      {
        let target = candidates[index]
        let inEdit = await runtime.extractEditText(input)
        let useEdit = inEdit.isEmpty ? editText : inEdit

        if useEdit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          await sessionStore.set(.waitEdit(target: target), for: userId)
          return buildResult(action: .amend, message: "你希望把这条改成什么内容？", followUp: true, followState: "awaiting_amend_content", traceId: traceId)
        }

        let newTxt = runtime.makeRevised(from: target.text, editText: useEdit)
        await runtime.saveMemory(text: newTxt, userId: userId)
        await sessionStore.clear(for: userId)
        return buildResult(action: .amend, message: "好的，我已经完成修改：\(newTxt)", followUp: false, followState: nil, traceId: traceId)
      }

      let refreshed = await runtime.findMemory(userId: userId, query: input)
      if !refreshed.isEmpty {
        await sessionStore.set(.waitPick(candidates: refreshed, editText: editText), for: userId)
        return buildResult(action: .amend, message: "我又找到了这些候选记录：\n\(runtime.formatList(refreshed, limit: 3))\n请说“第几条”。", followUp: true, followState: "awaiting_amend_target", traceId: traceId)
      }
      return buildResult(action: .amend, message: "我还没识别出你要改哪一条。你可以直接说“第1条”或“第2条”。", followUp: true, followState: "awaiting_amend_target", traceId: traceId)

    case let .waitEdit(target):
      if next == .cancel {
        await sessionStore.clear(for: userId)
        return buildResult(action: .amend, message: "好的，已取消这次修改。", followUp: false, followState: nil, traceId: traceId)
      }

      let newTxt = runtime.makeRevised(from: target.text, editText: input)
      await runtime.saveMemory(text: newTxt, userId: userId)
      await sessionStore.clear(for: userId)
      return buildResult(action: .amend, message: "明白，我已经按你的最新描述更新完成。", followUp: false, followState: nil, traceId: traceId)
    }
  }

  /// 组装统一的路由结果对象。
  private func buildResult(
    action: RouteAction,
    message: String,
    followUp: Bool,
    followState: String?,
    traceId: String
  ) -> RouteResult {
    RouteResult(
      action: action,
      message: message,
      needsFollowUp: followUp,
      followState: followState,
      traceId: traceId
    )
  }

  /// 将耗时从秒转换为毫秒整数。
  private func elapsedMs(since start: CFAbsoluteTime) -> Int {
    Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
  }
}
