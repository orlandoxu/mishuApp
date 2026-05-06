import { FormEvent, useEffect, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PaginationBar } from '@/components/ui/pagination-bar'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { adminApi, type DoubaoLogRecord } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'
import { Search, RotateCcw, DatabaseZap } from 'lucide-react'

function formatTime(raw: string): string {
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

function StatusPill({ success }: { success: boolean }) {
  const cls = success ? 'bg-[#e8fbf3] text-[#0f9f70]' : 'bg-[#ffecef] text-[#cf2f52]'
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${cls}`}>{success ? '成功' : '失败'}</span>
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

  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getDoubaoLogs({ page, pageSize, apiType: apiTypeQuery || undefined }, token)
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
  }, [token, logout, page, pageSize, apiTypeQuery])

  const onSearch = (e: FormEvent) => {
    e.preventDefault()
    setPage(1)
    setApiTypeQuery(apiTypeDraft.trim())
  }

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="mb-3 flex items-end justify-between gap-3">
        <div>
          <h2 className="text-[32px] font-bold tracking-tight text-[#172b4d]">豆包调用日志</h2>
          <p className="mt-1 text-base text-[#6f7f99]">接口调用稳定性、时延与错误分析</p>
        </div>
        <Badge className="bg-[#eaf1ff] text-[#36507a]">{total} 条记录</Badge>
      </div>

      <form onSubmit={onSearch} className="mb-3 flex shrink-0 items-center gap-2 rounded-2xl border border-[#dbe4f2] bg-white p-3 shadow-[0_10px_28px_-22px_rgba(31,54,91,0.35)]">
        <div className="relative w-[420px]">
          <Search size={16} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#8aa0c2]" />
          <Input
            value={apiTypeDraft}
            onChange={(e) => setApiTypeDraft(e.target.value)}
            placeholder="按接口类型搜索，如 chat_completion"
            className="pl-9"
          />
        </div>
        <Button type="submit" size="sm">搜索</Button>
        <Button type="button" size="sm" variant="outline" onClick={() => { setApiTypeDraft(''); setApiTypeQuery(''); setPage(1) }}>
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
                <TH>日志ID</TH>
                <TH>接口类型</TH>
                <TH>模型</TH>
                <TH>耗时</TH>
                <TH>状态</TH>
                <TH>错误信息</TH>
                <TH>时间</TH>
              </tr>
            </THead>
            <TBody>
              {records.map((item) => (
                <tr key={item.id} className="border-b border-[#eef3fb] hover:bg-[#f9fbff]">
                  <TD className="font-mono text-xs">{item.id}</TD>
                  <TD>{item.apiType}</TD>
                  <TD>{item.modelId}</TD>
                  <TD>{item.durationMs}ms</TD>
                  <TD><StatusPill success={item.success} /></TD>
                  <TD className="max-w-[300px] truncate">{item.errorMessage || '-'}</TD>
                  <TD>{formatTime(item.createdAt)}</TD>
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
