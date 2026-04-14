# 语音 Agent Route 生产级方案（先规划后开发）

## 0. 目标
构建可上线的语音 AI 核心路由，不是“只有大模型回复”，而是**可控的 Agent Route 执行系统**：
1. 用户语音输入 -> 稳定识别文本。
2. 路由层判定用户目标（记录/检索/修改/澄清/其他）。
3. 执行层调用对应能力（向量检索、落库、追问确认）。
4. 返回可解释、可追踪、可回放的结果。

---

## 1. 生产原则（必须满足）
1. 路由由 AI 驱动：采用“Embedding 初筛 + LLM 结构化决策”，不走关键词意图匹配。
2. 每一步可观测：必须打点 route、latency、error、fallback。
3. 每一步可回放：保留 route trace（不含敏感音频原文）。
4. 每一步可降级：任一外部依赖失败都有降级回复。
5. 结果可解释：返回给前端的 response 附带 action 和 reason。

---

## 2. Agent Route 总体架构

## 2.1 路由图
1. `InputStage`
2. `NormalizeStage`
3. `IntentRouterStage`
4. `PolicyGuardStage`
5. `ExecutorStage`
6. `ResponseStage`
7. `TelemetryStage`

## 2.2 Route 节点职责
1. `InputStage`
   - 输入：ASR 文本
   - 输出：`RouteContext(rawText, userId, sessionId, timestamp)`
2. `NormalizeStage`
   - 文本清洗、口语词归一、空输入拦截
3. `IntentRouterStage`
   - 双阶段：
     - Embedding 路由初筛（候选动作 shortlist）
     - LLM 路由器（结构化 JSON 决策）
   - 合并决策：LLM 仅在 shortlist 内决策，越界则进入 clarify
4. `PolicyGuardStage`
   - 业务策略检查：是否需要确认、是否信息不足、是否越权
5. `ExecutorStage`
   - `StoreExecutor`
   - `RetrieveExecutor`
   - `AmendExecutor`
   - `ClarifyExecutor`
   - `ChatExecutor`
6. `ResponseStage`
   - 统一响应结构：`action + message + followUpNeeded + traceId`
7. `TelemetryStage`
   - 指标上报 + route trace 日志

---

## 3. 关键数据契约（强约束）

## 3.1 路由输入
```swift
struct RouteContext {
  let userId: String
  let sessionId: String
  let rawText: String
  let normalizedText: String
  let createdAtMs: Int64
}
```

## 3.2 路由决策
```swift
enum AgentAction {
  case store
  case retrieve
  case amend
  case clarify
  case chat
  case unknown
}

struct RouteDecision {
  let action: AgentAction
  let confidence: Double
  let reason: String
  let slots: [String: String]
  let requireConfirmation: Bool
}
```

## 3.3 执行结果
```swift
struct AgentRouteResult {
  let action: AgentAction
  let userMessage: String
  let followUpNeeded: Bool
  let followUpState: String?
  let traceId: String
}
```

---

## 4. 会话状态机（确认/修改/补充）

## 4.1 状态定义
1. `idle`
2. `awaiting_clarification`
3. `awaiting_amend_target`
4. `awaiting_amend_content`
5. `awaiting_store_supplement`

## 4.2 状态转换
1. `idle -> awaiting_clarification`
   - 条件：信息缺失
2. `idle -> awaiting_amend_target`
   - 条件：识别到修改意图但候选>1
3. `awaiting_amend_target -> awaiting_amend_content`
   - 条件：用户仅给了“第N条”
4. `awaiting_amend_target -> idle`
   - 条件：用户给出“第N条+新内容”，可直接执行
5. `awaiting_store_supplement -> idle`
   - 条件：收到补充或取消

---

## 5. “Agent Route”不是“单次 LLM 回复”

必须拆成三层：
1. **Intent Layer**：判定做什么。
2. **Planning Layer**：决定先确认还是直接执行。
3. **Execution Layer**：真正落库/检索/修订。

LLM 只在 Intent/Planning 层提供建议，执行层由代码保证一致性。

---

## 6. 错误与降级策略（生产必须）
1. ASR 空文本 -> `我没听清，请再说一次`。
2. LLM 路由失败 -> 回退 clarify（继续追问，不做规则猜测）。
3. 向量检索失败 -> `检索暂时不可用` + 引导重试。
4. 向量写入失败 -> 本地失败日志 + 友好提示。
5. 后端 ingest 失败 -> 本地保留 + 标记待同步。

---

## 7. 可观测性指标（上线前必须接好）
1. `route_total{action}`
2. `route_fallback_total{from,to}`
3. `executor_error_total{action,errorType}`
4. `route_latency_ms{stage}`
5. `clarify_loop_count`

日志必须包含：`traceId/userId/action/confidence/fallback/latency`。

---

## 8. 开发分期（严格按期）

## Phase 1（路由内核）
1. 抽象 `AgentRouteEngine`（独立于 UI）。
2. 接入 `RouteContext -> RouteDecision -> AgentRouteResult`。
3. 保留旧流程开关（feature flag）。

## Phase 2（执行器）
1. 拆分五类 Executor。
2. 实现统一错误码与降级。
3. 加入 session 状态机。

## Phase 3（可观测与灰度）
1. 加 route trace 日志。
2. 指标埋点。
3. 1% 灰度 -> 10% -> 全量。

## Phase 4（质量）
1. 单元测试：路由与状态机。
2. 集成测试：存储/检索/修订链路。
3. 真机回归：IoT 场景语音压测。

---

## 9. 测试矩阵（必须覆盖）
1. 记录：明确/不明确/补充后记录。
2. 检索：命中/空结果/多候选。
3. 修改：单候选直改/多候选编号选择/取消修改。
4. 澄清：多轮追问后成功执行。
5. 异常：LLM失败/Embedding失败/DB失败/网络失败。

---

## 10. 本次之后的执行方式
1. 先实现 `AgentRouteEngine` 与契约结构。
2. 再把现有 `VoiceMemoryPipeline` 迁移到新引擎适配层。
3. 最后替换入口并保留回滚开关。

这份文档就是后续开发的唯一执行依据；不再“边写边猜”。
