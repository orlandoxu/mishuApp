import { assertProtocolV3Strict } from '../assertions/protocol.js';
import type { EnvironmentCheck } from '../types/index.js';
import type { EnvConfig } from '../config/env.js';
import { getJson } from '../utils/http.js';
import WebSocket from 'ws';
import { execSync } from 'node:child_process';

export async function checkEnvironment(env: EnvConfig): Promise<EnvironmentCheck> {
  const issues = [] as EnvironmentCheck['issues'];

  try {
    await getJson(`${env.baseHttpUrl}/health`);
  } catch (error) {
    issues.push({ severity: 'strong', kind: 'environment_failure', message: `REST 健康检查失败: ${String(error)}` });
  }

  try {
    await openWs(env);
  } catch (error) {
    issues.push({ severity: 'strong', kind: 'environment_failure', message: `WS 连接失败: ${String(error)}` });
  }

  verifyPm2Processes(issues);

  const protocolIssues = assertProtocolV3Strict({
    protocol: { version: 'probe', recommendedInput: 'user_text', directives: [{ type: 'assistant_message', text: 'ok' }] }
  });
  if (protocolIssues.length > 0) {
    issues.push(...protocolIssues);
  }

  return {
    ok: issues.length === 0,
    issues,
    baseHttpUrl: env.baseHttpUrl,
    wsUrl: env.wsUrl,
    authToken: env.authToken
  };
}

function verifyPm2Processes(issues: EnvironmentCheck['issues']): void {
  try {
    const raw = execSync('pm2 jlist', { encoding: 'utf8' });
    const list = JSON.parse(raw) as Array<{ name?: string }>;
    const names = new Set(list.map((x) => x.name).filter((x): x is string => typeof x === 'string'));
    const required = ['rest', 'socket', 'frpc'];
    const missing = required.filter((name) => !names.has(name));
    if (missing.length > 0) {
      issues.push({
        severity: 'strong',
        kind: 'environment_failure',
        message: `PM2 缺少关键进程: ${missing.join(', ')}`,
        hint: '请使用 pm2 启动标准服务后重试。'
      });
    }
  } catch (error) {
    issues.push({
      severity: 'strong',
      kind: 'environment_failure',
      message: `无法执行 pm2 自检: ${String(error)}`,
      hint: '请确认 PM2 已安装并可在当前 shell 访问。'
    });
  }
}

async function openWs(env: EnvConfig): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const socket = new WebSocket(`${env.wsUrl}?token=${encodeURIComponent(env.authToken)}`);
    const timeout = setTimeout(() => {
      socket.close();
      reject(new Error('timeout'));
    }, 6000);

    socket.once('open', () => {
      clearTimeout(timeout);
      socket.close();
      resolve();
    });

    socket.once('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}
