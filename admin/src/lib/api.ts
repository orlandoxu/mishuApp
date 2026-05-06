export type ApiResponse<T> = {
  ret: number
  msg: string
  data: T
}

export type AdminUserRecord = {
  id: string
  phoneNumber: string
  role: 'admin' | 'user'
  status: '正常' | '禁用'
  createdAt: string
  lastLoginAt: string | null
}

export type DoubaoLogRecord = {
  id: string
  apiType: string
  modelId: string
  durationMs: number
  success: boolean
  errorMessage: string
  createdAt: string
}

async function request<T>(url: string, options: RequestInit): Promise<T> {
  const mergedHeaders = {
    'Content-Type': 'application/json',
    ...((options.headers ?? {}) as Record<string, string>),
  }

  const response = await fetch(url, {
    ...options,
    headers: mergedHeaders,
  })

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`)
  }

  const json = (await response.json()) as ApiResponse<T>
  if (json.ret !== 0) {
    throw new Error(json.msg || '请求失败')
  }

  return json.data
}

export const adminApi = {
  login(payload: { username: string; password: string }) {
    return request<{ token: string; username: string }>('/api/admin/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  getUsers(payload: { page?: number; pageSize?: number; keyword?: string }, token: string) {
    return request<{ page: number; pageSize: number; total: number; records: AdminUserRecord[] }>('/api/admin/users', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
  getDoubaoLogs(payload: { page?: number; pageSize?: number; apiType?: string }, token: string) {
    return request<{ page: number; pageSize: number; total: number; records: DoubaoLogRecord[] }>('/api/admin/doubao/logs', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
}
