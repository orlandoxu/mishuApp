import type { FastifyReply, FastifyRequest } from 'fastify';
import { REPLY } from '../common/error.js';

export class HealthController {
  static async health(_request: FastifyRequest, _reply: FastifyReply): Promise<never> {
    REPLY({
      status: 'ok',
      uptimeSeconds: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    });
  }
}
