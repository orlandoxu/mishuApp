import type { AgentRouteInput, ConfirmationPayload, ExecutionRequest, RouteIntentResult, RoutePlugin, SessionState, SlotExtraction } from '../types';

/**
 * chat 路由意图识别：作为默认兜底会话路由，置信度保持中等。
 */
function detectIntent(input: AgentRouteInput): RouteIntentResult {
  const text = input.text.trim();
  if (!text) {
    return { confidence: 0.1, reason: 'empty input' };
  }

  return { confidence: 0.4, reason: 'default conversational route' };
}

/**
 * chat 路由不收集业务 slots。
 */
function extractSlots(): SlotExtraction {
  return { filled: {} };
}

/**
 * chat 路由确认文案（当前默认不启用确认，仅保留接口一致性）。
 */
function buildConfirmation(): ConfirmationPayload {
  return {
    prompt: '需要继续聊天吗？',
    summary: '当前是通用对话模式。',
    confirmLabel: '继续',
    denyLabel: '切换任务',
  };
}

/**
 * chat 路由不触发外部执行，返回 null。
 */
function buildExecutionRequest(): ExecutionRequest | null {
  return null;
}

export const chatRoute: RoutePlugin = {
  id: 'chat',
  description: 'Generic conversation and fallback QA.',
  requiredSlots: [],
  detectIntent,
  extractSlots,
  // 生成 chat 路由追问文案。
  buildSlotPrompt() {
    return '我在，想聊什么？';
  },
  // chat 路由默认不需要确认。
  needsConfirmation() {
    return false;
  },
  buildConfirmation,
  buildExecutionRequest,
  // 生成 chat 路由完成态文案。
  buildCompletedMessage(state: SessionState): string {
    const lastUser = [...state.history].reverse().find((item) => item.actor === 'user')?.text ?? '';
    return `收到：${lastUser}`;
  },
};
