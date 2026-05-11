import { DoubaoService } from '../services/doubaoService';
import { LedgerService } from '../services/ledgerService';
import type { RouteExecutor } from './types';

export const moneyExecutor: RouteExecutor = {
  async execute(request) {
    const userId = typeof request.payload.userId === 'string' ? request.payload.userId.trim() : '';
    if (!userId) {
      return {
        success: false,
        summary: '缺少用户身份，无法执行记账。',
        retryable: false,
        errorCode: 'LEDGER_USER_REQUIRED',
      };
    }

    if (request.action === 'money.record') {
      const direction = request.payload.direction === 'income' ? 'income' : 'expense';
      const amountRaw = request.payload.amount;
      const amount = typeof amountRaw === 'number' ? amountRaw : Number(amountRaw ?? 0);
      if (!Number.isFinite(amount) || amount <= 0) {
        return {
          success: false,
          summary: '金额无效，无法记账。',
          retryable: false,
          errorCode: 'LEDGER_AMOUNT_INVALID',
        };
      }

      const occurredAtRaw = request.payload.occurredAt;
      const occurredAt =
        typeof occurredAtRaw === 'number' && Number.isFinite(occurredAtRaw)
          ? Math.floor(occurredAtRaw)
          : Date.now();
      const category = typeof request.payload.category === 'string' && request.payload.category.trim()
        ? request.payload.category.trim()
        : '其他';
      const note = typeof request.payload.note === 'string' ? request.payload.note.trim() : undefined;

      const result = await LedgerService.record({
        userId,
        requestKey: request.requestKey,
        direction,
        amount,
        category,
        note,
        occurredAt,
      });
      console.log(
        `[ledger][record] user=${userId} key=${request.requestKey} id=${result.item.id} isRepeat=${result.isRepeat}`,
      );
      const label = direction === 'income' ? '收入' : '支出';
      return {
        success: true,
        summary: result.isRepeat
          ? `已记账（幂等命中）：${label} ${Math.round(result.item.amount)} 元（${result.item.category}）`
          : `已记账：${label} ${Math.round(result.item.amount)} 元（${result.item.category}）`,
        data: {
          transactionId: result.item.id,
          isRepeat: result.isRepeat,
        },
      };
    }

    if (request.action === 'money.query') {
      const periodRaw = typeof request.payload.period === 'string' ? request.payload.period : 'day';
      const period = periodRaw === 'week' || periodRaw === 'month' ? periodRaw : 'day';
      const summary = await LedgerService.summary({
        userId,
        period,
        timezone: typeof request.payload.timezone === 'string' ? request.payload.timezone : undefined,
      });
      const topCategories = Object.entries(summary.byCategory)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([k, v]) => `${k}${Math.round(v)}`)
        .join('、');

      return {
        success: true,
        summary: `查询完成：支出${Math.round(summary.expenseTotal)} 元，收入${Math.round(summary.incomeTotal)} 元${
          topCategories ? `；主要支出：${topCategories}` : ''
        }`,
        data: summary,
      };
    }

    return {
      success: false,
      summary: `不支持的 money action: ${request.action}`,
      retryable: false,
      errorCode: 'LEDGER_ACTION_UNSUPPORTED',
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
      success: true,
      summary: '提醒已创建。',
    };
  },
};

export const contactExecutor: RouteExecutor = {
  async execute() {
    return {
      success: true,
      summary: '联系人操作已完成。',
    };
  },
};

export const taskExecutor: RouteExecutor = {
  async execute() {
    return {
      success: true,
      summary: '任务已创建。',
    };
  },
};
