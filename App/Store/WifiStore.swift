import CoreLocation
import Foundation
import Network
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit

/// 管理当前手机连接的wifi，以及对应的车辆设备信息
class WifiStore: ObservableObject {
  static let shared = WifiStore()

  private init() {}

  @Published var currentSSID: String?
  @Published private var rawDeviceInfo: VehicleDeviceInfo? // 内部使用的(用来记录wifi读到的设备基础信息)
  // @Published var errorMessage: String?

  var isTargetWifiConnected: Bool {
    let ssid = (currentSSID ?? "").uppercased()
    return targetWifiPrefixes.contains { ssid.hasPrefix($0) }
  }

  /// 真正外部使用的
  var deviceInfo: VehicleDeviceInfo? {
    guard isTargetWifiConnected else { return nil }
    return rawDeviceInfo
  }

  let targetWifiPrefixes = ["CDR", "LLM"]
  var targetWifiPrefix: String {
    targetWifiPrefixes.joined(separator: "/")
  }

  var targetWifiPrefixHintText: String {
    targetWifiPrefixes.joined(separator: "/")
  }

  private var wifiCheckTimer: Timer?
  private var deviceInfoTimer: Timer?
  private var pathMonitor: NWPathMonitor?
  private var lifecycleObservers: [NSObjectProtocol] = []
  private var isDeviceInfoRequesting = false
  private let locationManager = CLLocationManager()
  private var appManagedSSIDs: Set<String> = []

  func startMonitoringWifi() {
    // Step 1. 清理上一次监听状态
    stopMonitoringWifi()

    ensureLocationAuthorization()
    LocalNetworkPermissionStore.shared.requestIfNeeded()

    // Step 2. 启动轮询检测
    wifiCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
      self?.checkCurrentWifi()
    }

    // Step 3. 监听前后台切换
    let center = NotificationCenter.default
    let didBecomeActive = center.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.checkCurrentWifi()
    }
    let willEnterForeground = center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.checkCurrentWifi()
    }
    lifecycleObservers = [didBecomeActive, willEnterForeground]

    // Step 4. 监听网络状态变化
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
      if path.status == .satisfied {
        self?.checkCurrentWifi()
      } else {
        DispatchQueue.main.async {
          self?.updateConnectionState(ssid: nil)
        }
      }
    }
    pathMonitor = monitor
    monitor.start(queue: DispatchQueue(label: "wifi.store.monitor"))

    // Step 5. 立即做一次检测
    checkCurrentWifi()
  }

  func stopMonitoringWifi() {
    // Step 1. 停止轮询检测
    wifiCheckTimer?.invalidate()
    wifiCheckTimer = nil
    // Step 2. 停止设备信息轮询
    stopDeviceInfoPolling()
    // Step 3. 停止网络状态监听
    if let monitor = pathMonitor {
      monitor.cancel()
    }
    pathMonitor = nil
    // Step 4. 移除前后台监听
    let center = NotificationCenter.default
    lifecycleObservers.forEach { center.removeObserver($0) }
    lifecycleObservers.removeAll()
  }

  func checkCurrentWifi() {
    ensureLocationAuthorization()
    LocalNetworkPermissionStore.shared.requestIfNeeded()
    Task {
      let ssid = await fetchCurrentSSID()
      await MainActor.run {
        self.updateConnectionState(ssid: ssid)
      }
    }
  }

  func reset() {
    // Step 1. 清理设备信息与错误状态
    rawDeviceInfo = nil
    // errorMessage = nil
    isDeviceInfoRequesting = false
    appManagedSSIDs.removeAll()
  }

  /// 记录由 App 通过 NEHotspotConfiguration 成功接入的 SSID。
  func markAppManagedConnection(ssid: String) {
    let normalized = normalizeSSID(ssid)
    guard normalized.isEmpty == false else { return }
    appManagedSSIDs.insert(normalized)
  }

  /// 当前连接 Wi-Fi 是否由 App 通过系统热点配置接入。
  var isCurrentWifiAppManaged: Bool {
    let current = normalizeSSID(currentSSID ?? "")
    guard current.isEmpty == false else { return false }
    return appManagedSSIDs.contains(current)
  }

  /// 仅当当前 Wi-Fi 为 App 管理连接时，移除系统热点配置触发断开。
  @discardableResult
  func disconnectCurrentAppManagedWifiIfNeeded() -> Bool {
    let current = normalizeSSID(currentSSID ?? "")
    guard current.isEmpty == false else { return false }
    guard appManagedSSIDs.contains(current) else { return false }

    NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: current)
    appManagedSSIDs.remove(current)
    checkCurrentWifi()
    return true
  }

  private func updateConnectionState(ssid: String?) {
    // Step 1. 记录上一状态并更新 SSID
    let wasConnected = isTargetWifiConnected
    currentSSID = ssid
    // Step 2. 连接状态变化时更新设备信息轮询
    if isTargetWifiConnected {
      if !wasConnected {
        startDeviceInfoPolling()
      }
    } else {
      stopDeviceInfoPolling()
      rawDeviceInfo = nil
      // errorMessage = nil
    }
  }

  private func startDeviceInfoPolling() {
    // Step 1. 先清理再开始轮询
    stopDeviceInfoPolling()
    // Step 2. 立即获取一次设备信息
    fetchDeviceInfo()
    // Step 3. 启动轮询心跳
    deviceInfoTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
      self?.fetchDeviceInfo()
    }
  }

  private func stopDeviceInfoPolling() {
    // Step 1. 停止设备信息轮询并清理状态
    deviceInfoTimer?.invalidate()
    deviceInfoTimer = nil
    isDeviceInfoRequesting = false
  }

  private func fetchCurrentSSID() async -> String? {
    // Step 1. 读取系统 Wi‑Fi 接口信息
    if let ssid = await fetchSSIDFromHotspot() {
      // print("currentSSID: \(ssid)")
      return ssid
    }
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as? [String] {
      for interface in interfaces {
        if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any] {
          ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
          break
        }
      }
    }
    // print("currentSSID: \(ssid ?? "nil")")
    return ssid
  }

  private func fetchSSIDFromHotspot() async -> String? {
    await withCheckedContinuation { continuation in
      NEHotspotNetwork.fetchCurrent { network in
        continuation.resume(returning: network?.ssid)
      }
    }
  }

  private func ensureLocationAuthorization() {
    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = locationManager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    if status == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    }
  }

  private func fetchDeviceInfo() {
    // Step 1. 仅在连接目标 Wi‑Fi 时请求
    guard isTargetWifiConnected else { return }
    if isDeviceInfoRequesting { return }
    isDeviceInfoRequesting = true
    // errorMessage = nil

    Task {
      // Step 2. 调用设备端接口
      let info = await VehicleDeviceAPI.shared.fetchDeviceInfo()
      print("fetchDeviceInfo: \(String(describing: info))")

      await MainActor.run {
        // Step 3. 更新状态并兜底
        self.isDeviceInfoRequesting = false
        guard self.isTargetWifiConnected else {
          self.rawDeviceInfo = nil
          // self.errorMessage = nil
          return
        }
        if let info, info.imei?.isEmpty == false, info.sn?.isEmpty == false {
          self.rawDeviceInfo = info
          // self.errorMessage = nil
        } else {
          self.rawDeviceInfo = nil
          // self.errorMessage = "获取设备信息失败，请确认已连接设备 Wi‑Fi"
        }
      }
    }
  }

  private func normalizeSSID(_ ssid: String) -> String {
    ssid.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
