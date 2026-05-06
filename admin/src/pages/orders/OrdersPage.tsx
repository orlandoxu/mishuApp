import { FormEvent, useEffect, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PaginationBar } from '@/components/ui/pagination-bar'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { UserIdentityCell } from '@/components/user-identity'
import { adminApi, type AdminOrderRecord, type AdminOrdersQuery, type AdminOrdersSummary } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'
import { Search, RotateCcw } from 'lucide-react'

function fmt(raw: string) {
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

function fmtRelative(raw: string) {
  const target = new Date(raw).getTime()
  const now = Date.now()
  const diffMs = target - now
  const diffSec = Math.round(diffMs / 1000)
  const absSec = Math.abs(diffSec)
  if (absSec < 60) return '刚刚'

  const units: Array<{ unit: Intl.RelativeTimeFormatUnit; seconds: number }> = [
    { unit: 'year', seconds: 365 * 24 * 60 * 60 },
    { unit: 'month', seconds: 30 * 24 * 60 * 60 },
    { unit: 'day', seconds: 24 * 60 * 60 },
    { unit: 'hour', seconds: 60 * 60 },
    { unit: 'minute', seconds: 60 },
  ]
  const rtf = new Intl.RelativeTimeFormat('zh-CN', { numeric: 'auto' })
  for (const { unit, seconds } of units) {
    if (absSec >= seconds) {
      return rtf.format(Math.round(diffSec / seconds), unit)
    }
  }
  return '刚刚'
}

function payMethodLabel(payMethod: AdminOrderRecord['payMethod']) {
  if (payMethod === 'alipay') return '支付宝'
  if (payMethod === 'apple') return '苹果支付'
  return '微信'
}

function payMethodClass(payMethod: AdminOrderRecord['payMethod']) {
  if (payMethod === 'alipay') return 'bg-[#eaf4ff] text-[#1f5fa8]'
  if (payMethod === 'apple') return 'bg-[#f0f1f5] text-[#343b4a]'
  return 'bg-[#e9f8f2] text-[#1b7c5a]'
}

const defaultSummary: AdminOrdersSummary = {
  totalAmountCny: 0,
  paidCount: 0,
  pendingCount: 0,
  yearlyCount: 0,
}

export function OrdersPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const orderUserIdFilter = useAdminStore((s) => s.orderUserIdFilter)
  const clearOrderUserFilter = useAdminStore((s) => s.clearOrderUserFilter)

  const [records, setRecords] = useState<AdminOrderRecord[]>([])
  const [summary, setSummary] = useState<AdminOrdersSummary>(defaultSummary)
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [query, setQuery] = useState<AdminOrdersQuery>({ userId: orderUserIdFilter || undefined })
  const [draft, setDraft] = useState({
    userId: orderUserIdFilter,
    phoneNumber: '',
    orderId: '',
    payMethod: '',
    planId: '',
    orderStatus: '',
    startAt: '',
    endAt: '',
  })

  useEffect(() => {
    setDraft((prev) => ({ ...prev, userId: orderUserIdFilter }))
    setQuery((prev) => ({ ...prev, userId: orderUserIdFilter || undefined }))
    setPage(1)
  }, [orderUserIdFilter])

  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getOrders({ page, pageSize, ...query }, token)
        if (!mounted) return
        setRecords(data.records)
        setTotal(data.total)
        setSummary(data.summary)
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
  }, [token, logout, page, pageSize, query])

  const onSearch = (e: FormEvent) => {
    e.preventDefault()
    setPage(1)
    setQuery({
      userId: draft.userId.trim() || undefined,
      phoneNumber: draft.phoneNumber.trim() || undefined,
      orderId: draft.orderId.trim() || undefined,
      payMethod: (draft.payMethod || undefined) as AdminOrdersQuery['payMethod'],
      planId: (draft.planId || undefined) as AdminOrdersQuery['planId'],
      orderStatus: (draft.orderStatus || undefined) as AdminOrdersQuery['orderStatus'],
      startAt: draft.startAt ? new Date(draft.startAt).toISOString() : undefined,
      endAt: draft.endAt ? new Date(draft.endAt).toISOString() : undefined,
    })
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="mb-4 flex items-end justify-between gap-3">
        <div>
          <h2 className="text-[32px] font-bold tracking-tight text-[#172b4d]">订单管理</h2>
          <p className="mt-1 text-base text-[#6d82a6]">会员订单、支付状态与续费周期管理</p>
        </div>
        <Badge className="bg-[#eaf1ff] text-[#36507a]">{total} 条订单</Badge>
      </div>

      <div className="mb-3 grid grid-cols-1 gap-3 lg:grid-cols-3">
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#f3f9ff] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">订单总金额</p>
          <p className="mt-1 text-2xl font-bold text-[#153257]">¥{summary.totalAmountCny.toFixed(2)}</p>
        </div>
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#f2fffb] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">已支付订单</p>
          <p className="mt-1 text-2xl font-bold text-[#146b5b]">{summary.paidCount}</p>
        </div>
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#f5f4ff] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">年度会员订单</p>
          <p className="mt-1 text-2xl font-bold text-[#4f43a6]">{summary.yearlyCount}</p>
        </div>
      </div>

      <form onSubmit={onSearch} className="mb-3 grid shrink-0 grid-cols-1 gap-2 rounded-2xl border border-[#dbe4f2] bg-white p-3 shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)] md:grid-cols-2 xl:grid-cols-4">
        <div className="relative">
          <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#8aa0c2]" />
          <Input value={draft.phoneNumber} onChange={(e) => setDraft((prev) => ({ ...prev, phoneNumber: e.target.value }))} placeholder="手机号" className="pl-9" />
        </div>
        <Input value={draft.orderId} onChange={(e) => setDraft((prev) => ({ ...prev, orderId: e.target.value }))} placeholder="订单ID / 第三方单号" />
        <select className="h-11 rounded-xl border border-[var(--border)] bg-white px-3 text-sm text-[var(--foreground)] outline-none focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/20" value={draft.payMethod} onChange={(e) => setDraft((prev) => ({ ...prev, payMethod: e.target.value }))}>
          <option value="">支付方式（全部）</option>
          <option value="wechat">微信</option>
          <option value="alipay">支付宝</option>
          <option value="apple">苹果支付</option>
        </select>
        <select className="h-11 rounded-xl border border-[var(--border)] bg-white px-3 text-sm text-[var(--foreground)] outline-none focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/20" value={draft.planId} onChange={(e) => setDraft((prev) => ({ ...prev, planId: e.target.value }))}>
          <option value="">套餐（全部）</option>
          <option value="monthly">月度会员</option>
          <option value="yearly">年度会员</option>
        </select>
        <select className="h-11 rounded-xl border border-[var(--border)] bg-white px-3 text-sm text-[var(--foreground)] outline-none focus:border-[#14b8a6] focus:ring-2 focus:ring-[#14b8a6]/20" value={draft.orderStatus} onChange={(e) => setDraft((prev) => ({ ...prev, orderStatus: e.target.value }))}>
          <option value="">支付状态（全部）</option>
          <option value="paid">已支付</option>
          <option value="pending">待支付</option>
          <option value="refunded">已退款</option>
        </select>
        <Input value={draft.userId} onChange={(e) => setDraft((prev) => ({ ...prev, userId: e.target.value }))} placeholder="用户ID（可选）" />
        <Input type="datetime-local" value={draft.startAt} onChange={(e) => setDraft((prev) => ({ ...prev, startAt: e.target.value }))} />
        <Input type="datetime-local" value={draft.endAt} onChange={(e) => setDraft((prev) => ({ ...prev, endAt: e.target.value }))} />
        <div className="flex items-center gap-2">
          <Button type="submit" size="sm">搜索</Button>
          <Button type="button" size="sm" variant="outline" onClick={() => {
            clearOrderUserFilter()
            setDraft({
              userId: '',
              phoneNumber: '',
              orderId: '',
              payMethod: '',
              planId: '',
              orderStatus: '',
              startAt: '',
              endAt: '',
            })
            setQuery({})
            setPage(1)
          }}>
          <RotateCcw size={14} className="mr-1" />重置
        </Button>
        </div>
      </form>

      <div className="min-h-0 flex-1 overflow-auto rounded-2xl border border-[#dbe4f2] bg-white shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        {loading ? <div className="p-4 text-sm text-[#6f7f99]">正在加载订单...</div> : null}
        {error ? <div className="p-4 text-sm text-[#cf2f52]">{error}</div> : null}
        {!loading && !error ? (
          <Table>
            <THead className="sticky top-0 bg-[#f5f9ff]">
              <tr>
                <TH>订单号</TH>
                <TH>用户信息</TH>
                <TH>套餐</TH>
                <TH>金额</TH>
                <TH>支付信息</TH>
                <TH>支付时间</TH>
              </tr>
            </THead>
            <TBody>
              {records.map((o) => (
                <tr key={o.orderId} className="border-b border-[#eef3fb] hover:bg-[#f9fbff]">
                  <TD className="font-mono text-xs">
                    <div className="space-y-1">
                      <p>{o.thirdPartyOrderId}</p>
                      <p className="text-[11px] text-[#6f7f99]">{o.mongoOrderId}</p>
                    </div>
                  </TD>
                  <TD>
                    <UserIdentityCell name={o.userName} phone={o.phoneNumber} vipStatus={o.vipStatus} />
                  </TD>
                  <TD>
                    <span className={`rounded-full px-2 py-1 text-[11px] font-medium ${o.planId === 'yearly' ? 'bg-[#ede9ff] text-[#5b4bb7]' : 'bg-[#e8f6ff] text-[#1d5f8b]'}`}>
                      {o.planName}
                    </span>
                  </TD>
                  <TD className="font-semibold text-[#1c4e8d]">¥{o.amountCny.toFixed(2)}</TD>
                  <TD>
                    <div className="flex flex-wrap items-center gap-1.5 text-[11px] font-medium">
                      <span
                        className={`rounded-full px-2 py-0.5 ${
                          o.orderStatus === 'paid'
                            ? 'bg-[#e8f8f0] text-[#17774b]'
                            : o.orderStatus === 'refunded'
                              ? 'bg-[#ffeff3] text-[#b83f5e]'
                              : 'bg-[#fff4e8] text-[#9b6115]'
                        }`}
                      >
                        {o.orderStatus === 'paid' ? '已支付' : o.orderStatus === 'refunded' ? '已退款' : '待支付'}
                      </span>
                      <span className={`rounded-full px-2 py-0.5 ${payMethodClass(o.payMethod)}`}>
                        {payMethodLabel(o.payMethod)}
                      </span>
                    </div>
                  </TD>
                  <TD>
                    <div className="flex flex-col">
                      <span className="text-sm font-semibold text-[#243a5c]">{fmtRelative(o.paidAt)}</span>
                      <span className="text-xs text-[#6f7f99]">{fmt(o.paidAt)}</span>
                    </div>
                  </TD>
                </tr>
              ))}
            </TBody>
          </Table>
        ) : null}
      </div>

      <PaginationBar page={page} total={total} pageSize={pageSize} onPageChange={setPage} onPageSizeChange={(next) => { setPage(1); setPageSize(next) }} />
    </div>
  )
}
