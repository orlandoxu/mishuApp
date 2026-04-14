import type { FastifyReply, FastifyRequest } from 'fastify';
import { REPLY } from '../common/error.js';
import { InfraHealthService } from '../service/infraHealthService.js';

export class HealthController {
  static async health(_request: FastifyRequest, _reply: FastifyReply): Promise<never> {
    const dependencies = await InfraHealthService.checkDependencies();

    REPLY({
      status: 'ok',
      uptimeSeconds: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
      dependencies,
    });
  }
}
