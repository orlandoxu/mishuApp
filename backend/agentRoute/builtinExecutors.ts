import { DoubaoService } from '../services/doubaoService';
import type { RouteExecutor } from './types';

function buildClientActionRequest(request: { idempotencyKey: string; action: string; payload: Record<string, unknown>; reason?: string }) {
  return {
    requestId: request.idempotencyKey,
    action: request.action,
    payload: request.payload,
    reason: request.reason,
  };
}

export const moneyExecutor: RouteExecutor = {
  async execute(request) {
    return {
      success: true,
      summary: '已下发本地账本动作，等待客户端执行。',
      requestClientAction: buildClientActionRequest({
        idempotencyKey: request.idempotencyKey,
        action: request.action,
        payload: request.payload,
        reason: '账本主存储在 iOS 本地，需由客户端执行读写。',
      }),
    };
  },
};

export const chatExecutor: RouteExecutor = {
  async execute(request) {
    const userText = typeof request.payload.userText === 'string' ? request.payload.userText : '';
    const historyText = typeof request.payload.historyText === 'string' ? request.payload.historyText : '';

    try {
      const completion = await DoubaoService.chatCompletion({
        temperature: 0.3,
        messages: [
          { role: 'system', content: '你是 Mishu App 的家庭助手，请用简洁中文回复。' },
          { role: 'user', content: `历史对话:\n${historyText}\n\n用户输入:\n${userText}` },
        ],
      });

      return {
        success: true,
        summary: completion.content.trim() || '我在，继续说。',
        data: { reply: completion.content.trim() || '我在，继续说。' },
      };
    } catch (error) {
      return {
        success: false,
        summary: `聊天调用失败：${error instanceof Error ? error.message : 'unknown'}`,
        retryable: true,
        errorCode: 'CHAT_EXECUTION_FAILED',
      };
    }
  },
};

export const reminderExecutor: RouteExecutor = {
  async execute() {
    return {
      success: false,
      summary: '提醒能力尚未接入生产执行器。',
      retryable: false,
      errorCode: 'NOT_IMPLEMENTED',
    };
  },
};

export const contactExecutor: RouteExecutor = {
  async execute() {
    return {
      success: false,
      summary: '联系人能力尚未接入生产执行器。',
      retryable: false,
      errorCode: 'NOT_IMPLEMENTED',
    };
  },
};

export const taskExecutor: RouteExecutor = {
  async execute() {
    return {
      success: false,
      summary: '任务能力尚未接入生产执行器。',
      retryable: false,
      errorCode: 'NOT_IMPLEMENTED',
    };
  },
};
