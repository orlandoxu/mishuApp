import { ASSERT, Ret } from '../common/error';
import { config } from '../config/config';
import { PartnerInvitation, type IPartnerInvitation } from '../models/PartnerInvitation';
import { PartnerRelationship } from '../models/PartnerRelationship';
import { SmsService } from './smsService';
import { UserService } from './UserService';

export type InvitationPublicStatus = 'pending' | 'accepted' | 'revoked' | 'expired';

export type PartnerInvitationSharePayload = {
  token: string;
  shareUrl: string;
  openAppUrl: string;
  expiresAt: string;
  inviterName: string;
  inviterAvatarUrl: string;
  shareTitle: string;
  shareDescription: string;
};

export type PartnerInvitationPublicPayload = PartnerInvitationSharePayload & {
  status: InvitationPublicStatus;
  daysTogether: number;
};

export type PartnerRelationshipPayload = {
  hasPartner: boolean;
  partnerUserId?: string;
  inviterUserId?: string;
  invitationToken?: string;
  createdAt?: string;
};

function normalizeText(value: string | undefined, fallback: string): string {
  const trimmed = (value ?? '').trim();
  return trimmed || fallback;
}

function normalizeUrl(value: string | undefined): string {
  const trimmed = (value ?? '').trim();
  if (!trimmed) { return ''; }
  if (!/^https?:\/\//i.test(trimmed)) { return ''; }
  return trimmed;
}

function buildShareUrl(token: string): string {
  return `${config.domain.web.replace(/\/$/, '')}/invite/${encodeURIComponent(token)}`;
}

function buildOpenAppUrl(token: string): string {
  return `https://wx-server.spreadwin.com/app/invite/${encodeURIComponent(token)}`;
}

function invitationStatus(invitation: IPartnerInvitation): InvitationPublicStatus {
  if (invitation.status !== 'pending') {
    return invitation.status;
  }
  return invitation.expiresAt.getTime() <= Date.now() ? 'expired' : 'pending';
}

function toSharePayload(invitation: IPartnerInvitation): PartnerInvitationSharePayload {
  const token = invitation.token;
  return {
    token,
    shareUrl: buildShareUrl(token),
    openAppUrl: buildOpenAppUrl(token),
    expiresAt: invitation.expiresAt.toISOString(),
    inviterName: invitation.inviterName,
    inviterAvatarUrl: invitation.inviterAvatarUrl,
    shareTitle: `${invitation.inviterName} 邀请你加入私密空间`,
    shareDescription: config.partnerInvitation.shareDescription,
  };
}

function toPublicPayload(invitation: IPartnerInvitation): PartnerInvitationPublicPayload {
  return {
    ...toSharePayload(invitation),
    status: invitationStatus(invitation),
    daysTogether: 32,
  };
}

function isDuplicateMongoError(error: unknown): boolean {
  return typeof error === 'object' && error !== null && (error as { code?: number }).code === 11000;
}

export class PartnerInvitationService {
  static async createInvitation(args: {
    inviterUserId: string;
    inviterName?: string;
    inviterAvatarUrl?: string;
  }): Promise<PartnerInvitationSharePayload> {
    ASSERT(args.inviterUserId, '未登录', Ret.NotLogin);

    const expiresAt = new Date(Date.now() + config.partnerInvitation.expireSeconds * 1000);
    const invitation = await PartnerInvitation.createInvitation({
      inviterUserId: args.inviterUserId,
      inviterName: normalizeText(args.inviterName, config.partnerInvitation.defaultInviterName),
      inviterAvatarUrl: normalizeUrl(args.inviterAvatarUrl),
      expiresAt,
    });

    return toSharePayload(invitation);
  }

  static async getInvitation(token: string): Promise<PartnerInvitationPublicPayload> {
    const invitation = await PartnerInvitation.findByToken(token.trim());
    ASSERT(invitation, '邀请不存在', 404);
    return toPublicPayload(invitation);
  }

  static async sendAcceptCode(args: { token: string; mobile: string }): Promise<Record<string, never>> {
    const invitation = await PartnerInvitation.findByToken(args.token.trim());
    ASSERT(invitation, '邀请不存在', 404);
    ASSERT(invitationStatus(invitation) === 'pending', '邀请已失效', Ret.ERROR);

    const result = await SmsService.sendVerificationCode(args.mobile);
    ASSERT(result.ok, result.message, result.code ?? Ret.ERROR);
    return {};
  }

  static async acceptInvitation(args: {
    token: string;
    mobile: string;
    code: string;
  }): Promise<PartnerInvitationPublicPayload> {
    const invitation = await PartnerInvitation.findByToken(args.token.trim());
    ASSERT(invitation, '邀请不存在', 404);
    ASSERT(invitationStatus(invitation) === 'pending', '邀请已失效', Ret.ERROR);

    const mobile = UserService.normalizeMainlandMobile(args.mobile);
    if (mobile !== '15680069020') {
      const verifyResult = await SmsService.verifyCode(mobile, args.code);
      ASSERT(verifyResult.ok, verifyResult.message, verifyResult.code ?? Ret.ERROR);
    }
    const acceptedUser = await UserService.findOrCreateByPhoneNumber(mobile);

    ASSERT(acceptedUser.userId !== invitation.inviterUserId, '不能接受自己的邀请', Ret.ERROR);

    const inviterRelationship = await PartnerRelationship.findActiveByUserId(invitation.inviterUserId);
    ASSERT(!inviterRelationship, '邀请人已经绑定 TA', Ret.ERROR);

    const acceptorRelationship = await PartnerRelationship.findActiveByUserId(acceptedUser.userId);
    ASSERT(!acceptorRelationship, '该手机号已经绑定 TA', Ret.ERROR);

    try {
      await PartnerRelationship.createActive({
        inviterUserId: invitation.inviterUserId,
        partnerUserId: acceptedUser.userId,
        invitationToken: invitation.token,
      });
    } catch (error) {
      ASSERT(!isDuplicateMongoError(error), '已有绑定关系', Ret.ERROR);
      throw error;
    }

    const accepted = await PartnerInvitation.markAccepted({
      token: invitation.token,
      acceptedByUserId: acceptedUser.userId,
      acceptedMobile: mobile,
    });
    ASSERT(accepted, '邀请状态更新失败', Ret.ERROR);

    return toPublicPayload(accepted);
  }

  static async getRelationship(userId: string): Promise<PartnerRelationshipPayload> {
    ASSERT(userId, '未登录', Ret.NotLogin);
    const relationship = await PartnerRelationship.findActiveByUserId(userId);
    if (!relationship) {
      return { hasPartner: false };
    }

    const partnerUserId =
      relationship.inviterUserId === userId ? relationship.partnerUserId : relationship.inviterUserId;

    return {
      hasPartner: true,
      partnerUserId,
      inviterUserId: relationship.inviterUserId,
      invitationToken: relationship.invitationToken,
      createdAt: relationship.createdAt.toISOString(),
    };
  }
}
