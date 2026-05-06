import { FormEvent, useEffect, useMemo, useState } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { PaginationBar } from '@/components/ui/pagination-bar'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { UserIdentityCell } from '@/components/user-identity'
import { adminApi, type AdminUserRecord, type AdminUsersSummary } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'
import { Search, RotateCcw, Users2, Tag, Ban } from 'lucide-react'
import { toast } from '@/components/ui/toast'

function formatTime(raw: string | null): string {
  if (!raw) return '-'
  return new Date(raw).toLocaleString('zh-CN', { hour12: false })
}

function formatCurrency(value: number): string {
  return value > 0 ? `¥${value.toFixed(2)}` : '¥0.00'
}

const defaultSummary: AdminUsersSummary = {
  totalUsers: 0,
  totalLtvCny: 0,
  paidUsers: 0,
  vipUsers: 0,
  svipUsers: 0,
  disabledUsers: 0,
}

export function UsersPage() {
  const token = useAdminStore((s) => s.token)
  const logout = useAdminStore((s) => s.logout)
  const openOrdersByUser = useAdminStore((s) => s.openOrdersByUser)
  const [records, setRecords] = useState<AdminUserRecord[]>([])
  const [summary, setSummary] = useState<AdminUsersSummary>(defaultSummary)
  const [total, setTotal] = useState(0)
  const [listLoading, setListLoading] = useState(true)
  const [summaryLoading, setSummaryLoading] = useState(true)
  const [error, setError] = useState('')
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(10)
  const [keywordDraft, setKeywordDraft] = useState('')
  const [keywordQuery, setKeywordQuery] = useState('')
  const loadUsers = async () => {
    setListLoading(true)
    setError('')
    try {
      const data = await adminApi.getUsers({ page, pageSize, keyword: keywordQuery || undefined }, token)
      setRecords(data.records)
      setTotal(data.total)
    } catch (e) {
      const msg = e instanceof Error ? e.message : '加载失败'
      setError(msg)
      if (msg.includes('未登录') || msg.includes('无权限')) logout()
    } finally {
      setListLoading(false)
    }
  }

  const loadSummary = async () => {
    setSummaryLoading(true)
    try {
      const data = await adminApi.getUsersSummary({}, token)
      setSummary(data)
    } catch {
      setSummary(defaultSummary)
    } finally {
      setSummaryLoading(false)
    }
  }

  useEffect(() => {
    loadUsers()
  }, [token, page, pageSize, keywordQuery])

  useEffect(() => {
    loadSummary()
  }, [token])

  const onSearch = (e: FormEvent) => {
    e.preventDefault()
    setPage(1)
    setKeywordQuery(keywordDraft.trim())
  }

  const copyId = async (id: string) => {
    try {
      await navigator.clipboard.writeText(id)
      toast.success('已复制')
    } catch {
      toast.error('复制失败')
    }
  }

  const toggleStatus = async (userId: string) => {
    try {
      await adminApi.toggleUserStatus({ userId }, token)
      await Promise.all([loadUsers(), loadSummary()])
    } catch (e) {
      const msg = e instanceof Error ? e.message : '操作失败'
      setError(msg)
    }
  }

  const vipRatio = useMemo(() => {
    if (!summary.totalUsers) return '0%'
    return `${Math.round(((summary.vipUsers + summary.svipUsers) / summary.totalUsers) * 100)}%`
  }, [summary.vipUsers, summary.svipUsers, summary.totalUsers])

  const paidRatio = useMemo(() => {
    if (!summary.totalUsers) return '0%'
    return `${((summary.paidUsers / summary.totalUsers) * 100).toFixed(1)}%`
  }, [summary.paidUsers, summary.totalUsers])

  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="mb-4 flex items-end justify-between gap-3">
        <div>
          <h2 className="text-[32px] font-bold tracking-tight text-[#172b4d]">用户管理</h2>
          <p className="mt-1 text-base text-[#6d82a6]">账号检索、会员分层与用户价值分析</p>
        </div>
        <Badge className="bg-[#eaf1ff] text-[#36507a]">{total} 位用户</Badge>
      </div>

      <div className="mb-3 grid grid-cols-1 gap-3 lg:grid-cols-3">
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#f2fffb] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">付费用户</p>
          <p className="mt-1 text-2xl font-bold text-[#146b5b]">{summaryLoading ? '--' : summary.paidUsers}</p>
        </div>
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#eefaf6] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">付费率</p>
          <p className="mt-1 text-2xl font-bold text-[#17806b]">{summaryLoading ? '--' : paidRatio}</p>
        </div>
        <div className="rounded-2xl border border-[#d8e4f6] bg-gradient-to-br from-[#ffffff] to-[#f5f4ff] p-4">
          <p className="text-xs font-medium text-[#6f7f99]">VIP 占比</p>
          <p className="mt-1 text-2xl font-bold text-[#4f43a6]">{summaryLoading ? '--' : vipRatio}</p>
        </div>
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
        {listLoading ? (
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
            <THead className="sticky top-0 z-10 bg-[#f5f9ff]">
              <tr>
                <TH className="w-[64px]">ID</TH>
                <TH>用户</TH>
                <TH>LTV</TH>
                <TH>最近登录</TH>
                <TH className="w-[100px]">操作</TH>
              </tr>
            </THead>
            <TBody>
              {records.map((user) => (
                <tr key={user.id} className="border-b border-[#eef3fb] hover:bg-[#f9fbff]">
                  <TD>
                    <button
                      onClick={() => copyId(user.id)}
                      className="inline-flex h-7 w-7 items-center justify-center text-[#7a8dae] hover:text-[#304b73]"
                      title="复制用户ID"
                    >
                      <Tag size={14} />
                    </button>
                  </TD>
                  <TD>
                    <UserIdentityCell name={user.displayName} phone={user.phoneNumber} vipStatus={user.vipStatus} />
                  </TD>
                  <TD>
                    <button
                      onClick={() => openOrdersByUser(user.id)}
                      className="font-semibold text-[#1c4e8d] hover:text-[#0e7490] hover:underline"
                      title="查看该用户订单"
                    >
                      {formatCurrency(user.ltvCny)}
                    </button>
                  </TD>
                  <TD>{formatTime(user.lastLoginAt)}</TD>
                  <TD>
                    {user.status === '正常' ? (
                      <button
                        onClick={() => toggleStatus(user.id)}
                        className="rounded-lg border border-[#d8e0ee] px-2.5 py-1 text-xs text-[#3a5175] hover:bg-[#f4f8ff]"
                      >
                        禁用
                      </button>
                    ) : (
                      <button
                        onClick={() => toggleStatus(user.id)}
                        className="inline-flex items-center gap-1 rounded-lg border border-[#e6c7c7] bg-[#fff8f8] px-2.5 py-1 text-xs text-[#8b4955] hover:bg-[#fff1f1]"
                        title="该用户当前处于禁用状态，点击解封"
                      >
                        <Ban size={12} />
                        解封
                      </button>
                    )}
                  </TD>
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
