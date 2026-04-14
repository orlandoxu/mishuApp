import crypto from 'node:crypto';
import { config, type RedisUser } from '../config/config.js';

type SessionRecord = {
  user: RedisUser;
  expireAt: number;
};

const tokenStore = new Map<string, SessionRecord>();

function nowMs(): number {
  return Date.now();
}

export function issueToken(user: RedisUser): string {
  const raw = `${user.id}:${crypto.randomUUID()}`;
  const token = `${config.auth.tokenPrefix}${Buffer.from(raw).toString('base64url')}`;
  tokenStore.set(token, {
    user,
    expireAt: nowMs() + config.auth.tokenExpireSeconds * 1000,
  });
  return token;
}

export function loadUserByToken(token: string): RedisUser | null {
  const record = tokenStore.get(token);
  if (!record) {
    return null;
  }

  if (record.expireAt <= nowMs()) {
    tokenStore.delete(token);
    return null;
  }

  return record.user;
}
