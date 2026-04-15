# AgentRoute (Server Runtime)

`AgentRoute` 是云端会话路由与推进层，负责：

- 多轮任务阶段推进（phase）
- route 决策与切换
- slot 增量收集与缺失检测
- confirmation 请求与确认判定
- 可执行条件 gating
- 执行编排调用与失败回退
- 输出可直接驱动移动端 UI 的结构化响应

## Client / Server 分工

客户端（App）
- 展示消息、追问、候选、确认框、执行状态
- 上送 `messageId/turnId/clientSessionVersion/clientContext`
- 仅维护轻量 UI state

服务端（AgentRoute）
- 持久化 `SessionState`
- route + phase + slot + confirmation 决策
- 幂等、防重、版本冲突保护
- 执行编排与异常回退

## 协议文件（你最关心的部分）

- 独立协议类型目录：`backend/agentRoute/protocol/`
- 协议说明文档：`backend/agentRoute/INTERACTION_PROTOCOL.md`

## 参考 claude-code 的精华点（已落地）

1. 显式运行时状态推进（借鉴 `claude-code/src/query.ts` 的循环推进思想）
- 我们落地为 `AgentPhase` + `phaseTransition.ts`，每次推进都走受控迁移。
- 目标不是“分类一次就结束”，而是多轮可持续推进。

2. 会话恢复与中断容错（借鉴 `claude-code/src/utils/conversationRecovery.ts`）
- 我们落地为 `processedTurns` + `messageId` 幂等去重 + `sessionVersion` 冲突保护。
- 解决移动端网络重试/重复提交场景。

3. 任务态与执行态分离（借鉴 `claude-code/src/tasks/*` 和 `src/tasks/types.ts`）
- 我们落地为 `RoutePlugin`（决策）与 `ExecutionOrchestrator/RouteExecutor`（执行）分离。
- route 层不混入业务执行细节，便于扩展新 skill/tool。

4. 对外统一状态输出（借鉴 `claude-code/src/utils/sessionState.ts` 的状态广播思路）
- 我们落地为 `AgentRouteOutput`，统一返回 `phase/askUser/confirmation/uiHints/actions`。
- 客户端直接按结构化字段渲染，不依赖解析自然语言。

## 最小运行

```bash
cd backend
bun ./agentRoute/demo.ts
```

## Phase 拆分建议

1. Phase 1
- `types/sessionState/routeMatcher/AgentRoute`
- chat route 最小链路可运行

2. Phase 2
- slot 收集增强
- reminder/contact/task 路由完善
- 模糊值候选与追问

3. Phase 3
- confirmation 与执行 orchestration 增强
- retry/failed/fallback 细化

4. Phase 4
- 幂等与恢复策略完善（断线、重放）
- responseBuilder 与 UI hints 协议固定

5. Phase 5
- 插件化 route/executor
- 集成测试与压测
