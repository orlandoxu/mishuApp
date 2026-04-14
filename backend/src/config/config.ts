export interface RedisUser {
  id: string;
  noId: number;
  realName: string;
  company: string;
  status: 'active' | 'ban';
  iVer: number;
  sVer: number;
  v: number;
}

function parsePort(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }

  return parsed;
}

export const config = {
  app: {
    host: process.env.BACKEND_HOST ?? '0.0.0.0',
    port: parsePort(process.env.BACKEND_PORT, 3000),
    nodeEnv: process.env.NODE_ENV ?? 'development',
  },
  auth: {
    tokenPrefix: 'tk-',
    tokenExpireSeconds: 3600 * 24 * 7,
  },
};
