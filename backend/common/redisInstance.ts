import RedisAsync from '../lib/redisAsync';
import { config } from '../config/config';

export const redis = new RedisAsync(config.redis);
