import { Crown, Diamond } from 'lucide-react'

export type VipStatus = '普通' | 'VIP' | 'SVIP'

function VipPill({ vipStatus }: { vipStatus: VipStatus }) {
  if (vipStatus === 'SVIP') {
    return <span className="inline-flex items-center gap-1 rounded-full bg-[#fff4db] px-2 py-0.5 text-[11px] font-semibold text-[#9a6612]"><Crown size={10} />SVIP</span>
  }
  if (vipStatus === 'VIP') {
    return <span className="inline-flex items-center gap-1 rounded-full bg-[#efe9ff] px-2 py-0.5 text-[11px] font-semibold text-[#6540c8]"><Diamond size={10} />VIP</span>
  }
  return <span className="inline-flex rounded-full bg-[#edf2fa] px-2 py-0.5 text-[11px] font-semibold text-[#5e7397]">普通</span>
}

function Avatar({ name }: { name: string }) {
  const seed = name.charCodeAt(name.length - 1) || 0
  const palette = ['bg-[#dcecff] text-[#2958a8]', 'bg-[#e8f7eb] text-[#247c48]', 'bg-[#fff0dd] text-[#9a5f12]', 'bg-[#f2ebff] text-[#6a3fc1]']
  const cls = palette[seed % palette.length]
  return <span className={`inline-flex h-9 w-9 items-center justify-center rounded-full text-xs font-bold ${cls}`}>{name.slice(-1)}</span>
}

export function UserIdentityCell({ name, phone, vipStatus }: { name: string; phone: string; vipStatus: VipStatus }) {
  return (
    <div className="flex items-center gap-3">
      <div className="flex w-12 flex-col items-center gap-1">
        <Avatar name={name} />
        <VipPill vipStatus={vipStatus} />
      </div>
      <div className="min-w-0">
        <p className="text-sm font-semibold text-[#243a5c]">{name}</p>
        <p className="truncate text-xs text-[#6f7f99]">{phone}</p>
      </div>
    </div>
  )
}
