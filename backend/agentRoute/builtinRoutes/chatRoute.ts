import type {
  AgentRouteInput,
  ConfirmationPayload,
  ExecutionRequest,
  RouteIntentResult,
  RoutePlugin,
  SessionState,
  SlotExtraction,
} from '../types';

function detectIntent(input: AgentRouteInput): RouteIntentResult {
  const text = input.text.trim();
  if (!text) return { confidence: 0.1, reason: 'empty input' };
  return { confidence: 0.4, reason: 'default chat route' };
}

function extractSlots(): SlotExtraction {
  return { filled: {} };
}

function buildConfirmation(): ConfirmationPayload {
  return {
    prompt: '继续对话吗？',
    summary: '当前是聊天模式',
    confirmLabel: '继续',
    denyLabel: '取消',
  };
}

function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest {
  const historyText = state.history
    .slice(-12)
    .map((item) => `${item.actor}:${item.text}`)
    .join('\n');

  return {
    idempotencyKey: `${state.sessionId}:${input.messageId}:chat`,
    route: 'chat',
    action: 'chat.reply',
    payload: {
      userText: input.text,
      historyText,
    },
  };
}

export const chatRoute: RoutePlugin = {
  id: 'chat',
  description: 'Generic conversation.',
  requiredSlots: [],
  detectIntent,
  extractSlots,
  buildSlotPrompt() {
    return '我在，想聊什么？';
  },
  needsConfirmation() {
    return false;
  },
  buildConfirmation,
  buildExecutionRequest,
  buildCompletedMessage(state: SessionState): string {
    return state.execution.result?.data?.reply as string ?? state.execution.result?.summary ?? '我在，继续说。';
  },
};
