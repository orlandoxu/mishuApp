import Combine
import NetworkExtension
import UIKit

// MARK: - WifiDirectViewModel

/// WiFi 直连页面 ViewModel
/// 负责管理 WiFi 直连的完整流程：点火 → 打开设备 WiFi → 连接 WiFi
@MainActor
final class WifiDirectViewModel: ObservableObject {
  // MARK: - Log

  private enum Log {
    static func info(_ message: String) {
      #if DEBUG
        print("[WifiDirect] \(message)")
      #endif
    }

    static func error(_ message: String) {
      #if DEBUG
        print("[WifiDirect][Error] \(message)")
      #endif
    }
  }

  // MARK: - FailureReason

  /// 失败原因枚举
  /// 用于在失败页面展示不同的文案和按钮行为
  enum FailureReason: Equatable {
    case openFailed // 打开设备 WiFi 失败
    case connectFailed // 连接 WiFi 失败

    /// 失败页面主标题
    var title: String {
      switch self {
      case .openFailed: return "打开失败"
      case .connectFailed: return "连接失败"
      }
    }

    /// 失败页面辅助提示语
    var tip: String {
      switch self {
      case .openFailed: return "请打开设备 WiFi 并连接"
      case .connectFailed: return "请手动连接以下 WiFi"
      }
    }

    /// 是否展示 WiFi 账号密码卡片
    /// 只有连接失败时需要展示
    var showsWifiCredential: Bool {
      self == .connectFailed
    }
  }

  /// 页面阶段枚举
  /// 驱动整个 WiFi 直连流程的状态切换
  enum Stage: Equatable {
    case ignitionReady // 初始态：提示用户先点火
    case openingDeviceWifi // 正在打开设备 WiFi
    case connectingDeviceWifi // 正在连接设备 WiFi
    case failed(FailureReason) // 失败态
    case connectSuccess // 连接成功

    /// 转换为页面索引
    /// 用于 PageViewController 切换页面
    var index: Int {
      switch self {
      case .ignitionReady: return 0
      case .openingDeviceWifi: return 1
      case .connectingDeviceWifi: return 2
      case .failed: return 3
      case .connectSuccess: return 4
      }
    }
  }

  // MARK: - Published Properties

  /// 当前页面阶段
  @Published private(set) var stage: Stage = .ignitionReady

  /// 设备 IMEI（供失败页面使用）
  @Published var imei: String = ""

  // MARK: - Private Properties

  /// 当前直连任务
  private var connectTask: Task<Void, Never>?

  /// WiFi 状态管理
  private let wifiStore: WifiStore

  /// 车辆状态管理
  private let vehiclesStore = VehiclesStore.shared

  /// Combine 订阅管理
  private var cancellables: Set<AnyCancellable> = []

  // MARK: - Initialization

  /// 初始化
  /// - Parameters:
  ///   - imei: 设备 IMEI
  ///   - wifiStore: WiFi 状态管理（默认单例）
  init(imei: String, wifiStore: WifiStore = .shared) {
    self.imei = imei
    self.wifiStore = wifiStore
    bindStore()
  }

  // MARK: - Public Methods

  /// 页面出现时调用
  /// Step 1. 申请本地网络权限
  /// Step 2. 刷新当前 WiFi 状态
  func onAppear() {
    LocalNetworkPermissionStore.shared.requestIfNeeded()
    wifiStore.checkCurrentWifi()
  }

  /// 页面消失时调用
  /// Step 1. 取消进行中的直连任务
  /// Step 2. 清空任务引用
  func onDisappear() {
    connectTask?.cancel()
    connectTask = nil
  }

  /// 触发开始直连
  /// 仅在初始态或失败态允许重试，避免并发重复执行
  func startDirectConnect() {
    // Step 1. 检查是否允许启动
    switch stage {
    case .ignitionReady, .failed:
      break
    default:
      return
    }

    // Step 2. 取消旧任务并启动新任务
    connectTask?.cancel()
    connectTask = Task { [weak self] in
      await self?.runDirectConnectFlow()
    }
  }

  /// 用户点击取消
  /// Step 1. 终止任务
  /// Step 2. 返回上一页
  func cancelAndBack() {
    connectTask?.cancel()
    connectTask = nil
    AppNavigationModel.shared.pop()
  }

  /// 跳转系统设置
  func openWifiSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  /// 核心直连流程
  private func runDirectConnectFlow() async {
    Log.info("========== 开始直连流程 ==========")

    // Step 1. 切换到正在打开设备 WiFi 状态
    Log.info("Step 1: 切换到 openingDeviceWifi")
    stage = .openingDeviceWifi

    // Step 2. 并发执行
    Log.info("Step 2: 调用 setRemoteWifiSwitch 接口")
    async let minimumOpeningDisplay: Void = Task.sleep(nanoseconds: 2_000_000_000)
    async let openWifiTask: Bool = SettingAPI.shared.setRemoteWifiSwitch(imei: imei, enabled: true)
    let opened = await openWifiTask
    Log.info("setRemoteWifiSwitch 结果: \(opened)")
    _ = try? await minimumOpeningDisplay

    guard Task.isCancelled == false else {
      Log.info("任务被取消")
      return
    }

    // Step 3. 判断打开结果
    Log.info("Step 3: 判断打开结果")
    guard opened else {
      Log.error("打开设备 WiFi 失败")
      stage = .failed(.openFailed)
      return
    }

    // Step 4. 切换到正在连接设备 WiFi 状态
    Log.info("Step 4: 切换到 connectingDeviceWifi")
    stage = .connectingDeviceWifi

    // Step 5. 等待 3 秒
    Log.info("Step 5: 等待 3 秒...")
    try? await Task.sleep(nanoseconds: 3_000_000_000)

    // Step 6. 检查 WiFi 名称是否有效
    Log.info("Step 6: 检查 WiFi 名称")
    guard let vehicle = vehiclesStore.hashVehicles[imei],
          let ssid = vehicle.wifi?.SSID,
          !ssid.isEmpty
    else {
      Log.error("WiFi 名称无效")
      stage = .failed(.connectFailed)
      return
    }

    Log.info("目标 WiFi: \(ssid), 密码: \(vehicle.wifi?.wifiPwd ?? "无")")

    // Step 7. 尝试连接目标 WiFi
    Log.info("Step 7: 开始连接目标 WiFi")
    let password = vehicle.wifi?.wifiPwd
    let connected = await connectToTargetWifi(ssid: ssid, password: password)
    guard Task.isCancelled == false else {
      Log.info("任务被取消")
      return
    }

    // Step 8. 根据连接结果切换状态
    Log.info("Step 8: 连接结果 = \(connected)")
    guard connected else {
      stage = .failed(.connectFailed)
      return
    }

    // Step 9. 引导流程结束：该页面仅负责引导用户连接设备 Wi-Fi；
    stage = .connectSuccess
    Log.info("========== 直连引导结束 ==========")
  }

  /// 绑定车辆数据监听
  /// 监听车辆列表变化，设备 WiFi 信息更新后实时刷新本页数据
  private func bindStore() {
    vehiclesStore.$vehicles
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        // 车辆信息变化时，刷新页面显示
      }
      .store(in: &cancellables)
  }

  /// 自动连接目标 WiFi
  private func connectToTargetWifi(ssid: String, password: String?) async -> Bool {
    // Step 1. 应用热点配置
    Log.info("开始连接 WiFi: \(ssid), 密码: \(password ?? "无")")
    let applied = await applyHotspotConfiguration(ssid: ssid, password: password)
    Log.info("热点配置结果: \(applied)")

    guard applied else {
      Log.error("应用热点配置失败")
      return false
    }

    // Step 2. 轮询检查
    Log.info("开始轮询检查当前 WiFi 状态")
    for i in 0 ..< 15 {
      guard Task.isCancelled == false else {
        Log.info("任务被取消")
        return false
      }

      wifiStore.checkCurrentWifi()
      let currentSSID = wifiStore.currentSSID
      Log.info("第 \(i + 1) 次检查，当前 WiFi: \(currentSSID ?? "nil"), 目标: \(ssid)")

      if currentSSID == ssid {
        Log.info("WiFi 连接成功")
        return true
      }

      try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    Log.error("WiFi 连接超时（15秒）")
    return false
  }

  /// 应用热点配置
  /// 调用系统热点配置接口写入目标 SSID/密码
  /// - Parameter ssid: WiFi 名称
  /// - Parameter password: WiFi 密码（可选）
  /// - Returns: 是否应用成功
  /// - Note: alreadyAssociated 视为成功，其他错误按失败处理
  private func applyHotspotConfiguration(ssid: String, password: String?) async -> Bool {
    await withCheckedContinuation { continuation in
      Log.info("创建 NEHotspotConfiguration, ssid: \(ssid), password: \(password ?? "无"), password.count: \(password?.count ?? 0)")

      // Step 1. 创建配置
      let config: NEHotspotConfiguration
      if let password = password, password.count >= 8 {
        config = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
      } else {
        config = NEHotspotConfiguration(ssid: ssid)
      }
      config.joinOnce = true

      // Step 2. 应用配置
      Log.info("调用 NEHotspotConfigurationManager.shared.apply")
      NEHotspotConfigurationManager.shared.apply(config) { error in
        if let error = error {
          Log.error("热点配置失败: \(error.localizedDescription), code: \((error as NSError).code)")
        } else {
          Log.info("热点配置成功（无错误）")
        }

        if let nsError = error as NSError?,
           nsError.domain == NEHotspotConfigurationErrorDomain,
           nsError.code == NEHotspotConfigurationError.alreadyAssociated.rawValue
        {
          Log.info("当前已连接到该 WiFi (alreadyAssociated)")
          // 进入该分支时用户来自“WiFi直连”流程，仍按 App 管理连接记录，
          // 确保后续直播页退出时能弹出“断开Wi-Fi”确认。
          Task { @MainActor [weak self] in
            self?.wifiStore.markAppManagedConnection(ssid: ssid)
          }
          continuation.resume(returning: true)
          return
        }

        if error == nil {
          Task { @MainActor [weak self] in
            self?.wifiStore.markAppManagedConnection(ssid: ssid)
          }
        }
        Log.info("热点配置结果: \(error == nil)")
        continuation.resume(returning: error == nil)
      }
    }
  }
}
