import crypto from 'node:crypto';
import { config, type RedisUser } from '../config/config.js';
import { redis } from '../common/redisInstance.js';

const TOKEN_EXPIRE = config.redisKey.loginToken.expire;

function nowMs(): number {
  return Date.now();
}

function normalizeUser(payload: Partial<RedisUser>): RedisUser {
  return {
    id: payload.id ?? '',
    noId: payload.noId ?? 0,
    realName: payload.realName ?? '',
    company: payload.company ?? '',
    status: payload.status === 'ban' ? 'ban' : 'active',
    iVer: payload.iVer ?? 1,
    sVer: payload.sVer ?? 1,
    v: payload.v ?? 1,
  };
}

export async function issueToken(user: RedisUser): Promise<string> {
  const raw = `${user.id}:${crypto.randomUUID()}:${nowMs()}`;
  const token = `${config.auth.tokenPrefix}${Buffer.from(raw).toString('base64url')}`;
  await redis.set(token, JSON.stringify(user), TOKEN_EXPIRE);
  return token;
}

export async function loadUserByToken(token: string): Promise<RedisUser | null> {
  const payload = await redis.get(token, TOKEN_EXPIRE);
  if (!payload) {
    return null;
  }

  try {
    const parsed = JSON.parse(payload) as Partial<RedisUser>;
    return normalizeUser(parsed);
  } catch {
    return null;
  }
}
