import { useParams } from 'react-router-dom';
import { useInvitationStore } from '../../features/invitation/store';
import { env } from '../../shared/config/env';
import { BottomActions } from '../../shared/ui/BottomActions';
import { InviteShell } from '../../shared/ui/InviteShell';
import { useLoadInvitation } from './useLoadInvitation';

export function InvitationSuccessPage() {
  const { token } = useParams();
  const detail = useInvitationStore((state) => state.detail);
  useLoadInvitation(token);
  const inviterName = detail?.inviterName ?? 'TA';
  const openAppUrl = detail?.openAppUrl ?? `${env.universalLinkBaseUrl.replace(/\/$/, '')}/invite/${token ?? ''}`;

  return (
    <InviteShell center>
      <div className="flex w-full flex-1 flex-col items-center justify-center px-8 pb-32">
        <div className="mb-6 flex h-[88px] w-[88px] items-center justify-center rounded-full border border-[#FFF0F2] bg-white text-[44px] shadow-[0_8px_24px_rgba(255,130,151,0.15)]">
          🎉
        </div>

        <h1 className="mb-3 text-[28px] font-semibold text-[#2C2C2E]">绑定成功</h1>
        <p className="mb-8 text-center text-[16px] leading-relaxed text-[#A89886]">
          你已经和 <span className="font-medium text-[#FF8297]">{inviterName}</span> 成功绑定
          <br />
          快去 App 里开启你们的私密空间吧
        </p>
      </div>

      <BottomActions>
        <a
          href={env.appStoreUrl}
          className="flex min-h-[54px] w-full items-center justify-center rounded-full border border-[#FFB2BD] bg-white text-center text-[17px] font-medium text-[#FF8297] shadow-[0_2px_8px_rgba(255,130,151,0.05)] transition-colors active:bg-[#FFF5F7]"
        >
          还没App？点我去下载
        </a>

        <a
          href={openAppUrl}
          className="flex min-h-[54px] w-full items-center justify-center rounded-full bg-[#FF8297] text-center text-[17px] font-medium text-white shadow-[0_6px_20px_rgba(255,130,151,0.35)] transition-colors active:bg-[#E87387]"
        >
          打开 App 查看
        </a>
      </BottomActions>
    </InviteShell>
  );
}
