import { z } from 'zod';
import { ASSERT, Ret } from '../common/error';
import { ok } from '../common/response';
import { BodySchema } from '../lib/fastify/bodySchema';
import type { TypedRequest } from '../lib/fastify/typeHelpers';
import { FoodMemoryService } from '../services/foodMemoryService';

export class FoodMemoryController {
  static listBody = z.object({
    category: z.string().trim().optional(),
    month: z.string().trim().optional(),
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
    minLat: z.number().optional(),
    maxLat: z.number().optional(),
    minLng: z.number().optional(),
    maxLng: z.number().optional(),
  });

  @BodySchema(FoodMemoryController.listBody)
  static async list(request: TypedRequest<typeof FoodMemoryController.listBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok(await FoodMemoryService.list({ userId: request.user.id, ...request.body }));
  }

  static detailBody = z.object({ id: z.string().trim().min(1) });
  @BodySchema(FoodMemoryController.detailBody)
  static async detail(request: TypedRequest<typeof FoodMemoryController.detailBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const item = await FoodMemoryService.detail(request.user.id, request.body.id);
    ASSERT(item, '记录不存在', Ret.ERROR);
    return ok(item);
  }

  static createBody = z.object({
    requestKey: z.string().trim().optional(),
    name: z.string().trim().min(1),
    category: z.string().trim().min(1),
    pricePerPerson: z.number().min(0),
    visitedAt: z.number().int().positive(),
    rating: z.number().int().min(1).max(5),
    features: z.array(z.string().trim()).optional(),
    signatureDishes: z.array(z.string().trim()).optional(),
    avoidDishes: z.array(z.string().trim()).optional(),
    review: z.string().trim().optional(),
    photos: z.array(z.string().trim()).optional(),
    lat: z.number(),
    lng: z.number(),
    address: z.string().trim().optional(),
  });

  @BodySchema(FoodMemoryController.createBody)
  static async create(request: TypedRequest<typeof FoodMemoryController.createBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok(await FoodMemoryService.create({ userId: request.user.id, ...request.body }));
  }

  static updateBody = z.object({
    requestKey: z.string().trim().optional(),
    id: z.string().trim().min(1),
    name: z.string().trim().min(1).optional(),
    category: z.string().trim().min(1).optional(),
    pricePerPerson: z.number().min(0).optional(),
    visitedAt: z.number().int().positive().optional(),
    rating: z.number().int().min(1).max(5).optional(),
    features: z.array(z.string().trim()).optional(),
    signatureDishes: z.array(z.string().trim()).optional(),
    avoidDishes: z.array(z.string().trim()).optional(),
    review: z.string().trim().optional(),
    photos: z.array(z.string().trim()).optional(),
    lat: z.number().optional(),
    lng: z.number().optional(),
    address: z.string().trim().optional(),
  });

  @BodySchema(FoodMemoryController.updateBody)
  static async update(request: TypedRequest<typeof FoodMemoryController.updateBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const { id, ...rest } = request.body;
    const item = await FoodMemoryService.update({ userId: request.user.id, id, ...rest });
    ASSERT(item, '记录不存在', Ret.ERROR);
    return ok(item);
  }

  static deleteBody = z.object({ requestKey: z.string().trim().optional(), id: z.string().trim().min(1) });

  @BodySchema(FoodMemoryController.deleteBody)
  static async remove(request: TypedRequest<typeof FoodMemoryController.deleteBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const success = await FoodMemoryService.remove(request.user.id, request.body.id);
    ASSERT(success, '记录不存在', Ret.ERROR);
    return ok({ success });
  }

  static async categories(request: FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok({ items: await FoodMemoryService.categories(request.user.id) });
  }

  static async months(request: FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok({ items: await FoodMemoryService.months(request.user.id) });
  }
}
