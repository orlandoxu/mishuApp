import crypto from 'node:crypto';
import { ASSERT, Ret } from '../common/error';
import { issueToken } from '../lib/tokenStore';
import type { AuthUser } from '../config/config';
import { SmsService } from './smsService';

export type LoginPayload = {
  token: string;
  userId: string;
};

export type AppUserProfile = {
  userId: string;
};

function normalize(value: string | undefined): string {
  return (value ?? '').trim();
}

function resolveUserIdByMobile(mobile?: string): string {
  const normalizedMobile = normalize(mobile).replace(/\s+/g, '');
  if (normalizedMobile) {
    return `u_${normalizedMobile}`;
  }
  return `u_${crypto.randomUUID().replaceAll('-', '')}`;
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
    const code = normalize(args.code);
    const verifyResult = await SmsService.verifyCode(mobile, code);
    ASSERT(verifyResult.ok, verifyResult.message, verifyResult.code ?? Ret.ERROR);
    return buildTokenPayload(resolveUserIdByMobile(mobile));
  }

  static buildProfile(user: AuthUser): AppUserProfile {
    return {
      userId: user.id,
    };
  }
}
