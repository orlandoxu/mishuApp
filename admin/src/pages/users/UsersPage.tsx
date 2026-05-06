import { useEffect, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { adminApi, type AdminUserRecord } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'

function formatTime(raw: string | null): string {
  if (!raw) return '-'
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

export function UsersPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const [records, setRecords] = useState<AdminUserRecord[]>([])
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let mounted = true
    const load = async () => {
      setLoading(true)
      setError('')
      try {
        const data = await adminApi.getUsers({ page: 1, pageSize: 50 }, token)
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
          <h2 className="text-lg font-semibold text-[#172b4d]">用户管理</h2>
          <p className="text-sm text-[#6f7f99]">实时读取后端用户数据</p>
        </div>
        <Badge>{total} 位用户</Badge>
      </div>

      {loading ? <p className="text-sm text-[#6f7f99]">加载中...</p> : null}
      {error ? <p className="text-sm text-[#ff90a3]">{error}</p> : null}

      {!loading && !error ? (
        <div className="overflow-auto">
          <Table>
            <THead>
              <tr>
                <TH>用户ID</TH>
                <TH>手机号</TH>
                <TH>角色</TH>
                <TH>状态</TH>
                <TH>创建时间</TH>
                <TH>最近登录</TH>
              </tr>
            </THead>
            <TBody>
              {records.map((user) => (
                <tr key={user.id} className="hover:bg-white/5">
                  <TD>{user.id}</TD>
                  <TD>{user.phoneNumber}</TD>
                  <TD>{user.role}</TD>
                  <TD>
                    <span className={user.status === '正常' ? 'text-[#64e3be]' : 'text-[#ff90a3]'}>{user.status}</span>
                  </TD>
                  <TD>{formatTime(user.createdAt)}</TD>
                  <TD>{formatTime(user.lastLoginAt)}</TD>
                </tr>
              ))}
            </TBody>
          </Table>
        </div>
      ) : null}
    </Card>
  )
}
