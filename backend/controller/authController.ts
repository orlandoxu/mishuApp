import { ASSERT, Ret } from '../common/error';
import { UserTokenService } from '../service/userTokenService';

type MockLoginPayload = Awaited<ReturnType<typeof UserTokenService.mockLogin>>;
type MePayload = { user: NonNullable<FastifyRequest['user']> };

export class AuthController {
  static async mockLogin(request: FastifyRequest): Promise<ApiResponse<MockLoginPayload>> {
    const body = (request.body ?? {}) as Record<string, unknown>;
    const name = typeof body.name === 'string' && body.name.trim() ? body.name.trim() : 'demo';

    const result = await UserTokenService.mockLogin(name);
    return ok(result);
  }

  static async me(request: FastifyRequest): Promise<ApiResponse<MePayload>> {
    ASSERT(request.user, '未登录', Ret.NotLogin);
    return ok({ user: request.user });
  }
}
