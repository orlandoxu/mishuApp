import Foundation

@MainActor
final class MeViewModel: ObservableObject {
  @Published var isLoading: Bool = false // 其实这个没有使用，可以先保留这个字段
  @Published var errorMessage: String?
  @Published var tripStats: TripStatisticalData?

  func load() async {
    // Step 1. 防止重复加载
    if isLoading { return }
    isLoading = true
    errorMessage = nil

    // Step 2. 拉取用户信息
    await SelfStore.shared.refresh()

    // Step 4. 结束加载
    isLoading = false
  }

  func logout() async {
    // Step 1. 请求后台退出
    _ = await UserAPI.shared.logout()
  }

  func formatBytes(_ value: Double?) -> String {
    // Step 1. 空值兜底
    guard let value else { return "-" }
    // Step 2. 使用系统格式化（后端返回以字节计）
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .binary
    return formatter.string(fromByteCount: Int64(max(0, value)))
  }

  func formatMinutes(_ value: Double?) -> String {
    // Step 1. 空值兜底
    guard let value else { return "-" }
    // Step 2. 分钟显示
    let minutes = Int(max(0, value))
    return "\(minutes) 分钟"
  }

  func formatMiles(_ value: Double?) -> String {
    // Step 1. 空值兜底
    guard let value else { return "-" }
    // Step 2. 里程显示
    return String(format: "%.1f km", value)
  }
}
