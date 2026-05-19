import type { RunEnv } from '../types/index.js';
import { buildDevJwtToken } from '../utils/jwt.js';

export type EnvConfig = {
  name: RunEnv;
  baseHttpUrl: string;
  wsUrl: string;
  authToken: string;
};

export function resolveEnv(env: RunEnv): EnvConfig {
  const baseHttpUrl = process.env.AGENT_TEST_HTTP_URL ?? 'http://127.0.0.1:3000';
  const wsUrl = process.env.AGENT_TEST_WS_URL ?? 'ws://127.0.0.1:3001/house';
  const userId = process.env.AGENT_TEST_USER_ID ?? 'agent-tester-user';
  const authToken = process.env.AGENT_TEST_TOKEN ?? buildDevJwtToken(userId);
  return { name: env, baseHttpUrl, wsUrl, authToken };
}
