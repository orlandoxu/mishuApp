import RedisAsync from '../lib/redisAsync.js';
import { config } from '../config/config.js';

export const redis = new RedisAsync(config.redis);
