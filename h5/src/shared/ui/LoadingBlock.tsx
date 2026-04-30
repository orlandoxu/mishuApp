export function LoadingBlock({ text }: { text: string }) {
  return (
    <div className="flex min-h-screen items-center justify-center px-8 text-center text-[15px] text-[#A89886]">
      {text}
    </div>
  );
}
