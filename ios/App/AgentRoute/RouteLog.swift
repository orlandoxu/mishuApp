import Foundation

// DONE-AI: 路由埋点输出 trace/action/latency，便于线上排障。

/// 路由追踪日志输出协议。
protocol RouteLogSink {
  /// 记录一条已完成的路由追踪。
  func record(trace: RouteTrace)
}

/// 默认日志落地实现：将追踪信息写入应用日志。
final class DefaultRouteLogSink: RouteLogSink {
  /// 格式化关键链路指标并输出。
  func record(trace: RouteTrace) {
    let stageText = trace.stages.map { "\($0.name):\($0.ms)ms" }.joined(separator: " | ")
    LKLog(
      "agent_route trace=\(trace.traceId) user=\(trace.userId) action=\(trace.finalAction.rawValue) total=\(trace.totalMs)ms stages=[\(stageText)]",
      type: "memory",
      label: "info"
    )
  }
}
