import type { ExecutionRequest, ExecutionResult, RouteExecutor, RouteId } from './types';

const DEFAULT_NOT_IMPLEMENTED: ExecutionResult = {
  success: false,
  summary: 'executor is not implemented for this route',
  retryable: false,
  errorCode: 'EXECUTOR_NOT_IMPLEMENTED',
};

export class ExecutionOrchestrator {
  /**
   * 构造执行编排器。
   * 作用：按 route 注入对应执行器，隔离路由决策与业务执行细节。
   */
  constructor(private readonly executors: Partial<Record<RouteId, RouteExecutor>>) {}

  /**
   * 执行路由动作请求；未注册执行器时返回统一未实现错误。
   */
  async execute(request: ExecutionRequest): Promise<ExecutionResult> {
    const executor = this.executors[request.route];
    if (!executor) {
      return DEFAULT_NOT_IMPLEMENTED;
    }

    return executor.execute(request);
  }
}
