import { useEffect, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { adminApi, type DoubaoLogRecord } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'

function formatTime(raw: string): string {
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

export function DoubaoLogsPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const [records, setRecords] = useState<DoubaoLogRecord[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getDoubaoLogs({ page: 1, pageSize: 50 }, token)
        if (!mounted) return
        setRecords(data.records)
        setTotal(data.total)
      } catch (e) {
        if (!mounted) return
        const msg = e instanceof Error ? e.message : '加载失败'
        setError(msg)
        if (msg.includes('未登录') || msg.includes('无权限')) {
          logout()
        }
      } finally {
        if (mounted) setLoading(false)
      }
    }

    load()
    return () => {
      mounted = false
    }
  }, [token, logout])

  return (
    <Card className="p-5">
      <div className="mb-4 flex items-end justify-between">
        <div>
          <h2 className="text-lg font-semibold text-[#172b4d]">豆包调用日志</h2>
          <p className="text-sm text-[#6f7f99]">实时读取后端日志记录</p>
        </div>
        <Badge>{total} 条记录</Badge>
      </div>

      {loading ? <p className="text-sm text-[#6f7f99]">加载中...</p> : null}
      {error ? <p className="text-sm text-[#ff90a3]">{error}</p> : null}

      {!loading && !error ? (
        <div className="overflow-auto">
          <Table>
            <THead>
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
                <tr key={item.id} className="hover:bg-white/5">
                  <TD>{item.id}</TD>
                  <TD>{item.apiType}</TD>
                  <TD>{item.modelId}</TD>
                  <TD>{item.durationMs}ms</TD>
                  <TD>
                    <span className={item.success ? 'text-[#64e3be]' : 'text-[#ff90a3]'}>{item.success ? '成功' : '失败'}</span>
                  </TD>
                  <TD>{item.errorMessage || '-'}</TD>
                  <TD>{formatTime(item.createdAt)}</TD>
                </tr>
              ))}
            </TBody>
          </Table>
        </div>
      ) : null}
    </Card>
  )
}
