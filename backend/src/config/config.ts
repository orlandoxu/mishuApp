import path from 'node:path';

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

export type RedisNodeConfig = {
  host: string;
  port: number;
  username: string;
  password: string;
  db: number;
};

function parsePort(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return fallback;
  }

  return parsed;
}

function parseDb(value: string | undefined, fallback: number): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    return fallback;
  }

  return parsed;
}

function parseBool(value: string | undefined, fallback: boolean): boolean {
  if (value === undefined) {
    return fallback;
  }

  return ['1', 'true', 'yes', 'on'].includes(value.toLowerCase());
}

export const config = {
  app: {
    host: process.env.BACKEND_HOST ?? '0.0.0.0',
    port: parsePort(process.env.BACKEND_PORT, 3000),
    nodeEnv: process.env.NODE_ENV ?? 'development',
  },
  ws: {
    path: process.env.BACKEND_WS_PATH ?? '/house',
    wssEnabled: parseBool(process.env.BACKEND_WSS_ENABLED, true),
    wssHost: process.env.BACKEND_WSS_HOST ?? '0.0.0.0',
    wssPort: parsePort(process.env.BACKEND_WSS_PORT, 3100),
    wssKeyPath:
      process.env.BACKEND_WSS_KEY_PATH ?? path.resolve(process.cwd(), '../SDao/cert/local/landeng.fun.key'),
    wssCertPath:
      process.env.BACKEND_WSS_CERT_PATH ?? path.resolve(process.cwd(), '../SDao/cert/local/landeng.fun.pem'),
  },
  auth: {
    tokenPrefix: 'tk-',
    tokenExpireSeconds: 3600 * 24 * 7,
  },
  redisKey: {
    userVersion: { key: 'tkv-' },
    loginToken: { key: '', expire: 3600 * 24 * 7 },
    userPermission: { key: 'user-p-', expire: 10 * 60 },
    userProjectPermission: { key: 'user-pp-', expire: 10 * 60 },
    userInProject: { key: 'user-in-p-', expire: 30 * 60 },
    projectIndependent: { key: 'pj-i-', expire: 30 * 60 },
    userIsProjectOwner: { key: 'pj-isOwner-', expire: 30 * 60 },
    projectUsers: { key: 'pj-u-', expire: 30 * 60 },
  },
  inMemoryKey: {
    pNoId2pId: 'in-pNoId2pId-',
    pId2pNoId: 'in-pId2pNoId-',
    uId2uNoId: 'in-uId2uNoId-',
    uNoId2uId: 'in-uNoId2uId-',
  },
  yjs: {
    storePath: path.resolve(process.cwd(), 'docs'),
  },
  domain: {
    api: process.env.BACKEND_API_DOMAIN ?? 'http://localhost:3000',
    web: process.env.BACKEND_WEB_DOMAIN ?? 'http://localhost:8200',
  },
  mongodb: {
    HOST: process.env.BACKEND_MONGO_HOST ?? '47.119.165.152:27017',
    USER: process.env.BACKEND_MONGO_USER ?? 'bun',
    PASSWD: process.env.BACKEND_MONGO_PASSWD ?? 'bunReal839923',
    DATABASE: process.env.BACKEND_MONGO_DATABASE ?? 'bun',
    AUTHSOURCE: process.env.BACKEND_MONGO_AUTHSOURCE ?? 'admin',
    REPLICASET: process.env.BACKEND_MONGO_REPLICASET ?? '',
  },
  redis: [
    {
      host: process.env.BACKEND_REDIS_HOST ?? 'experiment.redis.rds.aliyuncs.com',
      port: parsePort(process.env.BACKEND_REDIS_PORT, 6379),
      username: process.env.BACKEND_REDIS_USERNAME ?? 'experiment',
      password: process.env.BACKEND_REDIS_PASSWORD ?? 'bunReal839923',
      db: parseDb(process.env.BACKEND_REDIS_DB, 16),
    },
  ] as RedisNodeConfig[],
};

export type AppConfig = typeof config;
