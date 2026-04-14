import type { AgentRouteInput, ConfirmationPayload, ExecutionRequest, RouteIntentResult, RoutePlugin, SessionState, SlotExtraction } from '../types';
import { compactText, extractAfter, firstTimeLike, hasAnyKeyword } from './common';

const KEYWORDS = ['提醒', 'remind', '闹钟', '定个提醒'];

/**
 * reminder 路由意图识别。
 */
function detectIntent(input: AgentRouteInput): RouteIntentResult {
  if (hasAnyKeyword(input.text, KEYWORDS)) {
    return { confidence: 0.95, reason: 'contains reminder keyword' };
  }

  return { confidence: 0.05, reason: 'not reminder intent' };
}

/**
 * 提取提醒标题与时间槽位。
 */
function extractSlots(input: AgentRouteInput): SlotExtraction {
  const text = compactText(input.text);
  const time = firstTimeLike(text);

  let title = extractAfter(text, '提醒我');
  if (!title) {
    title = extractAfter(text, '提醒');
  }

  if (title && time) {
    title = title.replace(time, '').trim();
  }

  return {
    filled: {
      ...(title ? { title: { value: title, confidence: 0.9 } } : {}),
      ...(time ? { when: { value: time, confidence: 0.75 } } : {}),
    },
  };
}

/**
 * 生成提醒确认信息。
 */
function buildConfirmation(state: SessionState): ConfirmationPayload {
  const title = state.slots.title?.value ?? '未命名提醒';
  const when = state.slots.when?.value ?? '未指定时间';
  return {
    prompt: `要创建这个提醒吗？${title}，时间：${when}`,
    summary: `提醒内容：${title}；提醒时间：${when}`,
    confirmLabel: '确认创建',
    denyLabel: '我再改改',
  };
}

/**
 * 在槽位齐备时构造提醒执行请求。
 */
function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null {
  const title = state.slots.title?.value;
  const when = state.slots.when?.value;
  if (!title || !when) {
    return null;
  }

  return {
    idempotencyKey: `${state.sessionId}:${input.messageId}:reminder`,
    route: 'reminder',
    action: 'create_reminder',
    payload: {
      title,
      when,
      timezone: input.clientContext?.timezone ?? 'Asia/Shanghai',
    },
  };
}

export const reminderRoute: RoutePlugin = {
  id: 'reminder',
  description: 'Create personal reminders.',
  requiredSlots: ['title', 'when'],
  detectIntent,
  extractSlots,
  // 根据缺失槽位返回追问文案。
  buildSlotPrompt(missing) {
    if (missing.includes('title') && missing.includes('when')) {
      return '请告诉我要提醒什么、在什么时间提醒。';
    }
    if (missing.includes('title')) {
      return '提醒内容是什么？';
    }
    return '提醒时间是什么时候？';
  },
  // 提醒创建默认需要用户确认。
  needsConfirmation() {
    return true;
  },
  buildConfirmation,
  buildExecutionRequest,
  // 生成提醒完成态文案。
  buildCompletedMessage(state: SessionState): string {
    return `提醒已创建：${state.slots.title?.value ?? '未命名'}（${state.slots.when?.value ?? '时间待定'}）`;
  },
};
