import CoreLocation
import Foundation
import UIKit

final class LocationPermissionStore: NSObject, ObservableObject, CLLocationManagerDelegate {
  static let shared = LocationPermissionStore()

  @Published private(set) var authorization: CLAuthorizationStatus

  private let manager = CLLocationManager()

  override private init() {
    if #available(iOS 14.0, *) {
      authorization = manager.authorizationStatus
    } else {
      authorization = CLLocationManager.authorizationStatus()
    }
    super.init()
    manager.delegate = self
  }

  var isDenied: Bool {
    authorization == .denied || authorization == .restricted
  }

  func refresh() {
    if #available(iOS 14.0, *) {
      authorization = manager.authorizationStatus
    } else {
      authorization = CLLocationManager.authorizationStatus()
    }
  }

  func requestIfNeeded() {
    if authorization == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
  }

  func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if #available(iOS 14.0, *) {
      authorization = manager.authorizationStatus
    } else {
      authorization = CLLocationManager.authorizationStatus()
    }
  }

  func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    authorization = status
  }
}
