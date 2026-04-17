import crypto from 'node:crypto';
import { config, type AuthUser } from '../config/config';
import { issueToken } from '../lib/tokenStore';

type JwtPayload = {
  sub: string;
  iat: number;
  exp: number;
};

function hmacSignature(raw: string): string {
  return crypto.createHmac('sha256', config.auth.jwtSecret).update(raw).digest('base64url');
}

function parseJwt(token: string): JwtPayload | null {
  const parts = token.split('.');
  if (parts.length !== 3) {
    return null;
  }

  const [header, payload, signature] = parts;
  const raw = `${header}.${payload}`;
  if (signature !== hmacSignature(raw)) {
    return null;
  }

  let parsedHeader: { alg?: string; typ?: string };
  let parsedPayload: Partial<JwtPayload>;
  try {
    parsedHeader = JSON.parse(Buffer.from(header, 'base64url').toString('utf8')) as {
      alg?: string;
      typ?: string;
    };
    parsedPayload = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as Partial<JwtPayload>;
  } catch {
    return null;
  }

  if (parsedHeader.alg !== 'HS256' || parsedHeader.typ !== 'JWT') {
    return null;
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (
    typeof parsedPayload.sub !== 'string' ||
    typeof parsedPayload.iat !== 'number' ||
    typeof parsedPayload.exp !== 'number' ||
    parsedPayload.exp <= nowSec
  ) {
    return null;
  }

  return {
    sub: parsedPayload.sub,
    iat: parsedPayload.iat,
    exp: parsedPayload.exp,
  };
}

export class UserTokenService {
  static async ensureUserByToken(token: string): Promise<AuthUser | null> {
    if (!token) {
      return null;
    }

    const jwtToken = token.startsWith(config.auth.tokenPrefix)
      ? token.slice(config.auth.tokenPrefix.length)
      : token;
    const payload = parseJwt(jwtToken);
    return payload ? { id: payload.sub } : null;
  }

  static async mockLogin(name: string): Promise<{ token: string; user: AuthUser }> {
    const user: AuthUser = {
      id: `user-${name}`,
    };

    const token = await issueToken(user.id);
    return { token, user };
  }
}
