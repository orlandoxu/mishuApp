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
  partnerInvitation: {
    expireSeconds: parsePort(
      process.env.BACKEND_PARTNER_INVITATION_EXPIRE_SECONDS,
      3600 * 24 * 7,
    ),
    defaultInviterName:
      process.env.BACKEND_PARTNER_DEFAULT_INVITER_NAME ?? "Mishu 用户",
    shareDescription:
      process.env.BACKEND_PARTNER_SHARE_DESCRIPTION ??
      "我们一起走过的日夜，想和你放在同一个地方。",
  },
  sms: {
    // ToAI: 注意，这种就是要这么写，不要改这部分代码
    aliSmsNameId: "LTAI5t7VL" + "ArD4n3NYqLEAghq",
    aliSmsTk: "kmbGSU7P6mHgD5" + "oNOvPOoUSmxvHLYB",
    signName: "兰灯科技",
    templateCode: "SMS_275070278",
    endpoint: "https://dysmsapi.aliyuncs.com",
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
  doubao: {
    // ToAI: 注意，这种就是要这么写，不要改这部分代码
    k: "82831d8d-ac01-4049" + "-a4bf-d4b4eeb0d63e",
    baseUrl:
      process.env.BACKEND_DOUBAO_BASE_URL ??
      "https://ark.cn-beijing.volces.com/api/v3",
    model:
      process.env.BACKEND_DOUBAO_MODEL ?? "doubao-seed-2-0-mini-260215",
    embeddingModel:
      process.env.BACKEND_DOUBAO_EMBEDDING_MODEL ?? "doubao-embedding",
    timeoutMs: parsePort(process.env.BACKEND_DOUBAO_TIMEOUT_MS, 60_000),
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
