export type VipStatus = '普通' | 'VIP' | 'SVIP'

function VipBadge({ vipStatus }: { vipStatus: VipStatus }) {
  if (vipStatus === '普通') return null
  return <span className="inline-flex h-5 items-center rounded-full border border-[#4f46e5] bg-[#5b4bff] px-2.5 text-[11px] font-extrabold tracking-[0.03em] text-white shadow-[0_10px_16px_-10px_rgba(91,75,255,0.92)]">VIP</span>
}

function Avatar({ name }: { name: string }) {
  const seed = name.charCodeAt(name.length - 1) || 0
  const palette = ['bg-[#dcecff] text-[#2958a8]', 'bg-[#e8f7eb] text-[#247c48]', 'bg-[#fff0dd] text-[#9a5f12]', 'bg-[#f2ebff] text-[#6a3fc1]']
  const cls = palette[seed % palette.length]

  return <span className={`inline-flex h-12 w-12 items-center justify-center rounded-full text-lg font-bold ${cls}`}>{name.slice(-1)}</span>
}

export function UserIdentityCell({ name, phone, vipStatus }: { name: string; phone: string; vipStatus: VipStatus }) {
  return (
    <div className="flex items-center gap-3">
      <div className="relative flex w-16 items-center justify-center pb-2">
        <Avatar name={name} />
        <div className="absolute bottom-0 left-1/2 -translate-x-1/2">
          <VipBadge vipStatus={vipStatus} />
        </div>
      </div>
      <div className="min-w-0">
        <p className="text-sm font-semibold text-[#243a5c]">{name}</p>
        <p className="truncate text-xs text-[#6f7f99]">{phone}</p>
      </div>
    </div>
  )
}
