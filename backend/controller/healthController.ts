import { InfraHealthService } from '../services/infraHealthService';

// DONE-AI: 删除冗余 HealthPayload 类型，直接让 TypeScript 从 ok(...) 推导返回结构。
export class HealthController {
  static async health(_request: FastifyRequest) {
    const dependencies = await InfraHealthService.checkDependencies();

    return ok({
      status: 'ok' as const,
      uptimeSeconds: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
      dependencies,
    });
  }
}
