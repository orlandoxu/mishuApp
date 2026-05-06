import { DatabaseZap, LayoutDashboard, LogOut, Sparkles, Users } from 'lucide-react'
import { UserCircle2, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react'
import { useState } from 'react'
import { cn } from '@/lib/utils'
import { useAdminStore } from '@/store/admin-store'
import { UsersPage } from '@/pages/users/UsersPage'
import { DoubaoLogsPage } from '@/pages/doubao/DoubaoLogsPage'
import { DashboardHome } from '@/pages/layout/DashboardHome'

export function AdminLayout() {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const activeMenu = useAdminStore((s) => s.activeMenu)
  const doubaoSubMenu = useAdminStore((s) => s.doubaoSubMenu)
  const setActiveMenu = useAdminStore((s) => s.setActiveMenu)
  const setDoubaoSubMenu = useAdminStore((s) => s.setDoubaoSubMenu)
  const username = useAdminStore((s) => s.username)
  const logout = useAdminStore((s) => s.logout)

  return (
    <div className="min-h-screen">
      <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-[#dbe5f3] bg-white px-5">
        <div className="flex items-center gap-3">
          <div className="rounded-xl bg-[#dffaf3] p-2 text-[#0d9488]"><Sparkles size={18} /></div>
          <div>
            <p className="text-lg font-semibold text-[#172b4d]">Mishu Admin</p>
            <p className="text-xs text-[#6f7f99]">后台控制台</p>
          </div>
        </div>

        <div className="relative">
          <button
            onClick={() => setMenuOpen((v) => !v)}
            onBlur={() => setTimeout(() => setMenuOpen(false), 120)}
            className="group flex items-center gap-2 rounded-xl border border-[#d8e0ee] bg-white px-3 py-2 hover:bg-[#f6faff]"
          >
            <UserCircle2 size={20} className="text-[#4f6486] group-hover:text-[#1f3a65]" />
            <div className="text-left">
              <p className="text-sm font-medium text-[#1f3558]">{username}</p>
            </div>
            <ChevronDown size={14} className="text-[#6f7f99]" />
          </button>
          {menuOpen ? (
            <div className="absolute right-0 mt-2 w-40 rounded-xl border border-[#d8e0ee] bg-white p-1 shadow-[0_18px_40px_-24px_rgba(27,57,99,0.4)]">
              <button
                onClick={logout}
                className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-sm text-[#324b70] hover:bg-[#f2f7ff]"
              >
                <LogOut size={14} /> 退出登录
              </button>
            </div>
          ) : null}
        </div>
      </header>

      <div
        className="relative grid h-[calc(100vh-4rem)]"
        style={{
          gridTemplateColumns: sidebarCollapsed ? '84px 1fr' : '260px 1fr',
        }}
      >
        <button
          onClick={() => setSidebarCollapsed((v) => !v)}
          className="absolute top-6 z-10 inline-flex h-8 w-8 -translate-x-1/2 items-center justify-center rounded-full border border-[#d8e0ee] bg-white text-[#51688c] shadow-sm hover:bg-[#f2f7ff]"
          style={{ left: sidebarCollapsed ? 84 : 260 }}
          aria-label={sidebarCollapsed ? '展开菜单' : '收起菜单'}
        >
          {sidebarCollapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
        </button>

        <aside className="sticky top-16 h-[calc(100vh-4rem)] border-r border-[#dbe5f3] bg-[#f8fbff] p-4">
        <nav className="space-y-1">
          <button onClick={() => setActiveMenu('dashboard')} className={cn('flex w-full items-center rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', sidebarCollapsed ? 'justify-center' : 'gap-2', activeMenu === 'dashboard' && 'bg-[#e6eefc] text-[#14213d]')}><LayoutDashboard size={16} />{!sidebarCollapsed ? ' 仪表盘' : null}</button>
          <button onClick={() => setActiveMenu('users')} className={cn('flex w-full items-center rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', sidebarCollapsed ? 'justify-center' : 'gap-2', activeMenu === 'users' && 'bg-[#e6eefc] text-[#14213d]')}><Users size={16} />{!sidebarCollapsed ? ' 用户管理' : null}</button>
          <div>
            <button onClick={() => setActiveMenu('doubao')} className={cn('flex w-full items-center rounded-xl px-3 py-2 text-sm text-[#4e5f7d] hover:bg-[#edf3ff]', sidebarCollapsed ? 'justify-center' : 'gap-2', activeMenu === 'doubao' && 'bg-[#e6eefc] text-[#14213d]')}><DatabaseZap size={16} />{!sidebarCollapsed ? ' 豆包' : null}</button>
            {activeMenu === 'doubao' && !sidebarCollapsed ? <div className="mt-1 pl-8"><button onClick={() => setDoubaoSubMenu('logs')} className={cn('w-full rounded-lg px-2 py-1.5 text-left text-xs text-[#5e7397] hover:bg-[#edf3ff]', doubaoSubMenu === 'logs' && 'bg-[#e6eefc] text-[#14213d]')}>调用日志</button></div> : null}
          </div>
        </nav>

      </aside>

        <main className="min-w-0 overflow-y-auto p-5 lg:p-7">
          {activeMenu === 'dashboard' ? <DashboardHome /> : null}
          {activeMenu === 'users' ? <UsersPage /> : null}
          {activeMenu === 'doubao' && doubaoSubMenu === 'logs' ? <DoubaoLogsPage /> : null}
        </main>
      </div>
    </div>
  )
}
