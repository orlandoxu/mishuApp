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
  void input;
  return { confidence: 0, reason: 'money route intent is decided by AI router only' };
}

function extractSlots(input: AgentRouteInput, state: SessionState): SlotExtraction {
  void input;
  void state;
  // 槽位由 AI 意图路由统一写入。
  return { filled: {} };
}

function resolveMissingSlots(state: SessionState): string[] {
  const intent = state.slots.intent?.value;
  if (intent !== 'money.record' && intent !== 'money.query') {
    return ['intent'];
  }

  if (intent === 'money.query') {
    return [];
  }

  const missing: string[] = [];
  if (!state.slots.amount?.value) missing.push('amount');
  if (!state.slots.direction?.value) missing.push('direction');
  return missing;
}

function buildSlotPrompt(missing: string[], state: SessionState): string {
  const intent = state.slots.intent?.value;
  if (intent !== 'money.record' && intent !== 'money.query') {
    return '我来帮你处理账本。告诉我是记账还是查账吧。';
  }
  if (intent === 'money.query') {
    return '你想看今天、本周还是本月的收支？';
  }
  if (missing.includes('amount') && missing.includes('direction')) return '请告诉我金额和是收入还是支出。';
  if (missing.includes('amount')) return '这笔金额是多少？';
  return '这是收入还是支出？';
}

function needsConfirmation(state: SessionState): boolean {
  return state.slots.intent?.value === 'money.record';
}

function buildConfirmation(state: SessionState): ConfirmationPayload {
  const direction = state.slots.direction?.value === 'income' ? '收入' : '支出';
  const amount = state.slots.amount?.value ?? '-';
  const category = state.slots.category?.value ?? '其他';
  return {
    prompt: `确认记一笔${direction}：${amount} 元（${category}）？`,
    summary: `类型：${direction}；金额：${amount}；分类：${category}`,
    confirmLabel: '确认记账',
    denyLabel: '我再改改',
  };
}

function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null {
  const intent = state.slots.intent?.value;
  if (intent === 'money.query') {
    return {
      requestKey: `${state.sessionId}:${input.messageId}:money_query`,
      route: 'money',
      action: 'money.query',
      payload: {
        period: state.slots.period?.value ?? 'day',
        timezone: input.clientContext?.timezone ?? 'Asia/Shanghai',
      },
    };
  }

  if (intent !== 'money.record') return null;

  const amount = state.slots.amount?.value;
  const direction = state.slots.direction?.value;
  if (!amount || !direction) return null;

  return {
    requestKey: `${state.sessionId}:${input.messageId}:money_record`,
    route: 'money',
    action: 'money.record',
    payload: {
      amount,
      direction,
      category: state.slots.category?.value ?? '其他',
      note: state.slots.note?.value ?? input.text,
      occurredAt: Date.now(),
      userId: input.clientContext?.userId,
      timezone: input.clientContext?.timezone ?? 'Asia/Shanghai',
    },
  };
}

function applyClientActionResponse(state: SessionState, payload: { result?: Record<string, unknown> }): void {
  const summary = payload.result?.summary;
  if (typeof summary === 'string' && summary.trim()) {
    state.slots.actionSummary = {
      key: 'actionSummary',
      value: summary,
      confidence: 1,
      sourceMessageId: 'client_action_response',
      updatedAt: Date.now(),
    };
  }
}

function buildCompletedMessage(state: SessionState): string {
  const summary = state.slots.actionSummary?.value;
  if (summary) return summary;

  const intent = state.slots.intent?.value;
  if (intent === 'money.query') return '已完成账本查询。';
  const direction = state.slots.direction?.value === 'income' ? '收入' : '支出';
  return `已记账：${direction} ${state.slots.amount?.value ?? '-'} 元`;
}

export const moneyRoute: RoutePlugin = {
  id: 'money',
  description: 'Local money ledger record and query.',
  requiredSlots: [],
  detectIntent,
  extractSlots,
  resolveMissingSlots,
  buildSlotPrompt,
  needsConfirmation,
  buildConfirmation,
  buildExecutionRequest,
  applyClientActionResponse,
  buildCompletedMessage,
};
