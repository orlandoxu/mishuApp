import type { RedisUser } from '../config/config';

declare module 'fastify' {
  interface FastifyRequest {
    user?: RedisUser;
    logStart?: bigint;
  }

  interface FastifyContextConfig {
    noAuth?: boolean;
  }
}
