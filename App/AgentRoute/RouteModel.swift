import Foundation

// DONE-AI: 路由契约模型已稳定，供引擎/执行层共享。

/// 单轮用户输入的路由上下文。
struct RouteContext {
  let userId: String
  let sessionId: String
  let rawText: String
  let normalizedText: String
  let createdAtMs: Int64
}

/// 路由与规划阶段产出的顶层动作类型。
enum RouteAction: String {
  case store
  case retrieve
  case amend
  case clarify
  case chat
  case unknown
}

/// 仅在存在待处理会话状态时使用的跟进意图。
enum FollowIntent: String {
  case cancel
  case confirm
  case reject
  case other
}

/// 从意图层传给执行层的决策对象。
struct RouteDecision {
  let action: RouteAction
  let confidence: Double
  let reason: String
  let slots: [String: String]
  let needConfirm: Bool

  /// 由已解析的意图计划构建路由决策。
  static func from(plan: IntentPlan, reason: String) -> RouteDecision {
    RouteDecision(
      action: RouteAction(plan.normalizedIntent),
      confidence: 0.78,
      reason: reason,
      slots: [
        "store_text": plan.saveText,
        "retrieve_query": plan.findQuery,
        "amendment_text": plan.editText,
        "amendment_target_query": plan.editQuery,
        "clarification_question": plan.askText,
        "direct_reply": plan.replyText,
      ],
      needConfirm: plan.needConfirm
    )
  }
}

/// 执行完成后返回给调用方的统一结果结构。
struct RouteResult {
  let action: RouteAction
  let message: String
  let needsFollowUp: Bool
  let followState: String?
  let traceId: String
}

/// 一次完整路由链路中的单个埋点步骤。
struct RouteStep {
  let name: String
  let ms: Int
  let detail: String
}

/// 用于观测与排障的完整路由追踪信息。
struct RouteTrace {
  let traceId: String
  let userId: String
  var stages: [RouteStep] = []
  var finalAction: RouteAction = .unknown
  var message: String = ""
  var totalMs: Int = 0
}

private extension RouteAction {
  /// 将意图计划枚举映射为路由动作枚举。
  init(_ intent: IntentPlan.Intent) {
    switch intent {
    case .store: self = .store
    case .retrieve: self = .retrieve
    case .amend: self = .amend
    case .clarify: self = .clarify
    case .chat: self = .chat
    case .unknown: self = .unknown
    }
  }
}
