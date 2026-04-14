import {
  type AgentRouteOutput,
  type AgentRouteInput,
  type SessionState,
  type SessionStore,
} from './types';

const MAX_HISTORY = 40;
const MAX_DEDUP_CACHE = 120;

/**
 * 创建新会话的默认状态。
 */
export function createInitialSessionState(sessionId: string, now: number): SessionState {
  return {
    sessionId,
    version: 0,
    phase: 'intent_detected',
    activeRoute: 'chat',
    slots: {},
    missingSlots: [],
    ambiguousSlots: {},
    confirmation: {
      required: false,
    },
    execution: {
      retries: 0,
    },
    history: [],
    processedTurns: {},
    updatedAt: now,
  };
}

/**
 * 追加一条用户消息到服务端会话历史。
 */
export function appendUserMessage(state: SessionState, input: AgentRouteInput, now: number): void {
  state.history.push({
    id: input.messageId,
    turnId: input.turnId,
    actor: 'user',
    text: input.text,
    createdAt: now,
  });

  if (state.history.length > MAX_HISTORY) {
    state.history = state.history.slice(state.history.length - MAX_HISTORY);
  }
}

/**
 * 追加一条助手消息到服务端会话历史。
 */
export function appendAssistantMessage(
  state: SessionState,
  turnId: string,
  messageId: string,
  text: string,
  now: number,
): void {
  state.history.push({
    id: `${messageId}:assistant`,
    turnId,
    actor: 'assistant',
    text,
    createdAt: now,
  });

  if (state.history.length > MAX_HISTORY) {
    state.history = state.history.slice(state.history.length - MAX_HISTORY);
  }
}

/**
 * 根据 messageId 读取已处理输出，用于幂等去重。
 */
export function getDedupOutput(state: SessionState, messageId: string): AgentRouteOutput | null {
  return state.processedTurns[messageId]?.output ?? null;
}

/**
 * 标记当前 turn 已处理并缓存输出快照，防止重复提交造成重复处理。
 */
export function markProcessedTurn(
  state: SessionState,
  input: AgentRouteInput,
  output: AgentRouteOutput,
  now: number,
): void {
  state.processedTurns[input.messageId] = {
    messageId: input.messageId,
    turnId: input.turnId,
    output,
    processedAt: now,
  };

  const dedupItems = Object.entries(state.processedTurns)
    .sort((a, b) => a[1].processedAt - b[1].processedAt)
    .slice(-MAX_DEDUP_CACHE);

  state.processedTurns = Object.fromEntries(dedupItems);
}

export class InMemorySessionStore implements SessionStore {
  private readonly sessions = new Map<string, SessionState>();

  /**
   * 读取会话状态；不存在返回 null。
   */
  async get(sessionId: string): Promise<SessionState | null> {
    return this.sessions.get(sessionId) ?? null;
  }

  /**
   * 使用乐观并发版本号保存会话，冲突时抛错，避免并发覆盖。
   */
  async save(state: SessionState, expectedVersion: number): Promise<SessionState> {
    const current = this.sessions.get(state.sessionId);
    const currentVersion = current?.version ?? 0;

    if (currentVersion !== expectedVersion) {
      throw new Error(
        `SESSION_VERSION_CONFLICT: session=${state.sessionId} expected=${expectedVersion} actual=${currentVersion}`,
      );
    }

    const nextState: SessionState = {
      ...state,
      version: state.version + 1,
      updatedAt: Date.now(),
    };

    this.sessions.set(state.sessionId, nextState);
    return nextState;
  }
}
