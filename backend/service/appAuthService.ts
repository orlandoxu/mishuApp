import crypto from 'node:crypto';
import { ASSERT, Ret } from '../common/error';
import { issueToken } from '../lib/tokenStore';
import type { AuthUser } from '../config/config';

export type LoginPayload = {
  token: string;
  userId: string;
};

export type AppUserProfile = {
  userId: string;
};

type RegisterArgs = {
  mobile?: string;
  nickname?: string;
  userId?: string;
};

type LoginArgs = {
  mobile?: string;
  userId?: string;
};

function normalize(value: string | undefined): string {
  return (value ?? '').trim();
}

function resolveUserId(input: { userId?: string; mobile?: string; nickname?: string }): string {
  const userId = normalize(input.userId);
  if (userId) {
    return userId;
  }

  const mobile = normalize(input.mobile).replace(/\s+/g, '');
  if (mobile) {
    return `u_${mobile}`;
  }

  const nickname = normalize(input.nickname);
  if (nickname) {
    return `u_${nickname}`;
  }

  return `u_${crypto.randomUUID().replaceAll('-', '')}`;
}

async function buildTokenPayload(userId: string): Promise<LoginPayload> {
  ASSERT(userId, '用户ID不能为空', Ret.ERROR);
  const token = await issueToken(userId);
  return { token, userId };
}

export class AppAuthService {
  static async register(args: RegisterArgs): Promise<LoginPayload> {
    return buildTokenPayload(resolveUserId(args));
  }

  static async login(args: LoginArgs): Promise<LoginPayload> {
    return buildTokenPayload(resolveUserId(args));
  }

  static async verifyCodeLogin(args: { mobile?: string; code?: string; userId?: string }): Promise<LoginPayload> {
    const code = normalize(args.code);
    ASSERT(/^\d{4,8}$/.test(code), '验证码格式不正确', Ret.ERROR);
    return buildTokenPayload(resolveUserId(args));
  }

  static buildProfile(user: AuthUser): AppUserProfile {
    return {
      userId: user.id,
    };
  }
}
