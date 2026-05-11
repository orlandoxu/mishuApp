import type {
  AgentRouteInput,
  ConfirmationPayload,
  ExecutionRequest,
  RouteIntentResult,
  RoutePlugin,
  SessionState,
  SlotExtraction,
} from '../types';
import { compactText, hasAnyKeyword } from './common';

const KEYWORDS = [
  '记账', '花了', '收入', '支出', '消费', '本周花了', '本月花了', '查账',
  'record', 'income', 'expense', 'spend', 'query', 'ledger', 'account',
];

function detectIntent(input: AgentRouteInput): RouteIntentResult {
  if (hasAnyKeyword(input.text, KEYWORDS)) {
    return { confidence: 0.9, reason: 'money keyword matched' };
  }
  return { confidence: 0.05, reason: 'not money intent' };
}

function extractSlots(input: AgentRouteInput, state: SessionState): SlotExtraction {
  const text = compactText(input.text);
  const intentText = state.slots.intent?.value;
  const llmIntent = typeof intentText === 'string' && intentText.trim() ? intentText.trim().toLowerCase() : '';
  const amountMatch = text.match(/(\d+(?:\.\d{1,2})?)/);
  const direction = hasAnyKeyword(text, ['收入', '进账', '赚', 'income', 'earn'])
    ? 'income'
    : hasAnyKeyword(text, ['支出', '花了', '消费', '付款', 'expense', 'spend', 'paid', 'cost'])
      ? 'expense'
      : null;

  const hasAmount = Boolean(amountMatch);
  const hasQueryHint = hasAnyKeyword(text, ['本周', '本月', '查询', '查账', '多少', 'query', 'how much', 'summary']);
  const moneyOperation = llmIntent === 'money.query'
    ? 'ledger_query'
    : llmIntent === 'money.record'
      ? 'ledger_record'
      : !hasAmount && hasQueryHint
        ? 'ledger_query'
        : 'ledger_record';

  const period = hasAnyKeyword(text, ['本周', 'week', 'weekly'])
    ? 'week'
    : hasAnyKeyword(text, ['本月', 'month', 'monthly'])
      ? 'month'
      : hasAnyKeyword(text, ['今天', 'today', 'daily'])
        ? 'day'
        : 'day';

  const expenseCategories = parseCategoryList(state.slots.expenseCategories?.value);
  const incomeCategories = parseCategoryList(state.slots.incomeCategories?.value);
  const category = chooseCategory({
    text,
    direction,
    expenseCategories,
    incomeCategories,
  });

  return {
    filled: {
      moneyOperation: { value: moneyOperation, confidence: 0.9 },
      ...(llmIntent ? { intent: { value: llmIntent, confidence: 0.9 } } : {}),
      ...(amountMatch ? { amount: { value: amountMatch[1], confidence: 0.86 } } : {}),
      ...(direction ? { direction: { value: direction, confidence: 0.84 } } : {}),
      ...(moneyOperation === 'ledger_query' ? { period: { value: period, confidence: 0.9 } } : {}),
      category: { value: category, confidence: 0.7 },
      originalText: { value: text, confidence: 1 },
    },
  };
}

function parseCategoryList(raw?: string): string[] {
  if (!raw) return [];
  return raw.split('|').map((x) => x.trim()).filter(Boolean);
}

function chooseCategory(args: {
  text: string;
  direction: string | null;
  expenseCategories: string[];
  incomeCategories: string[];
}): string {
  const categories = args.direction === 'income' ? args.incomeCategories : args.expenseCategories;
  if (categories.length === 0) {
    if (args.direction === 'income') return '工资';
    return '其他';
  }

  for (const name of categories) {
    if (args.text.includes(name)) return name;
  }

  if (args.direction === 'income') {
    if (hasAnyKeyword(args.text, ['工资', 'salary'])) return pickExisting(categories, '工资');
    if (hasAnyKeyword(args.text, ['兼职', 'part', 'freelance'])) return pickExisting(categories, '兼职');
    return pickExisting(categories, '其他');
  }

  if (hasAnyKeyword(args.text, ['打车', '出租', '公交', '地铁', 'taxi', 'bus', 'subway', 'transport'])) {
    return pickExisting(categories, '交通');
  }
  if (hasAnyKeyword(args.text, ['餐', '饭', '奶茶', 'food', 'meal', 'coffee'])) {
    return pickExisting(categories, '餐饮');
  }
  if (hasAnyKeyword(args.text, ['购物', 'shop', 'mall'])) {
    return pickExisting(categories, '购物');
  }
  return pickExisting(categories, '其他');
}

function pickExisting(categories: string[], preferred: string): string {
  if (categories.includes(preferred)) return preferred;
  if (categories.includes('其他')) return '其他';
  return categories[0] ?? '其他';
}

function resolveMissingSlots(state: SessionState): string[] {
  const op = state.slots.moneyOperation?.value;
  if (!op) return ['moneyOperation'];
  if (op === 'ledger_query') return [];
  const missing: string[] = [];
  if (!state.slots.amount?.value) missing.push('amount');
  if (!state.slots.direction?.value) missing.push('direction');
  return missing;
}

function buildSlotPrompt(missing: string[], state: SessionState): string {
  const op = state.slots.moneyOperation?.value;
  if (!op) return '你是要记账，还是要查询账本？';
  if (op === 'ledger_query') return '你想看今天、本周还是本月的收支？';
  if (missing.includes('amount') && missing.includes('direction')) return '请告诉我金额和是收入还是支出。';
  if (missing.includes('amount')) return '这笔金额是多少？';
  return '这是收入还是支出？';
}

function needsConfirmation(state: SessionState): boolean {
  return state.slots.moneyOperation?.value === 'ledger_record';
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
  const operation = state.slots.moneyOperation?.value;
  if (!operation) return null;

  if (operation === 'ledger_query') {
    return {
      requestKey: `${state.sessionId}:${input.messageId}:money_query`,
      route: 'money',
      action: 'money.query',
      payload: {
        operation,
        period: state.slots.period?.value ?? 'day',
        timezone: input.clientContext?.timezone ?? 'Asia/Shanghai',
      },
    };
  }

  const amount = state.slots.amount?.value;
  const direction = state.slots.direction?.value;
  if (!amount || !direction) return null;

  return {
    requestKey: `${state.sessionId}:${input.messageId}:money_record`,
    route: 'money',
    action: 'money.record',
    payload: {
      operation,
      amount,
      direction,
      category: state.slots.category?.value ?? '其他',
      note: state.slots.originalText?.value,
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

  const operation = state.slots.moneyOperation?.value;
  if (operation === 'ledger_query') return '已完成账本查询。';
  const direction = state.slots.direction?.value === 'income' ? '收入' : '支出';
  return `已记账：${direction} ${state.slots.amount?.value ?? '-'} 元`;
}

export const moneyRoute: RoutePlugin = {
  id: 'money',
  description: 'Local money ledger record and query.',
  requiredSlots: ['moneyOperation'],
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
