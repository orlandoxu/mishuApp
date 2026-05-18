import { z } from 'zod';
import { ASSERT, Ret } from '../common/error';
import { ok } from '../common/response';
import { BodySchema } from '../lib/fastify/bodySchema';
import type { TypedRequest } from '../lib/fastify/typeHelpers';
import { FriendService } from '../services/friendService';

export class FriendController {
  static listBody = z.object({
    keyword: z.string().trim().optional(),
    starredOnly: z.boolean().optional(),
    page: z.number().int().positive().optional(),
    pageSize: z.number().int().positive().optional(),
  });

  @BodySchema(FriendController.listBody)
  static async list(request: TypedRequest<typeof FriendController.listBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok(await FriendService.list({ userId: request.user.id, ...request.body }));
  }

  static detailBody = z.object({ friendId: z.string().trim().min(1) });
  @BodySchema(FriendController.detailBody)
  static async detail(request: TypedRequest<typeof FriendController.detailBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const item = await FriendService.detail(request.user.id, request.body.friendId);
    ASSERT(item, '联系人不存在', Ret.ERROR);
    return ok(item);
  }

  static createBody = z.object({
    requestKey: z.string().trim().optional(),
    name: z.string().trim().min(1),
    shortName: z.string().trim().min(1),
    age: z.number().int().min(0).max(150),
    gender: z.string().trim().min(1),
    role: z.string().trim().default(''),
    avatarText: z.string().trim().default(''),
    tags: z.array(z.string().trim()).optional(),
    birthday: z.string().trim().optional(),
    relationship: z.string().trim().optional(),
    preferences: z.array(z.string().trim()).optional(),
    resources: z.array(z.string().trim()).optional(),
    insight: z.string().trim().optional(),
    isStarred: z.boolean().optional(),
  });

  @BodySchema(FriendController.createBody)
  static async create(request: TypedRequest<typeof FriendController.createBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok(await FriendService.create({ userId: request.user.id, ...request.body }));
  }

  static updateBody = z.object({
    requestKey: z.string().trim().optional(),
    friendId: z.string().trim().min(1),
    name: z.string().trim().min(1).optional(),
    shortName: z.string().trim().min(1).optional(),
    age: z.number().int().min(0).max(150).optional(),
    gender: z.string().trim().min(1).optional(),
    role: z.string().trim().optional(),
    avatarText: z.string().trim().optional(),
    tags: z.array(z.string().trim()).optional(),
    birthday: z.string().trim().optional(),
    relationship: z.string().trim().optional(),
    preferences: z.array(z.string().trim()).optional(),
    resources: z.array(z.string().trim()).optional(),
    insight: z.string().trim().optional(),
    isStarred: z.boolean().optional(),
  });

  @BodySchema(FriendController.updateBody)
  static async update(request: TypedRequest<typeof FriendController.updateBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const { friendId, ...rest } = request.body;
    const item = await FriendService.update({ userId: request.user.id, friendId, ...rest });
    ASSERT(item, '联系人不存在', Ret.ERROR);
    return ok(item);
  }

  static deleteBody = z.object({ requestKey: z.string().trim().optional(), friendId: z.string().trim().min(1) });

  @BodySchema(FriendController.deleteBody)
  static async remove(request: TypedRequest<typeof FriendController.deleteBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const success = await FriendService.remove(request.user.id, request.body.friendId);
    ASSERT(success, '联系人不存在', Ret.ERROR);
    return ok({ success });
  }

  static interactionListBody = z.object({ friendId: z.string().trim().min(1) });
  @BodySchema(FriendController.interactionListBody)
  static async listInteractions(request: TypedRequest<typeof FriendController.interactionListBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok({ items: await FriendService.listInteractions(request.user.id, request.body.friendId) });
  }

  static interactionCreateBody = z.object({
    requestKey: z.string().trim().optional(),
    friendId: z.string().trim().min(1),
    date: z.string().trim().min(1),
    type: z.string().trim().min(1),
    desc: z.string().trim().min(1),
  });
  @BodySchema(FriendController.interactionCreateBody)
  static async createInteraction(request: TypedRequest<typeof FriendController.interactionCreateBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    return ok(await FriendService.createInteraction({ userId: request.user.id, ...request.body }));
  }

  static interactionUpdateBody = z.object({
    requestKey: z.string().trim().optional(),
    interactionId: z.string().trim().min(1),
    date: z.string().trim().optional(),
    type: z.string().trim().optional(),
    desc: z.string().trim().optional(),
  });

  @BodySchema(FriendController.interactionUpdateBody)
  static async updateInteraction(request: TypedRequest<typeof FriendController.interactionUpdateBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const item = await FriendService.updateInteraction({ userId: request.user.id, ...request.body });
    ASSERT(item, '互动记录不存在', Ret.ERROR);
    return ok(item);
  }

  static interactionDeleteBody = z.object({ requestKey: z.string().trim().optional(), interactionId: z.string().trim().min(1) });

  @BodySchema(FriendController.interactionDeleteBody)
  static async removeInteraction(request: TypedRequest<typeof FriendController.interactionDeleteBody> & FastifyRequest) {
    ASSERT(request.user?.id, '未登录', Ret.NotLogin);
    const success = await FriendService.removeInteraction(request.user.id, request.body.interactionId);
    ASSERT(success, '互动记录不存在', Ret.ERROR);
    return ok({ success });
  }
}
