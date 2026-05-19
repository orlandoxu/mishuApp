# agentTester

TS 自动化框架，用于在无前端接入时验证后端 AI Agent 能力可靠性、协议正确性与能力覆盖。

## 使用

```bash
pnpm --dir agentTester install
pnpm --dir agentTester run run --layer=all --suite=smoke --env=local-frpc
```

## 环境变量

- `AGENT_TEST_HTTP_URL` 默认 `http://127.0.0.1:3000`
- `AGENT_TEST_WS_URL` 默认 `ws://127.0.0.1:3001/house`
- `AGENT_TEST_TOKEN` 默认自动生成开发 token
- `AGENT_TEST_USER_ID` 默认 `agent-tester-user`

## 产出

- `agentTester/reports/*.json`
- `agentTester/reports/*.md`
