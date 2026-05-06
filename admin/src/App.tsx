import { LoginPage } from '@/pages/auth/LoginPage'
import { AdminLayout } from '@/pages/layout/AdminLayout'
import { useAdminStore } from '@/store/admin-store'

export function App() {
  const isAuthed = useAdminStore((s) => s.isAuthed)
  return isAuthed ? <AdminLayout /> : <LoginPage />
}
