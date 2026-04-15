# AgentRoute 交互协议（独立代码层）

这份文档只讲协议；实现代码都在 `backend/agentRoute/protocol/`。

## 代码位置（不是伪协议）

- 协议入口导出: `backend/agentRoute/protocol/index.ts`
- 协议版本: `backend/agentRoute/protocol/version.ts`
- 客户端请求协议: `backend/agentRoute/protocol/client.ts`
- 服务端响应协议: `backend/agentRoute/protocol/server.ts`
- 指令/渲染构建器: `backend/agentRoute/protocol/directiveBuilder.ts`

## A. 客户端 -> 服务端

类型：`ClientTurnRequest`

关键字段：
- `sessionId/turnId/messageId`：会话+幂等主键
- `clientSessionVersion`：客户端已知版本
- `interaction`：结构化动作

`interaction.kind` 已支持：
- `user_text`
- `confirm`
- `slot_update`
- `candidate_select`
- `client_data_response`（客户端回传向量检索等数据）
- `cancel`
- `retry`

## B. 服务端 -> 客户端

类型：`ServerTurnResponse`

除了基础字段，重点是：
- `protocol.recommendedInput`
- `protocol.directives[]`
- `presentation`（前端渲染模板与块）

`directives` 已支持：
- `assistant_message`
- `ask_slots`
- `show_candidates`
- `confirm`
- `request_client_data`（服务端向 App 索要数据）
- `execution_status`
- `completed`
- `failed`
- `sync_required`

`presentation.template` 已支持：
- `chat_bubble`
- `result_card`
- `confirm_sheet`
- `error_banner`
- `loading_card`

## C. 关键能力（你问的两点）

1) 服务端主动向 App 索要数据（向量检索）
- 协议：`request_client_data`
- 请求结构：`ClientDataRequest`
- 当前已接入场景：联系人名字不明确时，`contactRoute` 会请求 `vector_memory_search`
- 运行代码：
  - 请求生成：`backend/agentRoute/builtinRoutes/contactRoute.ts`
  - 指令下发：`backend/agentRoute/protocol/directiveBuilder.ts`
  - 回包处理：`backend/agentRoute/AgentRoute.ts` (`applyClientDataResponse`)

2) 任务完成如何让 App 呈现
- 协议：`presentation`
- 已有模板：`result_card/error_banner/loading_card/...`
- 运行代码：`backend/agentRoute/protocol/directiveBuilder.ts` (`buildPresentation`)

## D. 最小交互闭环

1. 服务端识别信息不足 -> 下发 `request_client_data`
2. App 做端侧向量检索 -> 回传 `client_data_response`
3. 服务端补槽并继续推进 -> 下发 `confirm` 或 `completed`
4. App 根据 `presentation` 渲染最终结果
