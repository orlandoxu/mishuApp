import { ASSERT, Ret } from '../common/error';
import { UserTokenService } from '../service/userTokenService';

export async function loginMiddleware(request: FastifyRequest, _reply: FastifyReply): Promise<void> {
  if (request.routeOptions.config?.noAuth) {
    return;
  }

  const body = (request.body ?? {}) as Record<string, unknown>;
  const query = (request.query ?? {}) as Record<string, unknown>;
  const authHeader = request.headers.authorization;
  const rawToken =
    (typeof body.token === 'string' ? body.token : undefined) ??
    (typeof query.token === 'string' ? query.token : undefined) ??
    authHeader;
  const token = typeof rawToken === 'string' ? rawToken : null;

  ASSERT(token, '未登录', Ret.NotLogin);

  const user = await UserTokenService.ensureUserByToken(token);
  ASSERT(user, '未登录', Ret.NotLogin);

  request.user = user;
}
