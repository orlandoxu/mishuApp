import type { FastifyReply, FastifyRequest } from 'fastify';
import { ASSERT, Ret } from '../common/error.js';
import { UserTokenService } from '../service/userTokenService.js';

export async function loginMiddleware(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  if (request.routeOptions.config?.noAuth) {
    return;
  }

  const body = (request.body ?? {}) as Record<string, unknown>;
  const query = (request.query ?? {}) as Record<string, unknown>;
  const authHeader = request.headers.authorization;
  const token =
    (typeof body.token === 'string' ? body.token : undefined) ??
    (typeof query.token === 'string' ? query.token : undefined) ??
    authHeader;

  ASSERT(token, '未登录', Ret.NotLogin);

  const user = UserTokenService.ensureLastUserRedis(token);
  ASSERT(user, '未登录', Ret.NotLogin);
  ASSERT(user.status !== 'ban', '用户已经被禁用', Ret.UserBaned);

  request.user = user;
}
