import { useEffect, useMemo, useState } from 'react'
import { Card } from '@/components/ui/card'
import { adminApi, type DashboardPayload } from '@/lib/api'
import { useAdminStore } from '@/store/admin-store'

type LoadState = 'loading' | 'error' | 'ready'

type DailyPoint = {
  date: string
  value: number
}

function formatPct(value: number | null): string {
  if (value === null) return '--'
  return `${value > 0 ? '+' : ''}${value}%`
}

function formatLabel(date: string): string {
  const [, month, day] = date.split('-')
  return `${month}-${day}`
}

function DailyBarChart({ title, color, data }: { title: string; color: string; data: DailyPoint[] }) {
  const max = Math.max(...data.map((item) => item.value), 1)

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-medium text-[#3b4f71]">{title}</h3>
      <div className="overflow-x-auto rounded-lg border border-[#e8eef8] bg-[#fbfdff]">
        <div className="min-w-[980px] p-3">
          <div className="flex h-[240px] items-end gap-1">
            {data.map((item) => {
              const height = Math.max(6, (item.value / max) * 220)
              return (
                <div key={item.date} className="group flex w-3 flex-col items-center">
                  <div className="mb-1 text-[10px] text-[#6f7f99] opacity-0 transition-opacity group-hover:opacity-100">{item.value}</div>
                  <div
                    className="w-3 rounded-t-sm"
                    style={{ height: `${height}px`, backgroundColor: color }}
                    title={`${item.date}：${item.value}`}
                  />
                </div>
              )
            })}
          </div>
          <div className="mt-2 flex gap-1 text-[10px] text-[#7b8ba7]">
            {data.map((item, idx) => (
              <div key={item.date} className="w-3 text-center">
                {idx % 5 === 0 ? formatLabel(item.date) : ''}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

export function DashboardHome() {
  const token = useAdminStore((s) => s.token)
  const [state, setState] = useState<LoadState>('loading')
  const [data, setData] = useState<DashboardPayload | null>(null)

  useEffect(() => {
    let cancelled = false
    setState('loading')

    adminApi.getDashboard(token)
      .then((res) => {
        if (cancelled) return
        setData(res)
        setState('ready')
      })
      .catch(() => {
        if (cancelled) return
        setState('error')
      })

    return () => {
      cancelled = true
    }
  }, [token])

  const series = data?.charts.growth60d ?? []
  const userNewSeries = useMemo<DailyPoint[]>(() => series.map((item) => ({ date: item.date, value: item.newUsers })), [series])
  const activeSeries = useMemo<DailyPoint[]>(() => series.map((item) => ({ date: item.date, value: item.loginUsers })), [series])

  if (state === 'loading') {
    return <Card className="p-6 text-sm text-[#6f7f99]">正在加载真实运营数据...</Card>
  }

  if (state === 'error' || !data) {
    return <Card className="p-6 text-sm text-[#d14343]">仪表盘数据加载失败，请检查后端或重新登录。</Card>
  }

  return (
    <div className="space-y-5 pb-8">
      <div className="grid gap-4 md:grid-cols-4">
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">累计用户</p><p className="mt-2 text-3xl font-semibold text-[#162846]">{data.metrics.totalUsers}</p></Card>
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">近 7 天新增</p><p className="mt-2 text-3xl font-semibold text-[#162846]">{data.metrics.newUsers7d}</p><p className="mt-1 text-xs text-[#4a678f]">环比上周 {formatPct(data.trends.newUsers7dVsPrev7dPct)}</p></Card>
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">今日活跃</p><p className="mt-2 text-3xl font-semibold text-[#162846]">{data.metrics.activeUsersToday}</p><p className="mt-1 text-xs text-[#4a678f]">7天活跃 {data.metrics.activeUsers7d} / 30天活跃 {data.metrics.activeUsers30d}</p></Card>
        <Card className="p-5"><p className="text-sm text-[#6f7f99]">豆包成功率(30天)</p><p className="mt-2 text-3xl font-semibold text-[#162846]">{data.metrics.doubaoSuccessRate30d}%</p><p className="mt-1 text-xs text-[#4a678f]">Avg {data.metrics.doubaoAvgLatencyMs30d}ms · P95 {data.metrics.doubaoP95LatencyMs30d}ms</p></Card>
      </div>

      <Card className="p-5">
        <h2 className="text-lg font-semibold text-[#162846]">用户每日新增（近 60 天）</h2>
        <div className="mt-4">
          <DailyBarChart title="每日新增用户数" color="#1f6feb" data={userNewSeries} />
        </div>
      </Card>

      <Card className="p-5">
        <h2 className="text-lg font-semibold text-[#162846]">活跃用户每日数量（近 60 天）</h2>
        <div className="mt-4">
          <DailyBarChart title="每日活跃用户数" color="#0d9488" data={activeSeries} />
        </div>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="p-5">
          <h2 className="text-lg font-semibold text-[#162846]">AI 调用概览</h2>
          <div className="mt-3 space-y-2 text-sm text-[#334c72]">
            <p>今日调用：{data.metrics.doubaoCallsToday}（较昨日 {formatPct(data.trends.doubaoTodayVsYesterdayPct)}）</p>
            <p>近 30 天调用：{data.metrics.doubaoCalls30d}</p>
          </div>
        </Card>

        <Card className="p-5">
          <h2 className="text-lg font-semibold text-[#162846]">API 类型分布（近 30 天）</h2>
          <div className="mt-3 space-y-2">
            {data.charts.doubaoApiMix30d.map((item) => (
              <div key={item.apiType} className="text-sm text-[#334c72]">
                <div className="mb-1 flex items-center justify-between"><span>{item.apiType}</span><span>{item.count}</span></div>
                <div className="h-2 rounded bg-[#edf3ff]"><div className="h-2 rounded bg-[#3b82f6]" style={{ width: `${(item.count / Math.max(data.metrics.doubaoCalls30d, 1)) * 100}%` }} /></div>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
