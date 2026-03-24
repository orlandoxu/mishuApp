import SwiftUI

@MainActor
private final class DeviceGPSPlaybackController {
  private var tasks: [String: Task<Void, Never>] = [:]
  private var generations: [String: Int] = [:]

  func start(
    imei: String,
    points: [GPSModel],
    onTick: @escaping @MainActor (GPSModel) -> Void
  ) {
    cancel(imei: imei)
    guard points.isEmpty == false else { return }

    let generation = (generations[imei] ?? 0) + 1
    generations[imei] = generation
    let sortedPoints = points.sorted { $0.time < $1.time }

    tasks[imei] = Task { @MainActor [weak self] in
      for (index, point) in sortedPoints.enumerated() {
        guard let self else { return }
        if Task.isCancelled { return }
        guard self.generations[imei] == generation else { return }

        onTick(point)

        if index < sortedPoints.count - 1 {
          try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
      }

      guard let self else { return }
      guard self.generations[imei] == generation else { return }
      self.tasks[imei] = nil
    }
  }

  func cancel(imei: String) {
    generations[imei] = (generations[imei] ?? 0) + 1
    tasks[imei]?.cancel()
    tasks[imei] = nil
  }
}

@MainActor
private let gpsPlaybackController = DeviceGPSPlaybackController()

// DONE-AI: Socket 相关逻辑独立为 VehiclesStore+Socket
extension VehiclesStore {
  func handlePushEvent(_ event: SocketPushEvent) {
    switch event {
    case let .deviceOnline(imei, status, _):
      deviceOnlineStatus[imei] = status
      withAnimation {
        updateVehicleOnlineStatus(imei: imei, status: status)
      }

    case let .tcardStatus(imei, enabled, _):
      withAnimation {
        updateVehicleTCard(imei: imei, enabled: enabled)
      }

    case let .gpsBatchUpdate(imei, points):
      startGPSPlayback(imei: imei, points: points)

    case let .deviceUnbind(imei, _):
      deviceOnlineStatus.removeValue(forKey: imei)
      latestGPSData.removeValue(forKey: imei)
      cancelGPSPlayback(imei: imei)
      withAnimation {
        removeVehicle(imei: imei)
      }
      if vehicleDetailImei == imei {
        vehicleDetailImei = nil
      }

    case let .serverShutdown(message):
      print("[VehiclesStore] server shutdown: \(message)")

    case let .error(code, message):
      print("[VehiclesStore] socket error: code=\(code), message=\(message)")

    case .appLogUploadRequested:
      break
    }
  }

  func deviceStatus(for imei: String) -> Int? {
    deviceOnlineStatus[imei]
  }

  func latestGPS(for imei: String) -> GPSUpdatePayload? {
    latestGPSData[imei]
  }

  private func updateVehicleOnlineStatus(imei: String, status: Int) {
    guard let idx = vehicles.firstIndex(where: { $0.imei == imei }) else { return }
    vehicles[idx].onlineStatus = status
  }

  private func updateVehicleTCard(imei: String, enabled: Bool) {
    guard let idx = vehicles.firstIndex(where: { $0.imei == imei }) else { return }
    if vehicles[idx].realtime == nil {
      vehicles[idx].realtime = VehicleRealtimeModel()
    }
    vehicles[idx].realtime?.tcard = enabled
  }

  private func updateVehicleGPS(imei: String, gps: GPSModel) {
    guard let idx = vehicles.firstIndex(where: { $0.imei == imei }) else { return }
    vehicles[idx].gps = gps
  }

  private func startGPSPlayback(imei: String, points: [GPSModel]) {
    gpsPlaybackController.start(imei: imei, points: points) { [weak self] point in
      self?.applyGPSPoint(imei: imei, point: point)
    }
  }

  private func cancelGPSPlayback(imei: String) {
    gpsPlaybackController.cancel(imei: imei)
  }

  private func applyGPSPoint(imei: String, point: GPSModel) {
    let latitude = point.latitude
    let longitude = point.longitude
    let speed = Double(point.speed)
    let direction = Double(point.direct)
    let timestamp = point.time

    let gpsData = GPSUpdatePayload(
      imei: imei,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      direction: direction,
      timestamp: timestamp
    )
    latestGPSData[imei] = gpsData
    withAnimation {
      updateVehicleGPS(imei: imei, gps: point)
    }
  }
}
