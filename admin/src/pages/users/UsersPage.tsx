import { FormEvent, useEffect, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PaginationBar } from '@/components/ui/pagination-bar'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { adminApi, type AdminUserRecord } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'
import { Search, RotateCcw, Users2, Tag, Crown, Diamond } from 'lucide-react'

function formatTime(raw: string | null): string {
  if (!raw) return '-'
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

function VipPill({ vipStatus }: { vipStatus: '普通' | 'VIP' | 'SVIP' }) {
  if (vipStatus === 'SVIP') {
    return <span className="inline-flex items-center gap-1 rounded-full bg-[#fff4db] px-2.5 py-1 text-xs font-semibold text-[#9a6612]"><Crown size={12} />SVIP</span>
  }
  if (vipStatus === 'VIP') {
    return <span className="inline-flex items-center gap-1 rounded-full bg-[#efe9ff] px-2.5 py-1 text-xs font-semibold text-[#6540c8]"><Diamond size={12} />VIP</span>
  }
  return <span className="inline-flex rounded-full bg-[#edf2fa] px-2.5 py-1 text-xs font-semibold text-[#5e7397]">普通</span>
}

function formatCurrency(value: number): string {
  return value > 0 ? `¥${value.toFixed(2)}` : '¥0.00'
}

function Avatar({ name }: { name: string }) {
  const seed = name.charCodeAt(name.length - 1) || 0
  const palette = ['bg-[#dcecff] text-[#2958a8]', 'bg-[#e8f7eb] text-[#247c48]', 'bg-[#fff0dd] text-[#9a5f12]', 'bg-[#f2ebff] text-[#6a3fc1]']
  const cls = palette[seed % palette.length]
  return <span className={`inline-flex h-8 w-8 items-center justify-center rounded-full text-xs font-bold ${cls}`}>{name.slice(-1)}</span>
}

export function UsersPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const [records, setRecords] = useState<AdminUserRecord[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [keywordDraft, setKeywordDraft] = useState('')
  const [keywordQuery, setKeywordQuery] = useState('')
  const [copiedId, setCopiedId] = useState('')

  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getUsers({ page, pageSize, keyword: keywordQuery || undefined }, token)
        if (!mounted) return
        setRecords(data.records)
        setTotal(data.total)
      } catch (e) {
        if (!mounted) return
        const msg = e instanceof Error ? e.message : '加载失败'
        setError(msg)
        if (msg.includes('未登录') || msg.includes('无权限')) logout()
      } finally {
        if (mounted) setLoading(false)
      }
    }

    load()
    return () => {
      mounted = false
    }
  }, [token, logout, page, pageSize, keywordQuery])

  const onSearch = (e: FormEvent) => {
    e.preventDefault()
    setPage(1)
    setKeywordQuery(keywordDraft.trim())
  }

  const copyId = async (id: string) => {
    try {
      await navigator.clipboard.writeText(id)
      setCopiedId(id)
      setTimeout(() => setCopiedId(''), 1200)
    } catch {
      setCopiedId('')
    }
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="mb-3 flex items-end justify-between gap-3">
        <div>
          <h2 className="text-[32px] font-bold tracking-tight text-[#172b4d]">用户管理</h2>
          <p className="mt-1 text-base text-[#6f7f99]">账号检索、付费分层与用户价值分析</p>
        </div>
        <Badge className="bg-[#eaf1ff] text-[#36507a]">{total} 位用户</Badge>
      </div>

      <form onSubmit={onSearch} className="mb-3 flex shrink-0 items-center gap-2 rounded-2xl border border-[#dbe4f2] bg-white p-3 shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        <div className="relative w-[360px]">
          <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#8aa0c2]" />
          <Input
            value={keywordDraft}
            onChange={(e) => setKeywordDraft(e.target.value)}
            placeholder="按手机号搜索"
            className="pl-9"
          />
        </div>
        <Button type="submit" size="sm">搜索</Button>
        <Button type="button" size="sm" variant="outline" onClick={() => { setKeywordDraft(''); setKeywordQuery(''); setPage(1) }}>
          <RotateCcw size={14} className="mr-1" />重置
        </Button>
      </form>

      <div className="min-h-0 flex-1 overflow-auto rounded-2xl border border-[#dbe4f2] bg-white shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        {loading ? (
          <div className="p-4 text-sm text-[#6f7f99]">正在加载用户数据...</div>
        ) : error ? (
          <div className="p-4 text-sm text-[#cf2f52]">{error}</div>
        ) : records.length === 0 ? (
          <div className="flex h-full min-h-[280px] flex-col items-center justify-center text-[#7d90b0]">
            <Users2 size={22} />
            <p className="mt-2 text-sm">暂无匹配用户</p>
          </div>
        ) : (
          <Table>
            <THead className="sticky top-0 bg-[#f7faff]">
              <tr>
                <TH>ID</TH>
                <TH>用户</TH>
                <TH>VIP</TH>
                <TH>LTV</TH>
                <TH>状态</TH>
                <TH>最近登录</TH>
              </tr>
            </THead>
            <TBody>
              {records.map((user) => (
                <tr key={user.id} className="border-b border-[#eef3fb] hover:bg-[#f9fbff]">
                  <TD>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => copyId(user.id)}
                        className="inline-flex h-7 w-7 items-center justify-center text-[#7a8dae] hover:text-[#304b73]"
                        title="复制用户ID"
                      >
                        <Tag size={14} />
                      </button>
                      {copiedId === user.id ? <span className="text-xs text-[#0f9f70]">已复制</span> : null}
                    </div>
                  </TD>
                  <TD>
                    <div className="flex items-center gap-3">
                      <Avatar name={user.displayName} />
                      <div>
                        <p className="text-sm font-semibold text-[#243a5c]">{user.displayName}</p>
                        <p className="text-xs text-[#6f7f99]">{user.phoneNumber}</p>
                      </div>
                    </div>
                  </TD>
                  <TD><VipPill vipStatus={user.vipStatus} /></TD>
                  <TD className="font-semibold text-[#213a61]">{formatCurrency(user.ltvCny)}</TD>
                  <TD className="text-[#6f7f99]">{user.status}</TD>
                  <TD>{formatTime(user.lastLoginAt)}</TD>
                </tr>
              ))}
            </TBody>
          </Table>
        )}
      </div>

      <PaginationBar
        page={page}
        total={total}
        pageSize={pageSize}
        onPageChange={setPage}
        onPageSizeChange={(next) => {
          setPage(1)
          setPageSize(next)
        }}
      />
    </div>
  )
}
