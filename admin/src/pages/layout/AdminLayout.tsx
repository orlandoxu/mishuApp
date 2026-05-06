import { DatabaseZap, LayoutDashboard, LogOut, Sparkles, Users } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { useAdminStore } from '@/store/admin-store'
import { UsersPage } from '@/pages/users/UsersPage'
import { DoubaoLogsPage } from '@/pages/doubao/DoubaoLogsPage'

function DashboardHome() {
  const users = useAdminStore((s) => s.users)
  const logs = useAdminStore((s) => s.doubaoLogs)
  const successCount = logs.filter((item) => item.status === '成功').length

  const metrics = [
    { label: '注册用户', value: `${users.length}` },
    { label: '豆包总调用', value: `${logs.length}` },
    { label: '调用成功率', value: `${Math.round((successCount / logs.length) * 100)}%` },
  ]

  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-3">
        {metrics.map((item) => (
          <Card key={item.label} className="p-5">
            <p className="text-sm text-[#96aac9]">{item.label}</p>
            <p className="mt-2 text-3xl font-semibold text-white">{item.value}</p>
          </Card>
        ))}
      </div>
      <Card className="p-5">
        <h2 className="text-lg font-semibold text-white">运营概览</h2>
        <p className="mt-2 text-sm leading-6 text-[#9cb1d1]">后台已提供用户管理与豆包日志追踪能力，可作为统一运营中台，后续可继续扩展权限、筛选和告警。</p>
      </Card>
    </div>
  )
}

export function AdminLayout() {
  const activeMenu = useAdminStore((s) => s.activeMenu)
  const doubaoSubMenu = useAdminStore((s) => s.doubaoSubMenu)
  const setActiveMenu = useAdminStore((s) => s.setActiveMenu)
  const setDoubaoSubMenu = useAdminStore((s) => s.setDoubaoSubMenu)
  const username = useAdminStore((s) => s.username)
  const logout = useAdminStore((s) => s.logout)

  return (
    <div className="grid min-h-screen grid-cols-1 lg:grid-cols-[260px_1fr]">
      <aside className="border-r border-white/10 bg-[#071428]/75 p-4 backdrop-blur-xl">
        <div className="mb-6 flex items-center gap-3 rounded-2xl bg-white/5 p-3">
          <div className="rounded-xl bg-[#43d9ad]/20 p-2 text-[#6bf2c8]">
            <Sparkles size={18} />
          </div>
          <div>
            <p className="font-semibold text-white">Mishu Admin</p>
            <p className="text-xs text-[#97abca]">后台控制台</p>
          </div>
        </div>

        <nav className="space-y-1">
          <button onClick={() => setActiveMenu('dashboard')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#c6d8f6] hover:bg-white/6', activeMenu === 'dashboard' && 'bg-white/10 text-white')}>
            <LayoutDashboard size={16} /> 仪表盘
          </button>
          <button onClick={() => setActiveMenu('users')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#c6d8f6] hover:bg-white/6', activeMenu === 'users' && 'bg-white/10 text-white')}>
            <Users size={16} /> 用户管理
          </button>
          <div>
            <button onClick={() => setActiveMenu('doubao')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#c6d8f6] hover:bg-white/6', activeMenu === 'doubao' && 'bg-white/10 text-white')}>
              <DatabaseZap size={16} /> 豆包
            </button>
            {activeMenu === 'doubao' ? (
              <div className="mt-1 pl-8">
                <button
                  onClick={() => setDoubaoSubMenu('logs')}
                  className={cn('w-full rounded-lg px-2 py-1.5 text-left text-xs text-[#abc1e2] hover:bg-white/6', doubaoSubMenu === 'logs' && 'bg-white/10 text-white')}
                >
                  调用日志
                </button>
              </div>
            ) : null}
          </div>
        </nav>

        <button onClick={logout} className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl border border-white/10 bg-white/5 py-2 text-sm text-[#d7e3f8] hover:bg-white/10">
          <LogOut size={15} /> 退出登录
        </button>
      </aside>

      <main className="p-5 lg:p-7">
        <header className="mb-5 flex items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 backdrop-blur-xl">
          <div>
            <p className="text-sm text-[#95abcb]">欢迎回来</p>
            <p className="font-semibold text-white">{username}</p>
          </div>
          <p className="text-sm text-[#9bb0d0]">Mishu 智能运营后台</p>
        </header>

        {activeMenu === 'dashboard' ? <DashboardHome /> : null}
        {activeMenu === 'users' ? <UsersPage /> : null}
        {activeMenu === 'doubao' && doubaoSubMenu === 'logs' ? <DoubaoLogsPage /> : null}
      </main>
    </div>
  )
}
