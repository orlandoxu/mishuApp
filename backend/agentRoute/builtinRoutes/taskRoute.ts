import type { AgentRouteInput, ConfirmationPayload, ExecutionRequest, RouteIntentResult, RoutePlugin, SessionState, SlotExtraction } from '../types';

/**
 * task 路由意图识别。
 */
function detectIntent(input: AgentRouteInput): RouteIntentResult {
  void input;
  return { confidence: 0, reason: 'task route intent is decided by AI router only' };
}

/**
 * 提取任务标题与截止时间槽位。
 */
function extractSlots(input: AgentRouteInput): SlotExtraction {
  void input;
  return { filled: {} };
}

/**
 * 生成任务确认文案。
 */
function buildConfirmation(state: SessionState): ConfirmationPayload {
  const title = state.slots.taskTitle?.value ?? '未命名任务';
  const dueTime = state.slots.dueTime?.value;
  return {
    prompt: dueTime
      ? `确认创建任务「${title}」，截止 ${dueTime}？`
      : `确认创建任务「${title}」？`,
    summary: dueTime ? `任务：${title}；截止：${dueTime}` : `任务：${title}`,
    confirmLabel: '确认创建',
    denyLabel: '我再改改',
  };
}

/**
 * 在任务标题具备时构造任务执行请求。
 */
function buildExecutionRequest(state: SessionState, input: AgentRouteInput): ExecutionRequest | null {
  const taskTitle = state.slots.taskTitle?.value;
  if (!taskTitle) {
    return null;
  }

  return {
    requestKey: `${state.sessionId}:${input.messageId}:task`,
    route: 'task',
    action: 'task_create',
    payload: {
      taskTitle,
      dueTime: state.slots.dueTime?.value,
      timezone: input.clientContext?.timezone ?? 'Asia/Shanghai',
    },
  };
}

export const taskRoute: RoutePlugin = {
  id: 'task',
  description: 'Task and TODO management.',
  requiredSlots: ['taskTitle'],
  detectIntent,
  extractSlots,
  // 根据缺失槽位返回追问文案。
  buildSlotPrompt(missing) {
    if (missing.includes('taskTitle')) {
      return '这个待办任务要做什么？';
    }
    return '请补充任务信息。';
  },
  // 当任务标题存在时需要用户确认。
  needsConfirmation(state) {
    return Boolean(state.slots.taskTitle?.value);
  },
  buildConfirmation,
  buildExecutionRequest,
  // 生成任务完成态文案。
  buildCompletedMessage(state: SessionState): string {
    return `任务已创建：${state.slots.taskTitle?.value ?? '未命名任务'}`;
  },
};
