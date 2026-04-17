import { z } from "zod";
import { ASSERT, Ret } from "../common/error";
import { BodySchema } from "../lib/fastify/bodySchema";
import { TypedRequest } from "../lib/fastify/typeHelpers";
import { AppAuthService } from "../services/appAuthService";
import { SmsService } from "../services/smsService";

type MePayload = { user: NonNullable<FastifyRequest["user"]> };
type AppLoginPayload = Awaited<
  ReturnType<typeof AppAuthService.verifyCodeLogin>
>;

export class AuthController {
  static requestCodeType = z.object({
    mobile: z
      .string()
      .trim()
      .min(1, "手机号不能为空")
      .describe("手机号（国际格式）"),
  });

  @BodySchema(AuthController.requestCodeType)
  static async requestCode(
    request: TypedRequest<typeof AuthController.requestCodeType>,
  ): Promise<ApiResponse<Record<string, never>>> {
    const result = await SmsService.sendVerificationCode(request.body.mobile);
    ASSERT(result.ok, result.message, result.code ?? Ret.ERROR);
    return ok({});
  }

  static loginByCodeType = z.object({
    mobile: z
      .string()
      .trim()
      .min(1, "手机号不能为空")
      .describe("手机号（国际格式）"),
    code: z.string().trim().min(4, "验证码长度不正确").describe("验证码"),
  });

  // DONE-AI: 登录已接入短信验证码校验逻辑（Redis 存取 + 阿里云短信发送）。
  @BodySchema(AuthController.loginByCodeType)
  static async loginByCode(
    request: TypedRequest<typeof AuthController.loginByCodeType>,
  ): Promise<ApiResponse<AppLoginPayload>> {
    const { mobile, code } = request.body;
    const result = await AppAuthService.verifyCodeLogin({ mobile, code });
    return ok(result);
  }

  static async me(request: FastifyRequest): Promise<ApiResponse<MePayload>> {
    ASSERT(request.user, "未登录", Ret.NotLogin);
    return ok({ user: request.user });
  }

  static async appGetInfo(
    request: FastifyRequest,
  ): Promise<ApiResponse<ReturnType<typeof AppAuthService.buildProfile>>> {
    ASSERT(request.user, "未登录", Ret.NotLogin);
    return ok(AppAuthService.buildProfile(request.user));
  }

  static async appLogout(
    _request: FastifyRequest,
  ): Promise<ApiResponse<Record<string, never>>> {
    return ok({});
  }
}
