import RedisImport, { type RedisKey } from "ioredis";
// DONE-AI: 现在是 Bun + ESNext(Bundler) 方案，源码保持 TS 扩展名无后缀导入即可。
import type { RedisNodeConfig } from "../config/config";

export default class RedisAsync {
  private readonly client: RedisImport;

  constructor(redisConfig: RedisNodeConfig[] | RedisNodeConfig) {
    const node = Array.isArray(redisConfig) ? redisConfig[0] : redisConfig;
    // DONE-AI: 删除中间 RedisClient 类型，直接使用 ioredis 原生类型。
    this.client = new RedisImport(node);
  }

  async ping(): Promise<string> {
    return this.client.ping();
  }

  async set(key: RedisKey, value: string, ttl = 0): Promise<boolean> {
    const ret = ttl
      ? await this.client.set(key, value, "EX", ttl)
      : await this.client.set(key, value);
    return ret === "OK";
  }

  async get(key: RedisKey, ttl = 0): Promise<string | null> {
    const result = await this.client.get(key);
    if (result && ttl > 0) {
      await this.client.expire(key, ttl);
    }
    return result;
  }

  async del(key: RedisKey): Promise<number> {
    return this.client.del(key);
  }
}
