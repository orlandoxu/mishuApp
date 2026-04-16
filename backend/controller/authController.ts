import { ASSERT, Ret } from '../common/error';
import { AppAuthService } from '../service/appAuthService';
import { UserTokenService } from '../service/userTokenService';

type MockLoginPayload = Awaited<ReturnType<typeof UserTokenService.mockLogin>>;
type MePayload = { user: NonNullable<FastifyRequest['user']> };
type AppLoginPayload = Awaited<ReturnType<typeof AppAuthService.login>>;

export class AuthController {
  static async register(request: FastifyRequest): Promise<ApiResponse<AppLoginPayload>> {
    const body = (request.body ?? {}) as Record<string, unknown>;
    const mobile = typeof body.mobile === 'string' ? body.mobile : undefined;
    const nickname = typeof body.nickname === 'string' ? body.nickname : undefined;
    const userId = typeof body.userId === 'string' ? body.userId : undefined;
    const result = await AppAuthService.register({ mobile, nickname, userId });
    return ok(result);
  }

  static async login(request: FastifyRequest): Promise<ApiResponse<AppLoginPayload>> {
    const body = (request.body ?? {}) as Record<string, unknown>;
    const mobile = typeof body.mobile === 'string' ? body.mobile : undefined;
    const userId = typeof body.userId === 'string' ? body.userId : undefined;
    const result = await AppAuthService.login({ mobile, userId });
    return ok(result);
  }

  static async requestCode(_request: FastifyRequest): Promise<ApiResponse<Record<string, never>>> {
    // 验证码通道后续可接短信服务，当前只保留成功响应以保证 App 流程连通。
    return ok({});
  }

  static async loginByCode(request: FastifyRequest): Promise<ApiResponse<AppLoginPayload>> {
    const body = (request.body ?? {}) as Record<string, unknown>;
    const mobile = typeof body.mobile === 'string' ? body.mobile : undefined;
    const code = typeof body.code === 'string' ? body.code : undefined;
    const userId = typeof body.userId === 'string' ? body.userId : undefined;
    const result = await AppAuthService.verifyCodeLogin({ mobile, code, userId });
    return ok(result);
  }

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

  static async appGetInfo(request: FastifyRequest): Promise<ApiResponse<ReturnType<typeof AppAuthService.buildProfile>>> {
    ASSERT(request.user, '未登录', Ret.NotLogin);
    return ok(AppAuthService.buildProfile(request.user));
  }

  static async appLogout(_request: FastifyRequest): Promise<ApiResponse<Record<string, never>>> {
    return ok({});
  }
}
