import type { AuthUser } from '../config/config';

declare module 'fastify' {
  interface FastifyRequest {
    user?: AuthUser;
    logStart?: bigint;
  }
}
