import { ChevronLeft } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useInvitationStore } from '../../features/invitation/store';
import { InviteShell } from '../../shared/ui/InviteShell';
import { LoadingBlock } from '../../shared/ui/LoadingBlock';
import { useLoadInvitation } from './useLoadInvitation';

export function InvitationBindPage() {
  const { token } = useParams();
  const navigate = useNavigate();
  const [now, setNow] = useState(Date.now());
  const detail = useInvitationStore((state) => state.detail);
  const status = useInvitationStore((state) => state.status);
  const actionStatus = useInvitationStore((state) => state.actionStatus);
  const mobile = useInvitationStore((state) => state.mobile);
  const code = useInvitationStore((state) => state.code);
  const countdownEndsAt = useInvitationStore((state) => state.countdownEndsAt);
  const errorMessage = useInvitationStore((state) => state.errorMessage);
  const setMobile = useInvitationStore((state) => state.setMobile);
  const setCode = useInvitationStore((state) => state.setCode);
  const sendCode = useInvitationStore((state) => state.sendCode);
  const accept = useInvitationStore((state) => state.accept);
  useLoadInvitation(token);

  useEffect(() => {
    const timer = window.setInterval(() => setNow(Date.now()), 500);
    return () => window.clearInterval(timer);
  }, []);

  if (status === 'loading' || status === 'idle') {
    return <LoadingBlock text="正在读取邀请..." />;
  }

  if (status === 'error' || !detail) {
    return <LoadingBlock text={errorMessage || '邀请不存在或已失效'} />;
  }

  const countdown = Math.max(0, Math.ceil((countdownEndsAt - now) / 1000));
  const canSendCode = /^1[3-9]\d{9}$/.test(mobile) && countdown === 0 && actionStatus !== 'loading';
  const canAccept = /^1[3-9]\d{9}$/.test(mobile) && code.length >= 4 && actionStatus !== 'loading';

  async function handleAccept() {
    if (!token) { return; }
    const accepted = await accept(token);
    if (accepted) {
      navigate(`/invite/${token}/success`, { replace: true });
    }
  }

  return (
    <InviteShell>
      <div className="flex h-12 items-center px-4 pt-12">
        <button type="button" onClick={() => navigate(-1)} className="-ml-2 p-2 transition-opacity active:opacity-50">
          <ChevronLeft className="h-6 w-6 text-[#4A4A4A]" />
        </button>
      </div>

      <div className="flex-1 px-8 pt-6">
        <h1 className="mb-3 text-[28px] font-semibold text-[#2C2C2E]">接受邀请</h1>
        <p className="mb-10 text-[15px] text-[#A89886]">输入手机号即可与 {detail.inviterName} 绑定</p>

        <div className="flex flex-col gap-6">
          <div className="flex items-center rounded-[16px] border border-white bg-white px-4 py-3 shadow-[0_2px_12px_rgba(255,130,151,0.06)] transition-colors focus-within:border-[#FFB2BD]">
            <span className="mr-3 font-medium text-[#2C2C2E]">+86</span>
            <div className="mr-3 h-4 w-px bg-[#E5E5EA]" />
            <input
              type="tel"
              inputMode="numeric"
              maxLength={11}
              placeholder="请输入手机号"
              value={mobile}
              onChange={(event) => setMobile(event.target.value)}
              className="min-w-0 flex-1 border-none bg-transparent text-[16px] outline-none placeholder:text-[#C5B4B4]"
            />
          </div>

          <div className="flex items-center justify-between rounded-[16px] border border-white bg-white px-4 py-3 shadow-[0_2px_12px_rgba(255,130,151,0.06)] transition-colors focus-within:border-[#FFB2BD]">
            <input
              type="tel"
              inputMode="numeric"
              maxLength={6}
              placeholder="请输入验证码"
              value={code}
              onChange={(event) => setCode(event.target.value)}
              className="min-w-0 flex-1 border-none bg-transparent text-[16px] outline-none placeholder:text-[#C5B4B4]"
            />
            <button
              type="button"
              onClick={() => token && sendCode(token)}
              disabled={!canSendCode}
              className="shrink-0 bg-transparent pl-3 text-[15px] font-medium text-[#FF8297] outline-none transition-all active:opacity-60 disabled:text-[#C5B4B4] disabled:opacity-60"
            >
              {countdown > 0 ? `${countdown}s 后重新获取` : '获取验证码'}
            </button>
          </div>
        </div>

        {errorMessage && <p className="mt-5 text-center text-[14px] text-[#E35D72]">{errorMessage}</p>}

        <button
          type="button"
          onClick={handleAccept}
          disabled={!canAccept}
          className="mt-12 min-h-[54px] w-full rounded-full border-none bg-[#FF8297] text-[17px] font-semibold text-white shadow-[0_6px_20px_rgba(255,130,151,0.35)] outline-none transition-all active:bg-[#E87387] disabled:bg-[#FFC6D0] disabled:shadow-none"
        >
          {actionStatus === 'loading' ? '处理中...' : '确认绑定'}
        </button>
      </div>
    </InviteShell>
  );
}
