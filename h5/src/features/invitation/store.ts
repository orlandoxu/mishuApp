import { create } from 'zustand';
import { acceptInvitation, getInvitation, sendInvitationCode } from './api';
import type { InvitationDetail } from './types';

type LoadingState = 'idle' | 'loading' | 'success' | 'error';

type InvitationState = {
  detail?: InvitationDetail;
  status: LoadingState;
  actionStatus: LoadingState;
  mobile: string;
  code: string;
  countdownEndsAt: number;
  errorMessage: string;
  load: (token: string, signal?: AbortSignal) => Promise<void>;
  setMobile: (value: string) => void;
  setCode: (value: string) => void;
  sendCode: (token: string) => Promise<void>;
  accept: (token: string) => Promise<InvitationDetail | undefined>;
  resetActionError: () => void;
};

const digitsOnly = (value: string, max: number) => value.replace(/\D/g, '').slice(0, max);

export const useInvitationStore = create<InvitationState>((set, get) => ({
  status: 'idle',
  actionStatus: 'idle',
  mobile: '',
  code: '',
  countdownEndsAt: 0,
  errorMessage: '',
  async load(token, signal) {
    set({ status: 'loading', errorMessage: '' });
    try {
      const detail = await getInvitation(token, signal);
      set({ detail, status: 'success' });
    } catch (error) {
      set({ status: 'error', errorMessage: error instanceof Error ? error.message : '邀请加载失败' });
    }
  },
  setMobile(value) {
    set({ mobile: digitsOnly(value, 11), errorMessage: '' });
  },
  setCode(value) {
    set({ code: digitsOnly(value, 6), errorMessage: '' });
  },
  async sendCode(token) {
    const { mobile } = get();
    if (!/^1[3-9]\d{9}$/.test(mobile)) {
      set({ errorMessage: '请输入正确的手机号' });
      return;
    }
    set({ actionStatus: 'loading', errorMessage: '' });
    try {
      await sendInvitationCode(token, mobile);
      set({ actionStatus: 'success', countdownEndsAt: Date.now() + 60_000 });
    } catch (error) {
      set({ actionStatus: 'error', errorMessage: error instanceof Error ? error.message : '验证码发送失败' });
    }
  },
  async accept(token) {
    const { mobile, code } = get();
    if (!/^1[3-9]\d{9}$/.test(mobile) || code.length < 4) {
      set({ errorMessage: '请填写手机号和验证码' });
      return undefined;
    }
    set({ actionStatus: 'loading', errorMessage: '' });
    try {
      const detail = await acceptInvitation(token, mobile, code);
      set({ detail, actionStatus: 'success' });
      return detail;
    } catch (error) {
      set({ actionStatus: 'error', errorMessage: error instanceof Error ? error.message : '绑定失败' });
      return undefined;
    }
  },
  resetActionError() {
    set({ errorMessage: '', actionStatus: 'idle' });
  },
}));

export const selectCanSendCode = (state: InvitationState) =>
  /^1[3-9]\d{9}$/.test(state.mobile) && state.countdownEndsAt <= Date.now() && state.actionStatus !== 'loading';

export const selectCanAccept = (state: InvitationState) =>
  /^1[3-9]\d{9}$/.test(state.mobile) && state.code.length >= 4 && state.actionStatus !== 'loading';
