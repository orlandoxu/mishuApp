import type { RouteExecutor } from './types';

/**
 * 简单延迟函数，用于 demo 模拟异步外部调用。
 */
function wait(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

export const reminderExecutor: RouteExecutor = {
  // 执行提醒创建动作（示例实现）。
  async execute(request) {
    await wait(20);
    return {
      success: true,
      summary: 'reminder created',
      data: {
        reminderId: `rem_${Date.now()}`,
        ...request.payload,
      },
    };
  },
};

export const contactExecutor: RouteExecutor = {
  // 执行联系人动作（示例实现）。
  async execute(request) {
    await wait(20);
    return {
      success: true,
      summary: 'contact action queued',
      data: {
        ticketId: `contact_${Date.now()}`,
        ...request.payload,
      },
    };
  },
};

export const taskExecutor: RouteExecutor = {
  // 执行任务创建动作（示例实现）。
  async execute(request) {
    await wait(20);
    return {
      success: true,
      summary: 'task created',
      data: {
        taskId: `task_${Date.now()}`,
        ...request.payload,
      },
    };
  },
};
