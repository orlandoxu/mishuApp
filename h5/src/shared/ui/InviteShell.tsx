import type { PropsWithChildren } from 'react';
import inviteBg from '../../assets/invite/icon_invite_bg.png';

export function InviteShell({ children, center }: PropsWithChildren<{ center?: boolean }>) {
  return (
    <main
      className={`relative flex min-h-screen flex-col overflow-hidden bg-[#FFF7F7] bg-cover bg-center bg-no-repeat text-[#1C1C1E] ${center ? 'items-center justify-center' : ''}`}
      style={{ backgroundImage: `url(${inviteBg})` }}
    >
      {children}
    </main>
  );
}
