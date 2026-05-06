import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { useAdminStore } from '@/store/admin-store'

export function UsersPage() {
  const users = useAdminStore((s) => s.users)

  return (
    <Card className="p-5">
      <div className="mb-4 flex items-end justify-between">
        <div>
          <h2 className="text-lg font-semibold text-white">用户管理</h2>
          <p className="text-sm text-[#95a9c8]">查看账号状态、角色与创建时间</p>
        </div>
        <Badge>{users.length} 位用户</Badge>
      </div>
      <div className="overflow-auto">
        <Table>
          <THead>
            <tr>
              <TH>用户ID</TH>
              <TH>昵称</TH>
              <TH>手机号</TH>
              <TH>角色</TH>
              <TH>状态</TH>
              <TH>创建时间</TH>
            </tr>
          </THead>
          <TBody>
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-white/5">
                <TD>{user.id}</TD>
                <TD>{user.name}</TD>
                <TD>{user.phone}</TD>
                <TD>{user.role}</TD>
                <TD>
                  <span className={user.status === '正常' ? 'text-[#64e3be]' : 'text-[#ff90a3]'}>{user.status}</span>
                </TD>
                <TD>{user.createdAt}</TD>
              </tr>
            ))}
          </TBody>
        </Table>
      </div>
    </Card>
  )
}
