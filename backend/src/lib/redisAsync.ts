import RedisImport, { type RedisKey } from 'ioredis';
import type { RedisNodeConfig } from '../config/config.js';

type RedisClient = {
  ping(): Promise<string>;
  set(key: RedisKey, value: string, mode?: 'EX', ttl?: number): Promise<'OK' | null>;
  get(key: RedisKey): Promise<string | null>;
  expire(key: RedisKey, ttl: number): Promise<number>;
  del(key: RedisKey): Promise<number>;
};

export default class RedisAsync {
  private readonly client: RedisClient;

  constructor(redisConfig: RedisNodeConfig[] | RedisNodeConfig) {
    const node = Array.isArray(redisConfig) ? redisConfig[0] : redisConfig;
    const RedisCtor = RedisImport as unknown as new (options: RedisNodeConfig) => RedisClient;
    this.client = new RedisCtor(node);
  }

  async ping(): Promise<string> {
    return this.client.ping();
  }

  async set(key: RedisKey, value: string, ttl = 0): Promise<boolean> {
    const ret = ttl
      ? await this.client.set(key, value, 'EX', ttl)
      : await this.client.set(key, value);
    return ret === 'OK';
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
