import Foundation

extension VehiclesStore {
  var vehicleDetailVehicle: VehicleModel? {
    hashVehicles[vehicleDetailImei ?? ""]
  }

  func setVehicleDetailImei(_ imei: String) {
    vehicleDetailImei = imei
  }

  func loadVehicleDetailAll() async {
    guard let imei = vehicleDetailImei, !imei.isEmpty else {
      errorMessage = "车辆信息缺失"
      return
    }

    async let statusInfo = fetchStatusInfo(imei: imei)
    async let tripList = fetchTripList(imei: imei, page: 1, limit: 10)
    async let tripStats = fetchTripStats(imei: imei)

    let status = await statusInfo
    let trips = await tripList
    let stats = await tripStats

    updateVehicle(imei: imei) { vehicle in
      vehicle.statusInfo = status
      vehicle.tripList = trips ?? []
      vehicle.tripStats = stats
      print("loadVehicleDetailAll: \(vehicle)")
    }

    let listCount = trips?.count ?? 0
    vehicleDetailTripsState.pageByImei[imei] = 1
    vehicleDetailTripsState.hasMoreByImei[imei] = listCount >= 10
  }

  func refreshVehicleDetailTrips(limit: Int = 10) async {
    guard let imei = vehicleDetailImei, !imei.isEmpty else { return }
    if vehicleDetailTripsState.fetchingImeiSet.contains(imei) { return }
    vehicleDetailTripsState.fetchingImeiSet.insert(imei)
    defer { vehicleDetailTripsState.fetchingImeiSet.remove(imei) }

    let payload = TripListPayload(imei: imei, page: 1, limit: limit)
    let list = await TripAPI.shared.list(payload: payload)
    if let list {
      updateVehicle(imei: imei) { vehicle in
        vehicle.tripList = list
      }
      vehicleDetailTripsState.pageByImei[imei] = 1
      vehicleDetailTripsState.hasMoreByImei[imei] = list.count >= limit
    } else {
      errorMessage = "行程列表获取失败"
    }
  }

  func loadMoreVehicleDetailTripsIfNeeded(currentTripId: String, limit: Int = 10) async {
    guard let imei = vehicleDetailImei, !imei.isEmpty else { return }
    guard let currentTrips = vehicleDetailVehicle?.tripList, let last = currentTrips.last else { return }
    guard last.id == currentTripId else { return }
    if vehicleDetailTripsState.fetchingImeiSet.contains(imei) { return }
    if vehicleDetailTripsState.hasMoreByImei[imei] == false { return }

    vehicleDetailTripsState.fetchingImeiSet.insert(imei)
    defer { vehicleDetailTripsState.fetchingImeiSet.remove(imei) }

    let currentPage = vehicleDetailTripsState.pageByImei[imei] ?? 1
    let nextPage = currentPage + 1

    let payload = TripListPayload(imei: imei, page: nextPage, limit: limit)
    let next = await TripAPI.shared.list(payload: payload)
    if let next {
      updateVehicle(imei: imei) { vehicle in
        var existing = vehicle.tripList
        let existingIds = Set(existing.map(\.id))
        for item in next where !existingIds.contains(item.id) {
          existing.append(item)
        }
        vehicle.tripList = existing
      }

      vehicleDetailTripsState.pageByImei[imei] = nextPage
      vehicleDetailTripsState.hasMoreByImei[imei] = next.count >= limit
    } else {
      errorMessage = "行程列表获取失败"
    }
  }

  private func fetchStatusInfo(imei: String) async -> OBDDeviceStatusData? {
    let payload = OBDDeviceStatusPayload(imei: imei)
    let result = await OBDAPI.shared.getDeviceStatusInfo(payload: payload)
    if result == nil {
      errorMessage = "设备状态获取失败"
    }
    return result
  }

  private func fetchTripList(imei: String, page: Int, limit: Int) async -> [TripData]? {
    let payload = TripListPayload(imei: imei, page: page, limit: limit)
    let result = await TripAPI.shared.list(payload: payload)
    if result == nil {
      errorMessage = "行程列表获取失败"
    }
    return result
  }

  private func fetchTripStats(imei: String) async -> TripStatisticalData? {
    let result = await TripAPI.shared.statisticalData(imei)
    if result == nil {
      errorMessage = "行程统计获取失败"
    }
    return result
  }
}
