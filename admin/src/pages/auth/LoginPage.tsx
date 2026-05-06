import { FormEvent, useState } from 'react'
import { ShieldCheck, Sparkles } from 'lucide-react'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { useAdminStore } from '@/store/admin-store'

export function LoginPage() {
  const login = useAdminStore((s) => s.login)
  const [username, setUsername] = useState('admin')
  const [password, setPassword] = useState('admin123!')
  const [error, setError] = useState('')

  const onSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const result = login(username.trim(), password)
    if (!result.ok) {
      setError(result.message)
      return
    }
    setError('')
  }

  return (
    <div className="flex min-h-screen items-center justify-center px-4 py-10">
      <Card className="w-full max-w-md p-7">
        <div className="mb-6 flex items-center gap-3">
          <div className="rounded-xl bg-[#43d9ad]/20 p-2 text-[#63efc3]">
            <ShieldCheck size={22} />
          </div>
          <div>
            <p className="text-lg font-bold text-white">Mishu Admin</p>
            <p className="text-sm text-[#9eb2d4]">智能后台管理系统</p>
          </div>
        </div>

        <form className="space-y-4" onSubmit={onSubmit}>
          <div>
            <p className="mb-1 text-xs uppercase tracking-wide text-[#8ea3c3]">账号</p>
            <Input value={username} onChange={(e) => setUsername(e.target.value)} placeholder="请输入账号" />
          </div>
          <div>
            <p className="mb-1 text-xs uppercase tracking-wide text-[#8ea3c3]">密码</p>
            <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="请输入密码" />
          </div>
          {error ? <p className="text-sm text-[var(--danger)]">{error}</p> : null}
          <Button className="w-full" type="submit">
            <Sparkles size={16} className="mr-2" />
            登录系统
          </Button>
        </form>

        <p className="mt-5 text-xs text-[#93a7c8]">测试账号：admin / admin123!</p>
      </Card>
    </div>
  )
}
