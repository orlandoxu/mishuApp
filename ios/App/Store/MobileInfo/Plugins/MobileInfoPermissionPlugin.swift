import AVFoundation
import CoreLocation
import Foundation
import Photos
import UserNotifications

@MainActor
enum MobileInfoPermissionPlugin {
  static func snapshot() -> [String: Any] {
    let notice = NoticePermissionStore.shared
    let location = LocationPermissionStore.shared
    let localNetwork = LocalNetworkPermissionStore.shared
    let localAlbum = LocalAlbumStore.shared

    let cameraAuthorization = AVCaptureDevice.authorizationStatus(for: .video)

    return [
      "notification": [
        "authorizationStatus": notice.authorizationStatus.mobileInfoValue,
        "authorizationStatusRaw": notice.authorizationStatus.rawValue,
        "isAuthorized": notice.isAuthorized,
        "isDenied": notice.isDenied,
        "isNotDetermined": notice.isNotDetermined,
        "deviceTokenExists": notice.deviceToken?.isEmpty == false,
        "deviceTokenLength": notice.deviceToken?.count ?? 0,
      ],
      "location": [
        "authorization": location.authorization.mobileInfoValue,
        "authorizationRaw": location.authorization.rawValue,
        "isDenied": location.isDenied,
      ],
      "localNetwork": [
        "status": localNetwork.status.mobileInfoValue,
        "isDenied": localNetwork.isDenied,
      ],
      "photoLibrary": [
        "authorization": localAlbum.authorization.mobileInfoValue,
        "authorizationRaw": localAlbum.authorization.rawValue,
      ],
      "camera": [
        "authorization": cameraAuthorization.mobileInfoValue,
        "authorizationRaw": cameraAuthorization.rawValue,
      ],
    ]
  }
}

@MainActor
enum MobileInfoLiveUserLocationPlugin {
  static func snapshot() -> [String: Any] {
    [
      "scope": "instance",
      "globalSnapshotSupported": false,
      "reason": "LiveUserLocationStore is not a shared singleton store",
    ]
  }
}

private extension UNAuthorizationStatus {
  var mobileInfoValue: String {
    switch self {
    case .notDetermined:
      return "notDetermined"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .provisional:
      return "provisional"
    case .ephemeral:
      return "ephemeral"
    @unknown default:
      return "unknown"
    }
  }
}

private extension CLAuthorizationStatus {
  var mobileInfoValue: String {
    switch self {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorizedAlways:
      return "authorizedAlways"
    case .authorizedWhenInUse:
      return "authorizedWhenInUse"
    @unknown default:
      return "unknown"
    }
  }
}

private extension LocalNetworkAuthorizationStatus {
  var mobileInfoValue: String {
    switch self {
    case .unknown:
      return "unknown"
    case .granted:
      return "granted"
    case .denied:
      return "denied"
    }
  }
}

private extension PHAuthorizationStatus {
  var mobileInfoValue: String {
    switch self {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    case .limited:
      return "limited"
    @unknown default:
      return "unknown"
    }
  }
}

private extension AVAuthorizationStatus {
  var mobileInfoValue: String {
    switch self {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    @unknown default:
      return "unknown"
    }
  }
}
