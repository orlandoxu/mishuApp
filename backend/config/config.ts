import path from "node:path";

// DONE-AI: 用户鉴权上下文已改为与 Redis 解耦的 AuthUser。
export interface AuthUser {
  id: string;
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

  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

export const config = {
  app: {
    host: process.env.BACKEND_HOST ?? "0.0.0.0",
    port: parsePort(process.env.BACKEND_PORT, 3000),
    nodeEnv: process.env.NODE_ENV ?? "development",
  },
  ws: {
    path: process.env.BACKEND_WS_PATH ?? "/house",
    wsEnabled: parseBool(process.env.BACKEND_WS_ENABLED, true),
    wsHost: process.env.BACKEND_WS_HOST ?? "0.0.0.0",
    wsPort: parsePort(process.env.BACKEND_WS_PORT, 3001),
  },
  auth: {
    tokenPrefix: "tk-",
    tokenExpireSeconds: 3600 * 24 * 7,
    jwtSecret:
      process.env.BACKEND_JWT_SECRET ?? "mishu-dev-jwt-secret-change-me",
  },
  sms: {
    accessKeyId:
      process.env.BACKEND_ALIYUN_ACCESS_KEY_ID ??
      process.env.ALIYUN_ACCESS_KEY_ID ??
      "DUMMY_ALIYUN_ACCESS_KEY_ID",
    accessKeySecret:
      process.env.BACKEND_ALIYUN_ACCESS_KEY_SECRET ??
      process.env.ALIYUN_ACCESS_KEY_SECRET ??
      "DUMMY_ALIYUN_ACCESS_KEY_SECRET",
    signName:
      process.env.BACKEND_ALIYUN_SMS_SIGN_NAME ??
      process.env.ALIYUN_SMS_SIGN_NAME ??
      "兰灯科技",
    templateCode:
      process.env.BACKEND_ALIYUN_SMS_TEMPLATE_CODE ??
      process.env.ALIYUN_SMS_TEMPLATE_CODE ??
      "SMS_275070278",
    endpoint:
      process.env.BACKEND_ALIYUN_SMS_ENDPOINT ??
      process.env.ALIYUN_SMS_ENDPOINT ??
      "https://dysmsapi.aliyuncs.com",
    codeTtlSeconds: parsePort(process.env.BACKEND_SMS_CODE_TTL, 300),
    rateLimitSeconds: parsePort(process.env.BACKEND_SMS_RATE_LIMIT, 60),
  },
  redisKey: {
    userVersion: { key: "tkv-" },
    loginToken: { key: "", expire: 3600 * 24 * 7 },
    userPermission: { key: "user-p-", expire: 10 * 60 },
    userProjectPermission: { key: "user-pp-", expire: 10 * 60 },
    userInProject: { key: "user-in-p-", expire: 30 * 60 },
    projectIndependent: { key: "pj-i-", expire: 30 * 60 },
    userIsProjectOwner: { key: "pj-isOwner-", expire: 30 * 60 },
    projectUsers: { key: "pj-u-", expire: 30 * 60 },
  },
  inMemoryKey: {
    pNoId2pId: "in-pNoId2pId-",
    pId2pNoId: "in-pId2pNoId-",
    uId2uNoId: "in-uId2uNoId-",
    uNoId2uId: "in-uNoId2uId-",
  },
  yjs: {
    storePath: path.resolve(process.cwd(), "docs"),
  },
  domain: {
    api: process.env.BACKEND_API_DOMAIN ?? "http://localhost:3000",
    web: process.env.BACKEND_WEB_DOMAIN ?? "http://localhost:8200",
  },
  mongodb: {
    HOST: process.env.BACKEND_MONGO_HOST ?? "47.119.165.152:27017",
    USER: process.env.BACKEND_MONGO_USER ?? "bun",
    PASSWD: process.env.BACKEND_MONGO_PASSWD ?? "bunReal839923",
    DATABASE: process.env.BACKEND_MONGO_DATABASE ?? "bun",
    AUTHSOURCE: process.env.BACKEND_MONGO_AUTHSOURCE ?? "admin",
    REPLICASET: process.env.BACKEND_MONGO_REPLICASET ?? "",
  },
  redis: [
    {
      host:
        process.env.BACKEND_REDIS_HOST ?? "experiment.redis.rds.aliyuncs.com",
      port: parsePort(process.env.BACKEND_REDIS_PORT, 6379),
      username: process.env.BACKEND_REDIS_USERNAME ?? "experiment",
      password: process.env.BACKEND_REDIS_PASSWORD ?? "bunReal839923",
      db: parseDb(process.env.BACKEND_REDIS_DB, 16),
    },
  ] as RedisNodeConfig[],
};

export type AppConfig = typeof config;
