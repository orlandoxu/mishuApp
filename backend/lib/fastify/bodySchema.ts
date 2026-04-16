import type { ZodTypeAny } from "zod";

type RouteSchemaShape = {
  body?: unknown;
  querystring?: unknown;
  params?: unknown;
  headers?: unknown;
  response?: Record<number, unknown> | unknown;
};

type SchemaAnnotatedMethod = {
  __schema__?: RouteSchemaShape;
  hasSchema?: boolean;
};

/**
 * 方法注解：把 body schema 挂到 controller 方法上，供 route helper 自动识别。
 */
export function BodySchema<TSchema extends ZodTypeAny>(schema: TSchema) {
  return function (
    _target: unknown,
    _key: string,
    descriptor: TypedPropertyDescriptor<(...args: any[]) => any>,
  ): TypedPropertyDescriptor<(...args: any[]) => any> {
    const method = descriptor.value as SchemaAnnotatedMethod | undefined;
    if (!method) {
      return descriptor;
    }

    method.__schema__ = { ...(method.__schema__ ?? {}), body: schema };
    method.hasSchema = true;
    return descriptor;
  };
}
