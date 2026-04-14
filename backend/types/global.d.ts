import type { FastifyReply as FastifyReplyType, FastifyRequest as FastifyRequestType } from 'fastify';

declare global {
  type ApiResponse<T> = {
    ret: number;
    msg: string;
    data: T;
  };

  const ok: <T>(data: T, msg?: string, ret?: number) => ApiResponse<T>;

  interface GlobalThis {
    ok: typeof ok;
  }

  type FastifyRequest = FastifyRequestType;
  type FastifyReply = FastifyReplyType;
}

export {};
