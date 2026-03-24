import CoreLocation
import Foundation

final class LiveUserLocationStore: NSObject, ObservableObject, CLLocationManagerDelegate {
  @Published private(set) var coordinate: CLLocationCoordinate2D?
  @Published private(set) var heading: Double?

  private let manager = CLLocationManager()
  private var isRunning = false

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = 5
    manager.headingFilter = 1
  }

  @MainActor
  func start() {
    if isRunning { return }
    isRunning = true

    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    if status == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }

    manager.startUpdatingLocation()
    if CLLocationManager.headingAvailable() {
      manager.startUpdatingHeading()
    }
  }

  @MainActor
  func stop() {
    if !isRunning { return }
    isRunning = false
    manager.stopUpdatingLocation()
    manager.stopUpdatingHeading()
  }

  func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let last = locations.last else { return }
    let raw = last.coordinate
    if raw.latitude == 0 || raw.longitude == 0 { return }
    let converted = GpsUtil.gps84ToGcj02(raw)
    Task { @MainActor in
      self.coordinate = converted
    }
  }

  func locationManager(_: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    if newHeading.headingAccuracy < 0 { return }
    let value = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
    Task { @MainActor in
      self.heading = value
    }
  }

  func locationManagerShouldDisplayHeadingCalibration(_: CLLocationManager) -> Bool {
    true
  }
}

