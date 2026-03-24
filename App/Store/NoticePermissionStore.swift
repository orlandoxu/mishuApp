import Foundation
import UIKit
import UserNotifications

final class NoticePermissionStore: NSObject, ObservableObject {
  static let shared = NoticePermissionStore()

  @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
  @Published private(set) var deviceToken: String?

  private let deviceTokenKey = "mishu_ios_device_token"

  override private init() {
    super.init()
    deviceToken = UserDefaults.standard.string(forKey: deviceTokenKey)
    checkAuthorizationStatus()
  }

  var isAuthorized: Bool {
    authorizationStatus == .authorized
  }

  var isDenied: Bool {
    authorizationStatus == .denied
  }

  var isNotDetermined: Bool {
    authorizationStatus == .notDetermined
  }

  func checkAuthorizationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
      DispatchQueue.main.async {
        self?.authorizationStatus = settings.authorizationStatus
        print("[NoticePermission] authorizationStatus=\(settings.authorizationStatus.rawValue)")
      }
    }
  }

  func requestIfNeeded() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      print("[NoticePermission] currentStatus=\(settings.authorizationStatus.rawValue)")
      switch settings.authorizationStatus {
      case .notDetermined:
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .badge, .sound]
        ) { granted, _ in
          print("[NoticePermission] requestAuthorization granted=\(granted)")
          if granted {
            DispatchQueue.main.async {
              print("[NoticePermission] registerForRemoteNotifications")
              UIApplication.shared.registerForRemoteNotifications()
            }
          }
        }

      case .authorized, .provisional:
        DispatchQueue.main.async {
          print("[NoticePermission] registerForRemoteNotifications (authorized/provisional)")
          UIApplication.shared.registerForRemoteNotifications()
        }

      default:
        print("[NoticePermission] notifications not allowed")
      }
    }
  }

  func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }

  func setDeviceToken(_ token: String) {
    deviceToken = token
    UserDefaults.standard.set(token, forKey: deviceTokenKey)
    print("[NoticePermission] setDeviceToken length=\(token.count)")
  }

  func refresh() {
    checkAuthorizationStatus()
    deviceToken = UserDefaults.standard.string(forKey: deviceTokenKey)
  }

  private func hasApsAlert(userInfo: [AnyHashable: Any]) -> Bool {
    guard let aps = userInfo["aps"] as? [String: Any] else { return false }
    if let alert = aps["alert"] as? String {
      return !alert.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    if let alert = aps["alert"] as? [String: Any] {
      let title = (alert["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let body = (alert["body"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return !title.isEmpty || !body.isEmpty
    }
    return false
  }

  private func notificationTitle(from userInfo: [AnyHashable: Any]) -> String? {
    if let aps = userInfo["aps"] as? [String: Any],
       let alert = aps["alert"] as? [String: Any],
       let title = alert["title"] as? String
    {
      let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    if let title = userInfo["title"] as? String {
      let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    return nil
  }

  private func notificationBody(from userInfo: [AnyHashable: Any]) -> String? {
    if let aps = userInfo["aps"] as? [String: Any] {
      if let alert = aps["alert"] as? String {
        let trimmed = alert.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
      if let alert = aps["alert"] as? [String: Any],
         let body = alert["body"] as? String
      {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
    }
    if let body = userInfo["body"] as? String {
      let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    if let message = userInfo["msg"] as? String {
      let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed
    }
    return nil
  }
}
