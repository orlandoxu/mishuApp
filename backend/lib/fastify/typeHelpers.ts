import type { FastifyRequest as FastifyRequestType } from "fastify";
import type { z, ZodTypeAny } from "zod";

/**
 * TypedRequest<Schema>
 * 自动推导 FastifyRequest.body 的类型
 */
export type TypedRequest<Schema extends ZodTypeAny> = FastifyRequestType<{
  Body: z.infer<Schema>;
}>;

export type SchemaCarrier = {
  __schema__?: Record<string, unknown>;
};

export function hasSchemaDecorator(fn: unknown): fn is SchemaCarrier {
  return typeof fn === "function" && !!(fn as SchemaCarrier).__schema__;
}

export function getMethodSchema(fn: unknown): Record<string, unknown> | null {
  if (!hasSchemaDecorator(fn)) {
    return null;
  }
  return fn.__schema__ ?? null;
}
