export type InvitationStatus = 'pending' | 'accepted' | 'revoked' | 'expired';

export type InvitationDetail = {
  token: string;
  shareUrl: string;
  openAppUrl: string;
  expiresAt: string;
  inviterName: string;
  inviterAvatarUrl: string;
  shareTitle: string;
  shareDescription: string;
  status: InvitationStatus;
  daysTogether: number;
};
