import type {
  FastifyInstance,
  FastifyRequest,
  FastifyReply,
  RouteShorthandOptions,
} from "fastify";
import type { ZodTypeAny } from "zod";
import { RestError, Ret } from "../../common/error";
import { hasSchemaDecorator, getMethodSchema } from "./typeHelpers";

type FastifyMiddleware = (
  req: FastifyRequest,
  reply: FastifyReply,
) => void | Promise<void>;

type RouteHandler = (...args: any[]) => any;

type RouteOptionLike = Pick<RouteShorthandOptions, "config" | "schema" | "preHandler">;

function isRouteOptionLike(value: unknown): value is RouteOptionLike {
  if (!value || typeof value !== "object") {
    return false;
  }
  const candidate = value as Record<string, unknown>;
  return "config" in candidate || "schema" in candidate || "preHandler" in candidate;
}

function isZodSchema(value: unknown): value is ZodTypeAny {
  return !!value && typeof value === "object" && typeof (value as ZodTypeAny).safeParse === "function";
}

export function createRouter(fastify: FastifyInstance) {
  const makeRouter = (method: "get" | "post" | "put" | "delete") => {
    return (url: string, ...args: (RouteOptionLike | FastifyMiddleware | RouteHandler)[]) => {
      let routeOptions: RouteOptionLike = {};
      let handlers = args;

      if (args.length > 0 && isRouteOptionLike(args[0])) {
        routeOptions = args[0];
        handlers = args.slice(1);
      }

      const middlewares: FastifyMiddleware[] = [];
      let controllerFn: RouteHandler | null = null;

      for (const h of handlers) {
        if (typeof h === "function" && hasSchemaDecorator(h)) {
          controllerFn = h;
          break;
        }
      }

      if (!controllerFn && handlers.length > 0) {
        const lastHandler = handlers[handlers.length - 1];
        if (typeof lastHandler === "function") {
          controllerFn = lastHandler;
        }
      }

      for (const h of handlers) {
        if (typeof h === "function" && h !== controllerFn) {
          middlewares.push(h as FastifyMiddleware);
        }
      }

      if (!controllerFn) {
        throw new Error(`No controller function provided for ${url}`);
      }

      const methodSchema = getMethodSchema(controllerFn) ?? {};
      const methodBodySchema = methodSchema.body;

      const mergedSchema = {
        ...((routeOptions.schema as Record<string, unknown> | undefined) ?? {}),
        ...(isZodSchema(methodBodySchema)
          ? Object.fromEntries(
              Object.entries(methodSchema).filter(([key]) => key !== "body"),
            )
          : methodSchema),
      };

      const preHandlers: FastifyMiddleware[] = [];
      const configuredPreHandler = routeOptions.preHandler;
      if (Array.isArray(configuredPreHandler)) {
        preHandlers.push(...(configuredPreHandler as FastifyMiddleware[]));
      } else if (typeof configuredPreHandler === "function") {
        preHandlers.push(configuredPreHandler as FastifyMiddleware);
      }

      if (isZodSchema(methodBodySchema)) {
        preHandlers.push(async (request) => {
          const result = methodBodySchema.safeParse(request.body);
          if (!result.success) {
            const issue = result.error.issues[0];
            const message = issue?.message ?? "请求参数校验失败";
            throw new RestError(message, Ret.ERROR);
          }
          request.body = result.data;
        });
      }

      preHandlers.push(...middlewares);

      const finalOptions: RouteShorthandOptions = {
        ...routeOptions,
        ...(Object.keys(mergedSchema).length > 0 ? { schema: mergedSchema } : {}),
        ...(preHandlers.length > 0 ? { preHandler: preHandlers } : {}),
      };

      (fastify as any)[method](url, finalOptions, controllerFn);
    };
  };

  return {
    get: makeRouter("get"),
    post: makeRouter("post"),
    put: makeRouter("put"),
    delete: makeRouter("delete"),
  };
}
