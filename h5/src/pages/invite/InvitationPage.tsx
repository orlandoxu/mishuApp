import { useNavigate, useParams } from "react-router-dom";
import avatarGirl from "../../assets/avatar/avatar_girl.png";
import inviteCardBg from "../../assets/invite/icon_invite_card_bg.png";
import { env } from "../../shared/config/env";
import { BottomActions } from "../../shared/ui/BottomActions";
import { InviteShell } from "../../shared/ui/InviteShell";
import { LoadingBlock } from "../../shared/ui/LoadingBlock";
import { useInvitationStore } from "../../features/invitation/store";
import { useLoadInvitation } from "./useLoadInvitation";

export function InvitationPage() {
  const { token } = useParams();
  const navigate = useNavigate();
  const detail = useInvitationStore((state) => state.detail);
  const status = useInvitationStore((state) => state.status);
  const errorMessage = useInvitationStore((state) => state.errorMessage);
  useLoadInvitation(token);

  if (status === "loading" || status === "idle") {
    return <LoadingBlock text="正在读取邀请..." />;
  }

  if (status === "error" || !detail) {
    return <LoadingBlock text={errorMessage || "邀请不存在或已失效"} />;
  }

  const canBind = detail.status === "pending";
  const avatar = detail.inviterAvatarUrl || avatarGirl;

  return (
    <InviteShell>
      <div className="flex-1 pb-40 pt-20">
        <div className="animate-fade-in-up mx-auto flex w-full max-w-[380px] items-start gap-3 px-6">
          <div className="h-[48px] w-[48px] shrink-0 overflow-hidden rounded-full border-2 border-white shadow-sm">
            <img
              src={avatar}
              alt="邀请人头像"
              className="h-full w-full object-cover"
            />
          </div>

          <div className="relative flex-1 overflow-hidden rounded-[24px] rounded-tl-[8px] border border-white bg-white px-[22px] py-[22px] text-left shadow-[0_8px_24px_rgba(255,130,151,0.08)]">
            <div
              className="pointer-events-none absolute bottom-0 right-0 h-[140px] w-[140px] bg-contain bg-right-bottom bg-no-repeat opacity-80"
              style={{ backgroundImage: `url(${inviteCardBg})` }}
            />
            <p className="relative z-10 text-[16px] leading-[2] text-[#4A4A4A]">
              我们一起走过{" "}
              <span className="text-[17px] text-[#FF8297]">
                {detail.daysTogether}
              </span>{" "}
              个日夜
              <br />
              有笑、有小情绪，
              <br />
              还有很多没说出口的在意
              <br />
              <br />
              我偷偷为我们留了一个地方
              <br />
              放下了
              <br />
              心扉的钥匙
            </p>
          </div>
        </div>
      </div>

      <BottomActions>
        <div className="mb-1 text-center">
          <span className="text-[13px] tracking-wide text-[#C5B4B4]">
            {detail.inviterName} 邀请你加入 小问号 App
          </span>
        </div>
        <a
          href={env.appStoreUrl}
          className="flex min-h-[54px] w-full items-center justify-center rounded-full border border-[#FFB2BD] bg-white text-center text-[17px] font-medium text-[#FF8297] shadow-[0_2px_8px_rgba(255,130,151,0.05)] transition-colors active:bg-[#FFF5F7]"
        >
          还没App？点我去下载
        </a>
        <button
          type="button"
          disabled={!canBind}
          onClick={() => navigate(`/invite/${token ?? detail.token}/bind`)}
          className="min-h-[54px] w-full rounded-full border-none bg-[#FF8297] text-[17px] font-medium text-white shadow-[0_6px_20px_rgba(255,130,151,0.35)] outline-none transition-all active:bg-[#E87387] disabled:bg-[#FFC6D0] disabled:shadow-none"
        >
          {canBind ? "已下载，接受邀请" : "邀请已失效"}
        </button>
      </BottomActions>
    </InviteShell>
  );
}
