import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { Table, TBody, TD, TH, THead } from '@/components/ui/table'
import { useAdminStore } from '@/store/admin-store'

export function DoubaoLogsPage() {
  const logs = useAdminStore((s) => s.doubaoLogs)

  return (
    <Card className="p-5">
      <div className="mb-4 flex items-end justify-between">
        <div>
          <h2 className="text-lg font-semibold text-white">豆包调用日志</h2>
          <p className="text-sm text-[#95a9c8]">展示全部接口调用记录、耗时和状态</p>
        </div>
        <Badge>{logs.length} 条记录</Badge>
      </div>

      <div className="overflow-auto">
        <Table>
          <THead>
            <tr>
              <TH>日志ID</TH>
              <TH>接口</TH>
              <TH>模型</TH>
              <TH>耗时</TH>
              <TH>Token</TH>
              <TH>状态</TH>
              <TH>时间</TH>
            </tr>
          </THead>
          <TBody>
            {logs.map((item) => (
              <tr key={item.id} className="hover:bg-white/5">
                <TD>{item.id}</TD>
                <TD>{item.endpoint}</TD>
                <TD>{item.model}</TD>
                <TD>{item.latencyMs}ms</TD>
                <TD>{item.tokenUsage}</TD>
                <TD>
                  <span className={item.status === '成功' ? 'text-[#64e3be]' : 'text-[#ff90a3]'}>{item.status}</span>
                </TD>
                <TD>{item.createdAt}</TD>
              </tr>
            ))}
          </TBody>
        </Table>
      </div>
    </Card>
  )
}
