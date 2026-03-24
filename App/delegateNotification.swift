import UserNotifications

private func extractLinkURLString(from userInfo: [AnyHashable: Any]) -> String? {
  if let dataString = userInfo["data"] as? String,
     let jsonData = dataString.data(using: .utf8),
     let object = try? JSONSerialization.jsonObject(with: jsonData),
     let data = object as? [String: Any],
     let urlString = data["url"] as? String
  {
    let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  return nil
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent _: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .badge, .sound])
  }

  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo

    if let urlString = extractLinkURLString(from: userInfo) {
      Task { @MainActor in
        AppStateStore.shared.cachePendingLink(urlString: urlString)
      }
    }
    completionHandler()
  }
}
