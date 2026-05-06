import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { mockDoubaoLogs, mockUsers } from '@/data/mock'

type MainMenu = 'dashboard' | 'users' | 'doubao'
type DoubaoSubMenu = 'logs'

type AdminState = {
  isAuthed: boolean
  username: string
  activeMenu: MainMenu
  doubaoSubMenu: DoubaoSubMenu
  users: typeof mockUsers
  doubaoLogs: typeof mockDoubaoLogs
  login: (username: string, password: string) => { ok: boolean; message: string }
  logout: () => void
  setActiveMenu: (menu: MainMenu) => void
  setDoubaoSubMenu: (menu: DoubaoSubMenu) => void
}

const DEFAULT_MENU: MainMenu = 'dashboard'

export const useAdminStore = create<AdminState>()(
  persist(
    (set) => ({
      isAuthed: false,
      username: '',
      activeMenu: DEFAULT_MENU,
      doubaoSubMenu: 'logs',
      users: mockUsers,
      doubaoLogs: mockDoubaoLogs,
      login: (username, password) => {
        if (username === 'admin' && password === 'admin123!') {
          set({ isAuthed: true, username: 'admin' })
          return { ok: true, message: '登录成功' }
        }
        return { ok: false, message: '账号或密码错误' }
      },
      logout: () => set({ isAuthed: false, username: '', activeMenu: DEFAULT_MENU }),
      setActiveMenu: (menu) => set({ activeMenu: menu }),
      setDoubaoSubMenu: (menu) => set({ doubaoSubMenu: menu }),
    }),
    {
      name: 'mishu-admin-store',
      partialize: (state) => ({
        isAuthed: state.isAuthed,
        username: state.username,
        activeMenu: state.activeMenu,
        doubaoSubMenu: state.doubaoSubMenu,
      }),
    },
  ),
)
