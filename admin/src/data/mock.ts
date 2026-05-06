export type UserRecord = {
  id: string
  name: string
  phone: string
  role: '管理员' | '运营' | '客服'
  status: '正常' | '禁用'
  createdAt: string
}

export type DoubaoLog = {
  id: string
  endpoint: string
  model: string
  latencyMs: number
  status: '成功' | '失败'
  tokenUsage: number
  createdAt: string
}

export const mockUsers: UserRecord[] = [
  { id: 'U1001', name: '陈逸凡', phone: '138****9801', role: '管理员', status: '正常', createdAt: '2026-05-01 09:12' },
  { id: 'U1002', name: '李晴', phone: '139****1023', role: '运营', status: '正常', createdAt: '2026-05-01 11:02' },
  { id: 'U1003', name: '王绍轩', phone: '137****3345', role: '客服', status: '禁用', createdAt: '2026-05-02 16:24' },
  { id: 'U1004', name: '赵雅', phone: '136****0908', role: '运营', status: '正常', createdAt: '2026-05-03 08:48' },
  { id: 'U1005', name: '刘思远', phone: '135****6770', role: '客服', status: '正常', createdAt: '2026-05-04 14:17' },
]

export const mockDoubaoLogs: DoubaoLog[] = [
  { id: 'D-90001', endpoint: '/doubao/chat', model: 'doubao-1.5-pro-32k', latencyMs: 632, status: '成功', tokenUsage: 921, createdAt: '2026-05-06 10:30:22' },
  { id: 'D-90002', endpoint: '/doubao/embedding', model: 'doubao-embedding-large', latencyMs: 284, status: '成功', tokenUsage: 434, createdAt: '2026-05-06 10:31:04' },
  { id: 'D-90003', endpoint: '/doubao/chat', model: 'doubao-1.5-pro-32k', latencyMs: 1208, status: '失败', tokenUsage: 0, createdAt: '2026-05-06 10:33:42' },
  { id: 'D-90004', endpoint: '/doubao/voice', model: 'doubao-voice-realtime', latencyMs: 515, status: '成功', tokenUsage: 198, createdAt: '2026-05-06 10:34:27' },
  { id: 'D-90005', endpoint: '/doubao/chat', model: 'doubao-1.5-pro-32k', latencyMs: 726, status: '成功', tokenUsage: 1002, createdAt: '2026-05-06 10:36:19' },
]
