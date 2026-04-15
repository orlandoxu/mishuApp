import type {
  AgentRouteInput,
  ConfirmationPayload,
  ExecutionRequest,
  RouteIntentResult,
  RoutePlugin,
  SessionState,
  SlotExtraction,
} from '../types';
import type { ClientDataResponsePayload } from '../protocol';
import { compactText, extractAfter, hasAnyKeyword, simpleNameGuess } from './common';

const KEYWORDS = ['联系', '打电话', '电话给', '发消息', '通知'];

/**
 * contact 路由意图识别。
 */
function detectIntent(input: AgentRouteInput): RouteIntentResult {
  if (hasAnyKeyword(input.text, KEYWORDS)) {
    return { confidence: 0.92, reason: 'contact action keyword detected' };
  }

  return { confidence: 0.05, reason: 'not contact intent' };
}

/**
 * 从文本动作词中提取联系人操作类型。
 */
function extractAction(text: string): string | null {
  if (hasAnyKeyword(text, ['打电话', '电话'])) {
    return 'call';
  }
  if (hasAnyKeyword(text, ['发消息', '微信', '短信', '消息'])) {
    return 'message';
  }
  if (hasAnyKeyword(text, ['通知'])) {
    return 'notify';
  }
  return null;
}

/**
 * 提取联系人、动作和消息内容槽位。
 */
function extractSlots(input: AgentRouteInput): SlotExtraction {
  const text = compactText(input.text);
  let name = simpleNameGuess(text);
  const action = extractAction(text);

  if (name) {
    name = name.replace(/(发消息.*|打电话.*|通知.*)$/u, '').trim();
  }
  if (name && /^(那个|上次|之前|她|他|ta)/iu.test(name)) {
    name = null;
  }

  let content = extractAfter(text, '说');
  if (!content) {
    content = extractAfter(text, '内容是');
  }

  return {
    filled: {
      ...(name ? { contactName: { value: name, confidence: 0.72 } } : {}),
      ...(action ? { contactAction: { value: action, confidence: 0.9 } } : {}),
      ...(content ? { messageBody: { value: content, confidence: 0.7 } } : {}),
    },
  };
}

/**
 * 生成联系人动作确认信息。
 */
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

/**
 * 在必要槽位齐备时构造联系人执行请求。
 */
function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null {
  const contactName = state.slots.contactName?.value;
  const contactAction = state.slots.contactAction?.value;
  if (!contactName || !contactAction) {
    return null;
  }

  return {
    idempotencyKey: `${state.sessionId}:${input.messageId}:contact`,
    route: 'contact',
    action: 'contact_execute',
    payload: {
      contactName,
      contactAction,
      messageBody: state.slots.messageBody?.value,
    },
  };
}

/**
 * 在联系人缺失且用户表达“那个/上次/他/她”等指代时，请求客户端进行向量检索。
 */
function buildClientDataRequest(input: AgentRouteInput, state: SessionState) {
  const lacksContactName = !state.slots.contactName?.value;
  if (!lacksContactName) {
    return null;
  }

  const text = input.text.trim();
  const hasReferenceWord = /(那个|上次|之前|她|他|ta|that one)/i.test(text);
  if (!hasReferenceWord) {
    return null;
  }

  return {
    requestId: `${state.sessionId}:${input.messageId}:contact_vector`,
    kind: 'vector_memory_search' as const,
    query: text,
    topK: 5,
    namespace: 'contacts',
    reason: '联系人名称不明确，需要端侧向量检索候选联系人',
  };
}

/**
 * 应用客户端返回的候选数据，优先使用最高分项补全 contactName。
 */
function applyClientDataResponse(state: SessionState, payload: ClientDataResponsePayload): void {
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
  requiredSlots: ['contactName', 'contactAction'],
  detectIntent,
  extractSlots,
  // 根据缺失槽位返回追问文案。
  buildSlotPrompt(missing) {
    if (missing.includes('contactName') && missing.includes('contactAction')) {
      return '你要联系谁，以及希望执行什么动作（打电话/发消息）？';
    }
    if (missing.includes('contactName')) {
      return '你要联系谁？';
    }
    return '你希望执行什么动作（打电话/发消息/通知）？';
  },
  // 联系人动作默认需要确认。
  needsConfirmation() {
    return true;
  },
  buildConfirmation,
  buildClientDataRequest,
  applyClientDataResponse,
  buildExecutionRequest,
  // 生成联系人动作完成态文案。
  buildCompletedMessage(state: SessionState): string {
    const name = state.slots.contactName?.value ?? '联系人';
    return `已处理联系请求：${name}`;
  },
};
