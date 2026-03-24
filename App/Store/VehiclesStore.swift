import Foundation
import SwiftUI

final class VehicleDetailTripsState {
  var pageByImei: [String: Int] = [:]
  var hasMoreByImei: [String: Bool] = [:]
  var fetchingImeiSet: Set<String> = []
}

@MainActor
final class VehiclesStore: ObservableObject {
  static let shared = VehiclesStore()
  private let vehicleListCacheSchemaVersion = 1

  @Published var vehicles: [VehicleModel] = [] {
    didSet {
      hashVehicles = Dictionary(
        uniqueKeysWithValues: vehicles.map { ($0.imei, $0) }
      )
    }
  }

  /// 车辆列表的哈希表，用于快速查找
  @Published private(set) var hashVehicles: [String: VehicleModel] = [:]

  /// 爱车界面 / 预览界面，关注哪一个车
  @Published var vehicleDetailImei: String? = nil

  // DONE-AI：车辆详情数据挂载到 VehicleModel

  // 加载状态相关的
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil

  // MARK: - Socket实时数据（不需要持久化）

  /// 设备在线状态 [imei: status] 0:离线, 1:在线, 2:休眠
  @Published var deviceOnlineStatus: [String: Int] = [:]

  /// GPS数据缓存 [imei: GPSUpdatePayload]
  @Published var latestGPSData: [String: GPSUpdatePayload] = [:]

  /// VehiclesStore+Live相关
  @Published var liveImei: String? = nil // 当前直播的车辆IMEI

  @Published var cloudImei: String? = nil // 当前用户正在关注的云服务模块的IMEI

  let vehicleDetailTripsState = VehicleDetailTripsState()

  func refresh() async {
    if isLoading { return }

    // 首次空列表时先尝试本地缓存，缓存解析失败则直接忽略
    loadCachedVehiclesIfNeeded()

    isLoading = true
    errorMessage = nil

    if let result = await UserAPI.shared.getAllVehicleWithRaw() {
      vehicles = mergeVehiclesPreservingTransientFields(incoming: result.vehicles)
      saveVehicleCache(rawData: result.rawData)
    } else {
      errorMessage = "车辆列表获取失败"
    }

    isLoading = false
  }

  func setFavorite(imei: String) async {
    let result = await UserAPI.shared.setFavoriteVehicle(
      payload: UserSetFavoriteVehiclePayload(imei: imei)
    )
    if result != nil {
      await refresh()
    } else {
      errorMessage = "设置默认车辆失败"
    }
  }

  func updateVehicle(
    imei: String,
    mutate: (inout VehicleModel) -> Void
  ) {
    guard let idx = vehicles.firstIndex(where: { $0.imei == imei }) else { return }
    var vehicle = vehicles[idx]
    mutate(&vehicle)
    vehicles[idx] = vehicle
  }

  func removeVehicle(imei: String) {
    vehicles.removeAll { $0.imei == imei }
    // 本地设备列表发生明显变更时，避免下次启动读取到陈旧缓存
    clearVehicleCache()
  }
}

private extension VehiclesStore {
  var vehicleCacheKey: String {
    let userSegment = SelfStore.shared.selfUser?.userId ?? "default"
    return "tuyun_vehicle_list_cache_v\(vehicleListCacheSchemaVersion)_\(userSegment)"
  }

  func mergeVehiclesPreservingTransientFields(incoming: [VehicleModel]) -> [VehicleModel] {
    let existingByImei = Dictionary(uniqueKeysWithValues: vehicles.map { ($0.imei, $0) })
    var merged: [VehicleModel] = []
    merged.reserveCapacity(incoming.count)

    for var item in incoming {
      if let existing = existingByImei[item.imei] {
        item.travelReport = existing.travelReport
        item.statusInfo = existing.statusInfo
        item.tripList = existing.tripList
        item.tripStats = existing.tripStats
        item.cloudBenefitResources = existing.cloudBenefitResources
      }
      merged.append(item)
    }

    return merged
  }

  func loadCachedVehiclesIfNeeded() {
    guard vehicles.isEmpty else { return }
    guard let rawData = UserDefaults.standard.data(forKey: vehicleCacheKey) else { return }
    guard let cached = UserAPI.shared.decodeAllVehicleRawData(rawData) else {
      // 版本升级导致结构变化时，缓存解码失败直接丢弃，避免异常
      clearVehicleCache()
      return
    }
    vehicles = mergeVehiclesPreservingTransientFields(incoming: cached)
  }

  func saveVehicleCache(rawData: Data) {
    UserDefaults.standard.set(rawData, forKey: vehicleCacheKey)
  }

  func clearVehicleCache() {
    UserDefaults.standard.removeObject(forKey: vehicleCacheKey)
  }
}
