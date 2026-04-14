import CoreLocation
import Foundation

// 这个工作有3个：
// 1. 请求定位权限
// 2. 获取定位信息
// 3. 根据定位信息获取省份和城市

struct LocationInfo: Equatable {
  let location: CLLocation
  let province: String
  let city: String
}

enum LocationServiceError: Error, Equatable {
  case servicesDisabled
  case authorizationDenied
  case authorizationRestricted
  case authorizationNotDetermined
  case requestInProgress
  case locationUnavailable
  case geocodeFailed
}

@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
  static let shared = LocationService()

  private let manager: CLLocationManager
  private let geocoder: CLGeocoder
  private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Error>?
  private var locationContinuation: CheckedContinuation<CLLocation, Error>?

  override private init() {
    manager = CLLocationManager()
    geocoder = CLGeocoder()
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 100
  }

  func fetchLocationInfo() async throws -> LocationInfo {
    guard CLLocationManager.locationServicesEnabled() else {
      throw LocationServiceError.servicesDisabled
    }
    let status = try await requestAuthorizationIfNeeded()
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      throw LocationServiceError.authorizationDenied
    }
    let location = try await requestLocation()
    let placemark = try await reverseGeocode(location)
    let province = placemark.administrativeArea ?? ""
    let city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
    return LocationInfo(location: location, province: province, city: city)
  }

  private func requestAuthorizationIfNeeded() async throws -> CLAuthorizationStatus {
    let status = manager.authorizationStatus
    switch status {
    case .notDetermined:
      if authorizationContinuation != nil {
        throw LocationServiceError.requestInProgress
      }
      return try await withCheckedThrowingContinuation { continuation in
        authorizationContinuation = continuation
        manager.requestWhenInUseAuthorization()
      }
    case .restricted:
      throw LocationServiceError.authorizationRestricted
    case .denied:
      throw LocationServiceError.authorizationDenied
    case .authorizedAlways, .authorizedWhenInUse:
      return status
    @unknown default:
      throw LocationServiceError.authorizationDenied
    }
  }

  private func requestLocation() async throws -> CLLocation {
    if locationContinuation != nil {
      throw LocationServiceError.requestInProgress
    }
    return try await withCheckedThrowingContinuation { continuation in
      locationContinuation = continuation
      manager.requestLocation()
    }
  }

  private func reverseGeocode(_ location: CLLocation) async throws -> CLPlacemark {
    try await withCheckedThrowingContinuation { continuation in
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        guard let placemark = placemarks?.first else {
          continuation.resume(throwing: LocationServiceError.geocodeFailed)
          return
        }
        continuation.resume(returning: placemark)
      }
    }
  }

  func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    if let continuation = authorizationContinuation {
      authorizationContinuation = nil
      continuation.resume(returning: status)
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if let continuation = authorizationContinuation {
      authorizationContinuation = nil
      continuation.resume(returning: manager.authorizationStatus)
    }
  }

  func locationManager(
    _: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    if let continuation = locationContinuation {
      locationContinuation = nil
      guard let location = locations.last else {
        continuation.resume(throwing: LocationServiceError.locationUnavailable)
        return
      }
      continuation.resume(returning: location)
    }
  }

  func locationManager(
    _: CLLocationManager,
    didFailWithError error: Error
  ) {
    if let continuation = locationContinuation {
      locationContinuation = nil
      continuation.resume(throwing: error)
    }
  }
}
