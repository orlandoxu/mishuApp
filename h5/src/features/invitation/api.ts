import { apiRequest } from '../../shared/api/apiClient';
import type { InvitationDetail } from './types';

export function getInvitation(token: string, signal?: AbortSignal): Promise<InvitationDetail> {
  return apiRequest<InvitationDetail>(`/partner/invitations/${encodeURIComponent(token)}`, {}, { signal });
}

export function sendInvitationCode(token: string, mobile: string): Promise<Record<string, never>> {
  return apiRequest<Record<string, never>>(`/partner/invitations/${encodeURIComponent(token)}/code`, {
    method: 'POST',
    body: JSON.stringify({ mobile }),
  });
}

export function acceptInvitation(token: string, mobile: string, code: string): Promise<InvitationDetail> {
  return apiRequest<InvitationDetail>(`/partner/invitations/${encodeURIComponent(token)}/accept`, {
    method: 'POST',
    body: JSON.stringify({ mobile, code }),
  });
}
