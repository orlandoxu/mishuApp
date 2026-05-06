import { create } from 'zustand'
import { persist } from 'zustand/middleware'

type MainMenu = 'dashboard' | 'users' | 'doubao'
type DoubaoSubMenu = 'logs'

type AdminState = {
  isAuthed: boolean
  username: string
  token: string
  activeMenu: MainMenu
  doubaoSubMenu: DoubaoSubMenu
  setAuth: (args: { username: string; token: string }) => void
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
      token: '',
      activeMenu: DEFAULT_MENU,
      doubaoSubMenu: 'logs',
      setAuth: ({ username, token }) => set({ isAuthed: true, username, token }),
      logout: () => set({ isAuthed: false, username: '', token: '', activeMenu: DEFAULT_MENU }),
      setActiveMenu: (menu) => set({ activeMenu: menu }),
      setDoubaoSubMenu: (menu) => set({ doubaoSubMenu: menu }),
    }),
    {
      name: 'mishu-admin-store',
      partialize: (state) => ({
        isAuthed: state.isAuthed,
        username: state.username,
        token: state.token,
        activeMenu: state.activeMenu,
        doubaoSubMenu: state.doubaoSubMenu,
      }),
    },
  ),
)
