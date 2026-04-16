import { config } from '../config/config';
import { redis } from '../common/redisInstance';
import {
  mapAliyunSmsError,
  sendVerificationCodeSms,
} from '../lib/aliyunSmsClient';

type SmsResult = {
  ok: boolean;
  message: string;
  code?: number;
};

function normalizeMobile(mobile: string): string {
  return mobile.trim().replace(/\s+/g, '');
}

function normalizeMainlandMobile(raw: string): string | null {
  const compact = normalizeMobile(raw).replace(/^(\+86|0086|86)/, '');
  if (!/^1[3-9]\d{9}$/.test(compact)) {
    return null;
  }
  return compact;
}

function buildCode(): string {
  return String(Math.floor(100_000 + Math.random() * 900_000));
}

export class SmsService {
  static async sendVerificationCode(rawMobile: string): Promise<SmsResult> {
    const mobile = normalizeMainlandMobile(rawMobile);
    if (!mobile) {
      return { ok: false, message: '仅支持中国大陆手机号', code: 400 };
    }

    const rateLimitKey = `sms:rate_limit:${mobile}`;
    const rateLimited = await redis
      .get(rateLimitKey)
      .then(Boolean)
      .catch(() => false);

    if (rateLimited) {
      return { ok: false, message: '发送过于频繁，请稍后再试', code: 429 };
    }

    const code = buildCode();
    const smsResult = await sendVerificationCodeSms({
      phoneNumber: mobile,
      code,
    });

    if (!smsResult.success) {
      return {
        ok: false,
        message: mapAliyunSmsError(smsResult.code) || smsResult.message,
        code: 400,
      };
    }

    const codeKey = `sms:code:${mobile}`;
    const codeStored = await redis
      .set(codeKey, code, config.sms.codeTtlSeconds)
      .catch(() => false);
    if (!codeStored) {
      return { ok: false, message: '验证码存储失败', code: 500 };
    }

    await redis
      .set(rateLimitKey, '1', config.sms.rateLimitSeconds)
      .catch(() => false);

    return { ok: true, message: '验证码发送成功' };
  }

  static async verifyCode(rawMobile: string, rawCode: string): Promise<SmsResult> {
    const mobile = normalizeMainlandMobile(rawMobile);
    const code = rawCode.trim();
    if (!mobile) {
      return { ok: false, message: '仅支持中国大陆手机号', code: 400 };
    }
    if (!/^\d{4,8}$/.test(code)) {
      return { ok: false, message: '验证码格式不正确', code: 400 };
    }

    const codeKey = `sms:code:${mobile}`;
    const storedCode = await redis.get(codeKey).catch(() => null);
    if (!storedCode) {
      return { ok: false, message: '验证码已过期或不存在', code: 400 };
    }
    if (storedCode !== code) {
      return { ok: false, message: '验证码错误', code: 400 };
    }

    await redis.del(codeKey).catch(() => 0);
    return { ok: true, message: '验证码验证成功' };
  }
}
