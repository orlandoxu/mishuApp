import type { FastifyReply, FastifyRequest } from 'fastify';
import { ASSERT, REPLY } from '../common/error.js';
import { UserTokenService } from '../service/userTokenService.js';

export class AuthController {
  static async mockLogin(request: FastifyRequest, _reply: FastifyReply): Promise<never> {
    const body = (request.body ?? {}) as Record<string, unknown>;
    const name = typeof body.name === 'string' && body.name.trim() ? body.name.trim() : 'demo';

    const result = UserTokenService.mockLogin(name);
    REPLY(result);
  }

  static async me(request: FastifyRequest, _reply: FastifyReply): Promise<never> {
    ASSERT(request.user, '未登录', 401);
    REPLY({ user: request.user });
  }
}
