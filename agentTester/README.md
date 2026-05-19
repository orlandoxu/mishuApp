# agentTester

TS 自动化框架，用于在无前端接入时验证后端 AI Agent 能力可靠性、协议正确性与能力覆盖。

## CLI

```bash
npm --prefix agentTester run run -- --layer=all --suite=core --env=local-frpc
npm --prefix agentTester run report -- --format=md
```

## Web 可视化

```bash
npm --prefix agentTester run web
```

- 默认地址：`http://127.0.0.1:8320`
- 默认口令：`123456`（请通过环境变量覆盖）

环境变量：

- `AGENT_TESTER_WEB_HOST` 默认 `0.0.0.0`
- `AGENT_TESTER_WEB_PORT` 默认 `8320`
- `AGENT_TESTER_WEB_PASSWORD` 默认 `123456`
- `AGENT_TESTER_WEB_SESSION_TTL_MS` 默认 8 小时

测试运行环境变量：

- `AGENT_TEST_HTTP_URL` 默认 `http://127.0.0.1:3000`
- `AGENT_TEST_WS_URL` 默认 `ws://127.0.0.1:3001/house`
- `AGENT_TEST_TOKEN` 默认自动生成开发 token
- `AGENT_TEST_USER_ID` 默认 `agent-tester-user`

## 报告产出

- `agentTester/reports/*.json`
- `agentTester/reports/*.md`
- `agentTester/reports/index.json`（latest + history 摘要）

## 场景管理

- 内置场景：`agentTester/src/scenarios/scenarios.ts`
- 外部场景配置：`agentTester/scenarios/*.json`（数组，按 `id` 去重，`enabled=false` 可禁用）
