# AgentRoute 交互协议（v3）

协议代码：`backend/agentRoute/protocol/`
版本：`2026-05-08.v3`

## 客户端 -> 服务端

`ClientTurnRequest.interaction.kind`：
- `user_text`
- `confirm`
- `slot_update`
- `candidate_select`
- `client_capability_response`（v3 标准）
- `client_action_response`（v3 新增）
- `client_data_response`（v2 兼容别名）
- `cancel`
- `retry`

## 服务端 -> 客户端

`ServerTurnResponse.protocol.directives[]`：
- `assistant_message`
- `ask_slots`
- `show_candidates`
- `confirm`
- `request_client_capability`（v3 标准）
- `request_client_action`（v3 新增，本地执行动作）
- `request_client_data`（v2 兼容别名）
- `execution_status`
- `completed`
- `failed`
- `sync_required`

`recommendedInput`：
- `user_text`
- `confirm_or_deny`
- `slot_update`
- `candidate_select`
- `client_capability_response`
- `client_action_response`
- `none`

## 本地动作闭环（v3）

1. 服务端下发 `request_client_action`（例如 `money.record`、`money.query`）。
2. iOS 在本地账本执行动作。
3. iOS 回传 `client_action_response`（带 `requestId/success/result/error`）。
4. 服务端进入 `completed/failed`，返回最终 `message + presentation`。

## 兼容策略

- v3 保留 `request_client_data` 与 `client_data_response` 一个周期，便于灰度。
- 新客户端优先使用 `request_client_capability` / `client_capability_response`。
