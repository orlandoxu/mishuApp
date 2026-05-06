import { DatabaseZap, LayoutDashboard, LogOut, Sparkles, Users } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { cn } from '@/lib/utils'
import { useAdminStore } from '@/store/admin-store'
import { UsersPage } from '@/pages/users/UsersPage'
import { DoubaoLogsPage } from '@/pages/doubao/DoubaoLogsPage'

function DashboardHome() {
  return (
    <div className="space-y-4">
      <div className="grid gap-4 md:grid-cols-3">
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">系统状态</p><p className="mt-2 text-3xl font-semibold text-[#162846]">Online</p></Card>
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">数据源</p><p className="mt-2 text-3xl font-semibold text-[#162846]">MongoDB</p></Card>
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">模式</p><p className="mt-2 text-3xl font-semibold text-[#162846]">Real API</p></Card>
      </div>
      <Card className="p-5">
        <h2 className="text-lg font-semibold text-[#162846]">运营概览</h2>
        <p className="mt-2 text-sm leading-6 text-[#6f7f99]">后台已切换为真实后端数据链路，用户管理与豆包日志均来自线上数据库，可继续扩展筛选、导出、权限和审计能力。</p>
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
      <aside className="border-r border-[#dbe5f3] bg-[#f8fbff] p-4">
        <div className="mb-6 flex items-center gap-3 rounded-2xl bg-white p-3 shadow-[0_14px_30px_-24px_rgba(27,57,99,0.45)]">
          <div className="rounded-xl bg-[#dffaf3] p-2 text-[#0d9488]"><Sparkles size={18} /></div>
          <div><p className="font-semibold text-[#172b4d]">Mishu Admin</p><p className="text-xs text-[#6f7f99]">后台控制台</p></div>
        </div>

        <nav className="space-y-1">
          <button onClick={() => setActiveMenu('dashboard')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', activeMenu === 'dashboard' && 'bg-[#e6eefc] text-[#14213d]')}><LayoutDashboard size={16} /> 仪表盘</button>
          <button onClick={() => setActiveMenu('users')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', activeMenu === 'users' && 'bg-[#e6eefc] text-[#14213d]')}><Users size={16} /> 用户管理</button>
          <div>
            <button onClick={() => setActiveMenu('doubao')} className={cn('flex w-full items-center gap-2 rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', activeMenu === 'doubao' && 'bg-[#e6eefc] text-[#14213d]')}><DatabaseZap size={16} /> 豆包</button>
            {activeMenu === 'doubao' ? <div className="mt-1 pl-8"><button onClick={() => setDoubaoSubMenu('logs')} className={cn('w-full rounded-lg px-2 py-1.5 text-left text-xs text-[#5e7397] hover:bg-[#edf3ff]', doubaoSubMenu === 'logs' && 'bg-[#e6eefc] text-[#14213d]')}>调用日志</button></div> : null}
          </div>
        </nav>

        <button onClick={logout} className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl border border-[#d8e0ee] bg-white py-2 text-sm text-[#344864] hover:bg-[#f2f7ff]"><LogOut size={15} /> 退出登录</button>
      </aside>

      <main className="p-5 lg:p-7">
        <header className="mb-5 flex items-center justify-between rounded-2xl border border-[#d8e0ee] bg-white px-4 py-3">
          <div><p className="text-sm text-[#6f7f99]">欢迎回来</p><p className="font-semibold text-[#172b4d]">{username}</p></div>
          <p className="text-sm text-[#6f7f99]">Mishu 智能运营后台</p>
        </header>

        {activeMenu === 'dashboard' ? <DashboardHome /> : null}
        {activeMenu === 'users' ? <UsersPage /> : null}
        {activeMenu === 'doubao' && doubaoSubMenu === 'logs' ? <DoubaoLogsPage /> : null}
      </main>
    </div>
  )
}
