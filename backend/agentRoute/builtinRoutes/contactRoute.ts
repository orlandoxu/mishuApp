import type {
  AgentRouteInput,
  ConfirmationPayload,
  ExecutionRequest,
  RouteIntentResult,
  RoutePlugin,
  SessionState,
  SlotExtraction,
} from '../types';
import type { ClientCapabilityResponsePayload } from '../protocol';

function detectIntent(input: AgentRouteInput): RouteIntentResult {
  void input;
  return { confidence: 0, reason: 'contact route intent is decided by AI router only' };
}

function extractSlots(input: AgentRouteInput): SlotExtraction {
  void input;
  // 槽位由 AI 意图路由统一写入。
  return { filled: {} };
}

function resolveMissingSlots(state: SessionState): string[] {
  const missing: string[] = [];
  if (!state.slots.contactName?.value) missing.push('contactName');
  if (!state.slots.contactAction?.value) missing.push('contactAction');
  return missing;
}

function buildConfirmation(state: SessionState): ConfirmationPayload {
  const name = state.slots.contactName?.value ?? '目标联系人';
  const action = state.slots.contactAction?.value ?? 'message';
  const text = state.slots.messageBody?.value;
  const actionText = action === 'call' ? '拨打电话' : action === 'notify' ? '发送通知' : '发送消息';

  return {
    prompt: `确认${actionText}给 ${name} 吗？`,
    summary: text ? `${actionText}对象：${name}；内容：${text}` : `${actionText}对象：${name}`,
    confirmLabel: '确认',
    denyLabel: '取消',
  };
}

function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null {
  const contactName = state.slots.contactName?.value;
  const contactAction = state.slots.contactAction?.value;
  if (!contactName || !contactAction) {
    return null;
  }

  return {
    requestKey: `${state.sessionId}:${input.messageId}:contact`,
    route: 'contact',
    action: 'contact_execute',
    payload: {
      contactName,
      contactAction,
      messageBody: state.slots.messageBody?.value,
    },
  };
}

function buildClientCapabilityRequest(input: AgentRouteInput, state: SessionState) {
  const lacksContactName = !state.slots.contactName?.value;
  if (!lacksContactName) {
    return null;
  }

  return {
    requestId: `${state.sessionId}:${input.messageId}:contact_vector`,
    kind: 'vector_memory_search' as const,
    query: input.text.trim(),
    topK: 5,
    namespace: 'contacts',
    reason: '联系人名称不明确，需要端侧向量检索候选联系人',
  };
}

function applyClientCapabilityResponse(state: SessionState, payload: ClientCapabilityResponsePayload): void {
  if (payload.items.length === 0) {
    return;
  }

  const sorted = [...payload.items].sort((a, b) => (b.score ?? 0) - (a.score ?? 0));
  const top = sorted[0];
  if (!top) {
    return;
  }

  const metadataName = typeof top.metadata?.contactName === 'string' ? top.metadata.contactName : null;
  const name = metadataName ?? top.text;
  if (!name) {
    return;
  }

  state.slots.contactName = {
    key: 'contactName',
    value: name,
    confidence: Math.max(0.65, top.score ?? 0.65),
    sourceMessageId: `${payload.requestId}:client_data`,
    updatedAt: Date.now(),
  };
}

export const contactRoute: RoutePlugin = {
  id: 'contact',
  description: 'Contact/call/message operations.',
  requiredSlots: [],
  detectIntent,
  extractSlots,
  resolveMissingSlots,
  buildSlotPrompt(missing) {
    if (missing.includes('contactName') && missing.includes('contactAction')) {
      return '你要联系谁，以及希望执行什么动作（打电话/发消息）？';
    }
    if (missing.includes('contactName')) {
      return '你要联系谁？';
    }
    return '你希望执行什么动作（打电话/发消息/通知）？';
  },
  needsConfirmation() {
    return true;
  },
  buildConfirmation,
  buildClientCapabilityRequest,
  applyClientCapabilityResponse,
  buildExecutionRequest,
  buildCompletedMessage(state: SessionState): string {
    const name = state.slots.contactName?.value ?? '联系人';
    return `已处理联系请求：${name}`;
  },
};
