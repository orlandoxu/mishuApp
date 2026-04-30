import { z } from 'zod';
import { ASSERT, Ret } from '../common/error';
import { BodySchema } from '../lib/fastify/bodySchema';
import { TypedRequest } from '../lib/fastify/typeHelpers';
import { PartnerInvitationService } from '../services/partnerInvitationService';

function tokenFromRequest(request: FastifyRequest): string {
  const params = request.params as { token?: string } | undefined;
  const token = (params?.token ?? '').trim();
  ASSERT(token, '邀请参数缺失', Ret.ERROR);
  return token;
}

export class PartnerInvitationController {
  static createType = z.object({
    inviterName: z.string().trim().max(32).optional(),
    inviterAvatarUrl: z.string().trim().max(500).optional(),
  });

  @BodySchema(PartnerInvitationController.createType)
  static async create(
    request: TypedRequest<typeof PartnerInvitationController.createType>,
  ) {
    ASSERT(request.user, '未登录', Ret.NotLogin);
    return ok(
      await PartnerInvitationService.createInvitation({
        inviterUserId: request.user.id,
        inviterName: request.body.inviterName,
        inviterAvatarUrl: request.body.inviterAvatarUrl,
      }),
    );
  }

  static async detail(request: FastifyRequest) {
    return ok(await PartnerInvitationService.getInvitation(tokenFromRequest(request)));
  }

  static codeType = z.object({
    mobile: z.string().trim().min(1, '手机号不能为空'),
  });

  @BodySchema(PartnerInvitationController.codeType)
  static async code(
    request: TypedRequest<typeof PartnerInvitationController.codeType>,
  ) {
    return ok(
      await PartnerInvitationService.sendAcceptCode({
        token: tokenFromRequest(request),
        mobile: request.body.mobile,
      }),
    );
  }

  static acceptType = z.object({
    mobile: z.string().trim().min(1, '手机号不能为空'),
    code: z.string().trim().min(4, '验证码长度不正确'),
  });

  @BodySchema(PartnerInvitationController.acceptType)
  static async accept(
    request: TypedRequest<typeof PartnerInvitationController.acceptType>,
  ) {
    return ok(
      await PartnerInvitationService.acceptInvitation({
        token: tokenFromRequest(request),
        mobile: request.body.mobile,
        code: request.body.code,
      }),
    );
  }

  static async relationship(request: FastifyRequest) {
    ASSERT(request.user, '未登录', Ret.NotLogin);
    return ok(await PartnerInvitationService.getRelationship(request.user.id));
  }
}
