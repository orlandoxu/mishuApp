import type { PropsWithChildren } from 'react';

export function BottomActions({ children }: PropsWithChildren) {
  return (
    <div className="fixed bottom-0 left-0 right-0 w-full bg-gradient-to-t from-[#FFF7F7] via-[#FFF7F7] to-transparent pb-[calc(48px+env(safe-area-inset-bottom))] pt-16">
      <div className="mx-auto flex max-w-[380px] flex-col gap-4 px-8">{children}</div>
    </div>
  );
}
