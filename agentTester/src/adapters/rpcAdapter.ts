import WebSocket from 'ws';
import { AGENT_ROUTE_PROTOCOL_VERSION } from '../../../backend/agentRoute/protocol/version.ts';
import type { EnvConfig } from '../config/env.js';
import type { ScenarioResult, StepResult, TestScenario } from '../types/index.js';
import { uid } from '../utils/id.js';

type RpcResponse = {
  type: string;
  requestId?: string;
  payload?: {
    code?: number | string;
    msg?: string;
    data?: Record<string, unknown>;
  };
};

export async function runRpcScenario(scenario: TestScenario, env: EnvConfig): Promise<ScenarioResult> {
  const socket = await connect(env);
  const sessionId = uid(`rpc-${scenario.id}`);
  const steps: StepResult[] = [];
  let sessionVersion = 0;
  let lastActionRequestId: string | null = null;

  try {
    for (let i = 0; i < scenario.turns.length; i += 1) {
      const turn = scenario.turns[i];
      const requestId = uid(`req${i + 1}`);
      const messageId = uid(`m${i + 1}`);
      const turnId = uid(`t${i + 1}`);

      const payload: Record<string, unknown> = {
        protocolVersion: AGENT_ROUTE_PROTOCOL_VERSION,
        sessionId,
        turnId,
        messageId,
        text: turn.text,
        clientSessionVersion: sessionVersion,
        clientContext: { platform: 'ios', timezone: 'Asia/Shanghai' }
      };

      if (turn.interaction) {
        const cloned = JSON.parse(JSON.stringify(turn.interaction));
        const interaction = asRecord(cloned);
        const interactionPayload = asRecord(interaction?.payload);
        if (interactionPayload?.requestId === '__AUTO_FROM_DIRECTIVE__') {
          interactionPayload.requestId = lastActionRequestId ?? uid('fallback-action');
        }
        payload.interaction = cloned;
      }

      if (scenario.id === 'core-session-version-conflict' && i === 1) {
        payload.clientSessionVersion = 0;
      }

      socket.send(JSON.stringify({ type: 'rpc', method: 'agent.turn', requestId, payload }));
      const response = await waitRpcResponse(socket, requestId);
      const data = response.payload?.data ?? {};
      const dataError = asRecord((data as Record<string, unknown>).error);
      const errorCode =
        typeof dataError?.code === 'string'
          ? dataError.code
          : response.payload?.code && response.payload.code !== 0
            ? String(response.payload.code)
            : undefined;
      sessionVersion = typeof data.sessionVersion === 'number' ? data.sessionVersion : sessionVersion;

      const protocol = asRecord(data.protocol);
      const directiveList = Array.isArray(protocol?.directives) ? protocol.directives : [];
      const directives = directiveList
        .map((item) => asRecord(item))
        .filter((item): item is Record<string, unknown> => Boolean(item))
        .map((item) => (typeof item.type === 'string' ? item.type : 'unknown'));

      for (const item of directiveList) {
        const rec = asRecord(item);
        if (rec?.type === 'request_client_action' && typeof rec.requestId === 'string') {
          lastActionRequestId = rec.requestId;
        }
      }

      steps.push({
        turnIndex: i,
        phase: typeof data.phase === 'string' ? data.phase : undefined,
        directives,
        recommendedInput: typeof protocol?.recommendedInput === 'string' ? protocol.recommendedInput : undefined,
        message: typeof data.message === 'string' ? data.message : undefined,
        errorCode,
        issues: []
      });
    }
  } finally {
    socket.close();
  }

  return {
    layer: 'rpc',
    scenarioId: scenario.id,
    capabilityId: scenario.capabilityId,
    title: scenario.title,
    level: scenario.level,
    verdict: 'pass',
    steps,
    issues: []
  };
}

async function connect(env: EnvConfig): Promise<WebSocket> {
  return await new Promise((resolve, reject) => {
    const socket = new WebSocket(`${env.wsUrl}?token=${encodeURIComponent(env.authToken)}`);
    const timeout = setTimeout(() => reject(new Error(`ws connect timeout: ${env.wsUrl}`)), 8_000);

    socket.once('open', () => {
      clearTimeout(timeout);
      resolve(socket);
    });
    socket.once('error', (err) => {
      clearTimeout(timeout);
      reject(err);
    });
  });
}

async function waitRpcResponse(socket: WebSocket, requestId: string): Promise<RpcResponse> {
  return await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      cleanup();
      reject(new Error(`rpc timeout requestId=${requestId}`));
    }, 15_000);

    const onMessage = (raw: WebSocket.RawData) => {
      try {
        const text = typeof raw === 'string' ? raw : raw.toString();
        const data = JSON.parse(text) as RpcResponse;
        if (data.type !== 'rpc' || data.requestId !== requestId) return;
        cleanup();
        resolve(data);
      } catch (error) {
        cleanup();
        reject(error);
      }
    };

    const onError = (error: Error) => {
      cleanup();
      reject(error);
    };

    function cleanup(): void {
      clearTimeout(timeout);
      socket.off('message', onMessage);
      socket.off('error', onError);
    }

    socket.on('message', onMessage);
    socket.on('error', onError);
  });
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>;
  return null;
}
