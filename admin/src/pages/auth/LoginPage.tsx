import { FormEvent, useState } from 'react'
import { Sparkles } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useAdminStore } from '@/store/admin-store'
import { adminApi } from '@/lib/api'

export function LoginPage() {
  const setAuth = useAdminStore((s) => s.setAuth)
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (submitting) return

    setSubmitting(true)
    setError('')
    try {
      const result = await adminApi.login({ username: username.trim(), password })
      setAuth(result)
    } catch (e) {
      setError(e instanceof Error ? e.message : '登录失败')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <Card className="w-full max-w-md p-7">
        <div className="mb-6 flex items-center gap-3">
          <img src="/app-logo-60.png" alt="Mishu Logo" className="h-12 w-12 rounded-2xl object-contain" />
          <div>
            <p className="text-lg font-bold text-[#172b4d]">Mishu Admin</p>
            <p className="text-sm text-[#9eb2d4]">智能后台管理系统</p>
          </div>
        </div>

        <form className="space-y-4" onSubmit={onSubmit}>
          <div>
            <p className="mb-1 text-xs uppercase tracking-wide text-[#7083a3]">账号</p>
            <Input value={username} onChange={(e) => setUsername(e.target.value)} placeholder="请输入账号" />
          </div>
          <div>
            <p className="mb-1 text-xs uppercase tracking-wide text-[#7083a3]">密码</p>
            <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="请输入密码" />
          </div>
          {error ? <p className="text-sm text-[var(--danger)]">{error}</p> : null}
          <Button className="w-full" type="submit" disabled={submitting}>
            <Sparkles size={16} className="mr-2" />
            {submitting ? '登录中...' : '登录系统'}
          </Button>
        </form>
      </Card>
    </div>
  )
}
