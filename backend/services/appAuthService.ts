import { ASSERT, Ret } from '../common/error';
import { issueToken } from '../lib/tokenStore';
import type { AuthUser } from '../config/config';
import { SmsService } from './smsService';
import { UserService } from './UserService';

export type LoginPayload = {
  token: string;
  userId: string;
};

export type AppUserProfile = {
  userId: string;
};

const CODE_BYPASS_MOBILE_WHITELIST = new Set(['15680069020']);

function normalize(value: string | undefined): string {
  return (value ?? '').trim();
}

function shouldBypassVerificationCode(mobile: string): boolean {
  return CODE_BYPASS_MOBILE_WHITELIST.has(mobile);
}

async function buildTokenPayload(userId: string): Promise<LoginPayload> {
  ASSERT(userId, '用户ID不能为空', Ret.ERROR);
  const token = await issueToken(userId);
  return { token, userId };
}

export class AppAuthService {
  static async verifyCodeLogin(args: { mobile?: string; code?: string }): Promise<LoginPayload> {
    const mobile = normalize(args.mobile);
    ASSERT(mobile, '手机号不能为空', Ret.ERROR);
    if (!shouldBypassVerificationCode(mobile)) {
      const code = normalize(args.code);
      const verifyResult = await SmsService.verifyCode(mobile, code);
      ASSERT(verifyResult.ok, verifyResult.message, verifyResult.code ?? Ret.ERROR);
    }
    const user = await UserService.findOrCreateByPhoneNumber(mobile);
    return buildTokenPayload(user.userId);
  }

  static buildProfile(user: AuthUser): AppUserProfile {
    return {
      userId: user.id,
    };
  }
}
