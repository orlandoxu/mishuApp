import crypto from 'node:crypto';
import { config } from '../config/config';

function toBase64Url(value: string): string {
  return Buffer.from(value).toString('base64url');
}

function hmacSignature(raw: string): string {
  return crypto.createHmac('sha256', config.auth.jwtSecret).update(raw).digest('base64url');
}

type JwtPayload = {
  sub: string;
  iat: number;
  exp: number;
};

export async function issueToken(userId: string): Promise<string> {
  const nowSec = Math.floor(Date.now() / 1000);
  const payload: JwtPayload = {
    sub: userId,
    iat: nowSec,
    exp: nowSec + config.auth.tokenExpireSeconds,
  };

  const header = { alg: 'HS256', typ: 'JWT' };
  const headerRaw = toBase64Url(JSON.stringify(header));
  const payloadRaw = toBase64Url(JSON.stringify(payload));
  const raw = `${headerRaw}.${payloadRaw}`;
  const signed = hmacSignature(raw);

  return `${config.auth.tokenPrefix}${raw}.${signed}`;
}
