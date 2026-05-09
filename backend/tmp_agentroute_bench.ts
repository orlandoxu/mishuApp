import { AgentRoute } from './agentRoute/AgentRoute';

const agent = new AgentRoute();

const req = {
  protocolVersion: '2026-05-08.v3',
  sessionId: 'bench-ios-session',
  turnId: crypto.randomUUID(),
  messageId: crypto.randomUUID(),
  text: process.argv[2] ?? '帮我记一笔账，午饭花了38元',
  timestamp: Date.now(),
  clientContext: {
    locale: 'zh-CN',
    timezone: 'Asia/Shanghai',
    platform: 'ios',
    appVersion: 'bench',
    deviceId: 'bench-device',
  },
};

const t0 = Date.now();
const out = await agent.handle(req as any);
const cost = Date.now() - t0;
console.log(JSON.stringify({ costMs: cost, phase: out.phase, message: out.message?.slice(0, 120) }, null, 2));
