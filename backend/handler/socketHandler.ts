import { AgentRoute } from '../agentRoute/AgentRoute';
import { AGENT_ROUTE_PROTOCOL_VERSION, type ClientTurnRequest } from '../agentRoute/protocol';

export type SocketMessage = {
  type: string;
  requestId?: string;
  token?: string;
  payload?: unknown;
  data?: unknown;
  [key: string]: unknown;
};

type SocketUser = {
  id: string;
  realName: string;
};

type HandleSocketMessageArgs = {
  raw: string | Buffer;
  send: (payload: unknown) => void;
  setUserId: (userId: string) => void;
  ensureUserByToken: (token: string) => Promise<SocketUser | null>;
};

const agentRouteRuntime = new AgentRoute();

export async function handleSocketMessage(args: HandleSocketMessageArgs): Promise<void> {
  const { raw, send, setUserId, ensureUserByToken } = args;
  const text = typeof raw === 'string' ? raw : raw.toString();

  let message: SocketMessage;
  try {
    message = JSON.parse(text) as SocketMessage;
  } catch {
    send({ type: 'error', error: 'Invalid JSON message' });
    return;
  }

  switch (message.type) {
    case 'login': {
      const token = typeof message.token === 'string' ? message.token : '';
      if (!token) {
        send({ type: 'loginFail', requestId: message.requestId, error: 'token required' });
        return;
      }

      const user = await ensureUserByToken(token);
      if (!user?.id) {
        send({ type: 'loginFail', requestId: message.requestId, error: 'invalid token' });
        return;
      }

      setUserId(user.id);
      send({
        type: 'loginSuccess',
        requestId: message.requestId,
        userId: user.id,
        realName: user.realName,
      });
      return;
    }
    case 'ping':
      send({ type: 'pong', requestId: message.requestId, ts: Date.now() });
      return;
    case 'echo':
      send({ type: 'echoResponse', requestId: message.requestId, data: message.data });
      return;
    case 'agent_turn': {
      const payloadSource = asRecord(message.payload) ?? asRecord(message.data);
      if (!payloadSource) {
        send({ type: 'error', requestId: message.requestId, error: 'agent_turn payload required' });
        return;
      }

      const turnRequest = normalizeClientTurnRequest(payloadSource);
      if (!turnRequest) {
        send({ type: 'error', requestId: message.requestId, error: 'invalid agent_turn payload' });
        return;
      }

      try {
        const response = await agentRouteRuntime.handle(turnRequest);
        send({
          type: 'agent_turn_result',
          requestId: message.requestId ?? turnRequest.messageId,
          payload: response,
        });
      } catch (error) {
        const detail = error instanceof Error ? error.message : String(error);
        send({
          type: 'agent_turn_result',
          requestId: message.requestId ?? turnRequest.messageId,
          payload: {
            sessionId: turnRequest.sessionId,
            sessionVersion: turnRequest.clientSessionVersion ?? 0,
            turnId: turnRequest.turnId,
            messageId: turnRequest.messageId,
            route: 'fallback',
            phase: 'failed',
            message: '服务端执行失败，请稍后重试。',
            missingSlots: [],
            filledSlots: {},
            executable: false,
            needsUserInput: false,
            uiHints: {
              display: 'error',
              allowCancel: false,
            },
            presentation: {
              template: 'error_banner',
              blocks: [{ type: 'status_chip', status: 'error', text: detail }],
            },
            actions: [{ type: 'none' }],
            error: {
              code: 'AGENT_TURN_INTERNAL_ERROR',
              message: detail,
              retryable: true,
            },
            protocol: {
              version: AGENT_ROUTE_PROTOCOL_VERSION,
              recommendedInput: 'user_text',
              directives: [
                {
                  type: 'failed',
                  code: 'AGENT_TURN_INTERNAL_ERROR',
                  message: detail,
                  retryable: true,
                },
              ],
            },
          },
        });
      }
      return;
    }
    default:
      send({ type: 'error', requestId: message.requestId, error: 'Unknown message type' });
  }
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  return null;
}

function readString(record: Record<string, unknown>, key: string): string | null {
  const value = record[key];
  if (typeof value !== 'string') {
    return null;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeClientTurnRequest(payload: Record<string, unknown>): ClientTurnRequest | null {
  const sessionId = readString(payload, 'sessionId');
  const turnId = readString(payload, 'turnId');
  const messageId = readString(payload, 'messageId');
  const text = readString(payload, 'text');

  if (!sessionId || !turnId || !messageId || !text) {
    return null;
  }

  const interaction = payload.interaction;
  const history = payload.history;
  const clientContext = payload.clientContext;
  const timestamp = payload.timestamp;
  const clientSessionVersion = payload.clientSessionVersion;
  const protocolVersion = readString(payload, 'protocolVersion') ?? AGENT_ROUTE_PROTOCOL_VERSION;

  const request: ClientTurnRequest = {
    protocolVersion,
    sessionId,
    turnId,
    messageId,
    text,
  };

  if (interaction && typeof interaction === 'object') {
    request.interaction = interaction as ClientTurnRequest['interaction'];
  }
  if (Array.isArray(history)) {
    request.history = history as ClientTurnRequest['history'];
  }
  if (clientContext && typeof clientContext === 'object') {
    request.clientContext = clientContext as ClientTurnRequest['clientContext'];
  }
  if (typeof timestamp === 'number' && Number.isFinite(timestamp)) {
    request.timestamp = Math.floor(timestamp);
  }
  if (typeof clientSessionVersion === 'number' && Number.isFinite(clientSessionVersion)) {
    request.clientSessionVersion = Math.floor(clientSessionVersion);
  }

  return request;
}
