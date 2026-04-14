import type { AgentRouteInput, ConfirmationPayload, ExecutionRequest, RouteIntentResult, RoutePlugin, SessionState, SlotExtraction } from '../types';

/**
 * fallback 路由不参与正常意图竞争，仅用于兜底。
 */
function detectIntent(): RouteIntentResult {
  return { confidence: 0, reason: 'fallback route only' };
}

/**
 * fallback 路由不提取业务 slots。
 */
function extractSlots(): SlotExtraction {
  return { filled: {} };
}

/**
 * fallback 确认信息模板。
 */
function buildConfirmation(): ConfirmationPayload {
  return {
    prompt: '要继续尝试吗？',
    summary: '当前请求未匹配到稳定任务路由。',
  };
}

/**
 * fallback 不触发执行。
 */
function buildExecutionRequest(): ExecutionRequest | null {
  return null;
}

export const fallbackRoute: RoutePlugin = {
  id: 'fallback',
  description: 'Fallback route when confidence is low or context is invalid.',
  requiredSlots: [],
  detectIntent,
  extractSlots,
  // 兜底路由追问文案。
  buildSlotPrompt() {
    return '我没完全听懂，你可以换一种说法，或告诉我你想做提醒/联系人/待办。';
  },
  // 兜底路由默认不走确认。
  needsConfirmation() {
    return false;
  },
  buildConfirmation,
  buildExecutionRequest,
  // 兜底完成态文案。
  buildCompletedMessage(_state: SessionState): string {
    return '请求进入兜底流程，请补充更多信息。';
  },
};
