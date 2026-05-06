export type ApiResponse<T> = {
  ret: number
  msg: string
  data: T
}

export type AdminUserRecord = {
  id: string
  phoneNumber: string
  displayName: string
  role: 'admin' | 'user'
  status: '正常' | '禁用'
  vipStatus: '普通' | 'VIP' | 'SVIP'
  ltvCny: number
  createdAt: string
  lastLoginAt: string | null
}

export type AdminUsersSummary = {
  totalUsers: number
  totalLtvCny: number
  paidUsers: number
  vipUsers: number
  svipUsers: number
  disabledUsers: number
}

export type AdminOrderRecord = {
  orderId: string
  thirdPartyOrderId: string
  mongoOrderId: string
  userId: string
  userName: string
  phoneNumber: string
  vipStatus: '普通' | 'VIP' | 'SVIP'
  planId: 'monthly' | 'yearly'
  planName: string
  amountCny: number
  payMethod: 'alipay' | 'wechat' | 'apple'
  orderStatus: 'paid' | 'refunded' | 'pending'
  paidAt: string
  expireAt: string
}

export type AdminOrdersQuery = {
  page?: number
  pageSize?: number
  userId?: string
  phoneNumber?: string
  orderId?: string
  payMethod?: 'alipay' | 'wechat' | 'apple'
  planId?: 'monthly' | 'yearly'
  orderStatus?: 'paid' | 'refunded' | 'pending'
  startAt?: string
  endAt?: string
}

export type AdminOrdersSummary = {
  totalAmountCny: number
  paidCount: number
  pendingCount: number
  yearlyCount: number
}

export type DoubaoLogRecord = {
  id: string
  apiType: string
  modelId: string
  userId: string
  userPhone: string
  userDisplayName: string
  vipStatus: '普通' | 'VIP' | 'SVIP'
  durationMs: number
  inputTokens: number
  outputTokens: number
  totalTokens: number
  tokenSource: 'provider' | 'estimated'
  success: boolean
  requestPreview: string
  responsePreview: string
  requestPayload: Record<string, unknown>
  responsePayload: Record<string, unknown>
  responseText: string
  errorMessage: string
  createdAt: string
}

export type DashboardPayload = {
  snapshotAt: string
  metrics: {
    totalUsers: number
    newUsersToday: number
    newUsers7d: number
    activeUsersToday: number
    activeUsers7d: number
    activeUsers30d: number
    doubaoCallsToday: number
    doubaoCalls30d: number
    doubaoSuccessRate30d: number
    doubaoAvgLatencyMs30d: number
    doubaoP95LatencyMs30d: number
  }
  trends: {
    newUsersTodayVsYesterdayPct: number | null
    newUsers7dVsPrev7dPct: number | null
    doubaoTodayVsYesterdayPct: number | null
  }
  charts: {
    growth60d: Array<{
      date: string
      newUsers: number
      loginUsers: number
      doubaoCalls: number
      doubaoSuccessRate: number
    }>
    doubaoApiMix30d: Array<{
      apiType: string
      count: number
    }>
  }
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
  getUsersSummary(payload: { keyword?: string }, token: string) {
    return request<AdminUsersSummary>('/api/admin/users/summary', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
  toggleUserStatus(payload: { userId: string }, token: string) {
    return request<{ userId: string; isActive: boolean }>('/api/admin/users/status', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
  getOrders(payload: AdminOrdersQuery, token: string) {
    return request<{ page: number; pageSize: number; total: number; summary: AdminOrdersSummary; records: AdminOrderRecord[] }>('/api/admin/orders', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
  getDoubaoLogs(payload: { page?: number; pageSize?: number; apiType?: string; userKeyword?: string }, token: string) {
    return request<{ page: number; pageSize: number; total: number; records: DoubaoLogRecord[] }>('/api/admin/doubao/logs', {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: JSON.stringify(payload),
    })
  },
  getDashboard(token: string) {
    return request<DashboardPayload>('/api/admin/dashboard', {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}` },
    })
  },
}
