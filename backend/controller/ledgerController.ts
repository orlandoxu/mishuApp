import { z } from "zod";
import { ASSERT, Ret } from "../common/error";
import { ok, type ApiResponse } from "../common/response";
import { BodySchema } from "../lib/fastify/bodySchema";
import type { TypedRequest } from "../lib/fastify/typeHelpers";
import { LedgerService } from "../services/ledgerService";
import { MoneyCategoryService } from "../services/moneyCategoryService";

export class LedgerController {
  static categoriesBody = z.object({
    direction: z.enum(["income", "expense"]),
    names: z.array(z.string().trim().min(1)).max(50),
  });

  static recordBody = z.object({
    requestKey: z.string().trim().min(1).optional(),
    idempotencyKey: z.string().trim().min(1).optional(),
    direction: z.enum(["income", "expense"]),
    amount: z.number().positive(),
    category: z.string().trim().min(1).default("其他"),
    note: z.string().trim().optional(),
    occurredAt: z.number().int().positive(),
  });

  @BodySchema(LedgerController.recordBody)
  static async record(
    request: TypedRequest<typeof LedgerController.recordBody> & FastifyRequest,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof LedgerService.record>>>> {
    ASSERT(request.user?.id, "未登录", Ret.NotLogin);
    const requestKey = request.body.requestKey ?? request.body.idempotencyKey;
    ASSERT(requestKey, "requestKey 不能为空", Ret.ERROR);
    const result = await LedgerService.record({
      userId: request.user.id,
      requestKey,
      direction: request.body.direction,
      amount: request.body.amount,
      category: request.body.category,
      note: request.body.note,
      occurredAt: request.body.occurredAt,
    });
    return ok(result);
  }

  static queryBody = z.object({
    startAtMs: z.number().int(),
    endAtMs: z.number().int(),
    limit: z.number().int().positive().max(500).optional(),
  });

  @BodySchema(LedgerController.queryBody)
  static async query(
    request: TypedRequest<typeof LedgerController.queryBody> & FastifyRequest,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof LedgerService.query>>>> {
    ASSERT(request.user?.id, "未登录", Ret.NotLogin);
    const result = await LedgerService.query({
      userId: request.user.id,
      ...request.body,
    });
    return ok(result);
  }

  static async summary(
    request: FastifyRequest,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof LedgerService.summary>>>> {
    ASSERT(request.user?.id, "未登录", Ret.NotLogin);
    const query = (request.query ?? {}) as { period?: string; timezone?: string };
    const period = query.period === "week" || query.period === "month" ? query.period : "day";
    const result = await LedgerService.summary({
      userId: request.user.id,
      period,
      timezone: query.timezone,
    });
    return ok(result);
  }

  static async categories(
    request: FastifyRequest,
  ): Promise<ApiResponse<Awaited<ReturnType<typeof MoneyCategoryService.listActive>>>> {
    ASSERT(request.user?.id, "未登录", Ret.NotLogin);
    const result = await MoneyCategoryService.listActive(request.user.id);
    return ok(result);
  }

  @BodySchema(LedgerController.categoriesBody)
  static async saveCategories(
    request: TypedRequest<typeof LedgerController.categoriesBody> & FastifyRequest,
  ): Promise<ApiResponse<{ items: Awaited<ReturnType<typeof MoneyCategoryService.replaceDirectionCategories>> }>> {
    ASSERT(request.user?.id, "未登录", Ret.NotLogin);
    const items = await MoneyCategoryService.replaceDirectionCategories({
      userId: request.user.id,
      direction: request.body.direction,
      names: request.body.names,
    });
    return ok({ items });
  }
}
