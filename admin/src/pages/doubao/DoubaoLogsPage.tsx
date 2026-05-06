import { FormEvent, type ReactNode, useEffect, useMemo, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PaginationBar } from '@/components/ui/pagination-bar'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { UserIdentityCell } from '@/components/user-identity'
import { adminApi, type DoubaoLogRecord } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'
import { Search, RotateCcw, DatabaseZap, Activity, Timer, Coins, AlertTriangle } from 'lucide-react'
import { toast } from '@/components/ui/toast'

function formatTime(raw: string): string {
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

function StatusPill({ success }: { success: boolean }) {
  const cls = success
    ? 'border-[#bfe9d8] bg-[#e9faf3] text-[#0f9f70]'
    : 'border-[#f5c2cc] bg-[#fff0f3] text-[#cf2f52]'
  return <span className={`inline-flex rounded-full border px-2.5 py-1 text-xs font-semibold ${cls}`}>{success ? '成功' : '失败'}</span>
}

function toDisplayText(value: unknown): string {
  if (typeof value === 'string') return value
  try {
    return JSON.stringify(value, null, 2)
  } catch {
    return String(value ?? '')
  }
}

function buildDetailContent(item: DoubaoLogRecord): string {
  const requestDetail = toDisplayText(item.requestPayload)
  const responseSource = item.responsePayload && Object.keys(item.responsePayload).length > 0
    ? item.responsePayload
    : item.responseText
  const responseDetail = toDisplayText(responseSource)
  return `【请求】\n${requestDetail || '-'}\n\n【返回】\n${responseDetail || '-'}\n\n【错误】\n${item.errorMessage || '-'}`
}

function StatCard({ title, value, sub, icon }: { title: string; value: string; sub?: string; icon: ReactNode }) {
  return (
    <div className="rounded-2xl border border-[#dbe4f2] bg-white/95 p-4 shadow-[0_10px_24px_-22px_rgba(31,54,91,0.45)]">
      <div className="mb-2 flex items-center justify-between text-[#6a7fa3]">
        <p className="text-xs font-medium tracking-wide">{title}</p>
        <span className="text-[#7f93b5]">{icon}</span>
      </div>
      <p className="text-2xl font-bold text-[#19345e]">{value}</p>
      {sub ? <p className="mt-1 text-xs text-[#7f93b5]">{sub}</p> : null}
    </div>
  )
}

export function DoubaoLogsPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const [records, setRecords] = useState<DoubaoLogRecord[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [apiTypeDraft, setApiTypeDraft] = useState('')
  const [apiTypeQuery, setApiTypeQuery] = useState('')
  const [userDraft, setUserDraft] = useState('')
  const [userQuery, setUserQuery] = useState('')
  const [expandedId, setExpandedId] = useState('')
  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getDoubaoLogs(
          { page, pageSize, apiType: apiTypeQuery || undefined, userKeyword: userQuery || undefined },
          token,
        )
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
  }, [token, logout, page, pageSize, apiTypeQuery, userQuery])

  const onSearch = (e: FormEvent) => {
    e.preventDefault()
    setPage(1)
    setApiTypeQuery(apiTypeDraft.trim())
    setUserQuery(userDraft.trim())
  }

  const copyDetail = async (item: DoubaoLogRecord) => {
    try {
      await navigator.clipboard.writeText(buildDetailContent(item))
      toast.success('已复制')
    } catch {
      toast.error('复制失败')
    }
  }

  const stats = useMemo(() => {
    const currentTotal = records.length
    const successCount = records.filter((item) => item.success).length
    const failCount = currentTotal - successCount
    const successRate = currentTotal > 0 ? ((successCount / currentTotal) * 100).toFixed(1) : '0.0'
    const avgLatency = currentTotal > 0 ? Math.round(records.reduce((acc, item) => acc + item.durationMs, 0) / currentTotal) : 0
    const tokenTotal = records.reduce((acc, item) => acc + item.totalTokens, 0)
    const p95Latency = (() => {
      const sorted = records.map((item) => item.durationMs).sort((a, b) => a - b)
      if (sorted.length === 0) return 0
      const idx = Math.max(0, Math.ceil(sorted.length * 0.95) - 1)
      return sorted[idx]
    })()

    return { currentTotal, failCount, successRate, avgLatency, tokenTotal, p95Latency }
  }, [records])

  return (
    <div className="flex h-full min-h-0 flex-col gap-4">
      <div className="flex items-end justify-between gap-3">
        <h2 className="text-[38px] font-bold tracking-tight text-[#172b4d]">豆包调用日志</h2>
        <Badge className="rounded-full bg-[#eaf1ff] px-3 py-1.5 text-base text-[#36507a]">{total} 条记录</Badge>
      </div>

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
        <StatCard title="当前页成功率" value={`${stats.successRate}%`} sub={`失败 ${stats.failCount} 条`} icon={<Activity size={16} />} />
        <StatCard title="平均耗时" value={`${stats.avgLatency}ms`} sub={`P95 ${stats.p95Latency}ms`} icon={<Timer size={16} />} />
        <StatCard title="总 Token" value={String(stats.tokenTotal)} sub={`当前页 ${stats.currentTotal} 条`} icon={<Coins size={16} />} />
        <StatCard title="异常记录" value={String(stats.failCount)} sub="建议优先排查失败详情" icon={<AlertTriangle size={16} />} />
      </div>

      <form onSubmit={onSearch} className="flex shrink-0 items-center gap-2 rounded-2xl border border-[#dbe4f2] bg-white p-3 shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        <div className="relative w-[300px]">
          <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#8aa0c2]" />
          <Input value={apiTypeDraft} onChange={(e) => setApiTypeDraft(e.target.value)} placeholder="接口类型" className="pl-9" />
        </div>
        <div className="relative w-[320px]">
          <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#8aa0c2]" />
          <Input value={userDraft} onChange={(e) => setUserDraft(e.target.value)} placeholder="用户ID或手机号" className="pl-9" />
        </div>
        <Button type="submit" size="sm">搜索</Button>
        <Button type="button" size="sm" variant="outline" onClick={() => { setApiTypeDraft(''); setApiTypeQuery(''); setUserDraft(''); setUserQuery(''); setPage(1) }}>
          <RotateCcw size={14} className="mr-1" />重置
        </Button>
      </form>

      <div className="min-h-0 flex-1 overflow-auto rounded-2xl border border-[#dbe4f2] bg-white shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        {loading ? (
          <div className="p-4 text-sm text-[#6f7f99]">正在加载调用日志...</div>
        ) : error ? (
          <div className="p-4 text-sm text-[#cf2f52]">{error}</div>
        ) : records.length === 0 ? (
          <div className="flex h-full min-h-[280px] flex-col items-center justify-center text-[#7d90b0]">
            <DatabaseZap size={22} />
            <p className="mt-2 text-sm">暂无日志记录</p>
          </div>
        ) : (
          <Table>
            <THead className="sticky top-0 bg-[#f7faff]">
              <tr>
                <TH>时间</TH>
                <TH>用户</TH>
                <TH>接口/模型</TH>
                <TH>Token</TH>
                <TH>性能</TH>
                <TH>详情</TH>
                <TH>状态</TH>
                <TH>错误</TH>
              </tr>
            </THead>
            <TBody>
              {records.flatMap((item) => {
                const rows = [
                  <tr key={item.id} className="border-b border-[#eef3fb] align-top hover:bg-[#f9fbff]">
                    <TD className="whitespace-nowrap text-sm text-[#1f3558]">{formatTime(item.createdAt)}</TD>
                    <TD>
                      <UserIdentityCell
                        name={item.userDisplayName}
                        phone={item.userPhone || '-'}
                        vipStatus={item.vipStatus}
                      />
                    </TD>
                    <TD>
                      <div className="text-sm text-[#263d63]">
                        <p className="font-medium">{item.apiType}</p>
                        <p className="text-[#6f7f99]">{item.modelId}</p>
                      </div>
                    </TD>
                    <TD className="text-sm text-[#263d63]">
                      <p>{item.inputTokens}/{item.outputTokens}/{item.totalTokens}</p>
                      <p className="text-xs text-[#7f93b5]">{item.tokenSource === 'provider' ? '官方' : '估算'}</p>
                    </TD>
                    <TD className="whitespace-nowrap text-sm font-medium text-[#1f3558]">{item.durationMs}ms</TD>
                    <TD>
                      <button
                        onClick={() => setExpandedId(expandedId === item.id ? '' : item.id)}
                        className="rounded-lg border border-[#d8e0ee] px-2.5 py-1 text-xs text-[#3a5175] hover:bg-[#f4f8ff]"
                      >
                        {expandedId === item.id ? '收起详情' : '查看详情'}
                      </button>
                    </TD>
                    <TD><StatusPill success={item.success} /></TD>
                    <TD className="max-w-[220px] truncate text-sm text-[#324b70]">{item.errorMessage || '-'}</TD>
                  </tr>,
                ]

                if (expandedId !== item.id) return rows

                rows.push(
                  <tr key={`${item.id}-detail`} className="border-b border-[#eef3fb] bg-[#f8fbff]">
                    <td colSpan={8} className="px-4 py-3">
                      <div className="rounded-xl border border-[#d7e2f3] bg-white p-3">
                        <div className="mb-2 flex items-center justify-between">
                          <p className="text-sm font-semibold text-[#19345e]">请求与返回详情</p>
                          <button
                            onClick={() => copyDetail(item)}
                            className="rounded-lg border border-[#d8e0ee] px-2.5 py-1 text-xs text-[#3a5175] hover:bg-[#f4f8ff]"
                          >
                            复制内容
                          </button>
                        </div>
                        <pre className="max-h-72 overflow-auto whitespace-pre-wrap break-all rounded-lg bg-[#f5f8ff] p-2 text-xs text-[#2d4266]">{buildDetailContent(item)}</pre>
                      </div>
                    </td>
                  </tr>,
                )
                return rows
              })}
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
