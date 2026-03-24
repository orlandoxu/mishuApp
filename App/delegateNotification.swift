import UserNotifications

/// 收到任意推送后触发一次服务消息同步（小蜥蜴服务消息）
/// 说明：同步逻辑内部有 isSyncing 防抖，重复触发不会并发请求
func syncServiceMessagesIfNeeded(reason: String, userInfo: [AnyHashable: Any]? = nil) async -> Bool {
  let isLoggedIn = await MainActor.run { SelfStore.shared.isLoggedIn }
  guard isLoggedIn else {
    print("[PushSync] skip message sync (not logged in), reason=\(reason)")
    return false
  }

  if let userInfo {
    print("[PushSync] trigger message sync, reason=\(reason), userInfo=\(userInfo)")
  } else {
    print("[PushSync] trigger message sync, reason=\(reason)")
  }

  await MessageStore.shared.syncLatest()
  return true
}

func printNotification(_ notification: UNNotification) {
  let content: UNNotificationContent = notification.request.content

  print("===== 推送原始对象 =====")
  print(notification)

  print("===== 标题 / 内容 =====")
  print("title:", content.title)
  print("body:", content.body)
  print("subtitle:", content.subtitle)

  print("===== userInfo 原始数据 =====")
  print(content.userInfo)

  print("===== userInfo JSON格式 =====")
  if let data = try? JSONSerialization.data(withJSONObject: content.userInfo, options: .prettyPrinted),
     let json = String(data: data, encoding: .utf8)
  {
    print(json)
  }
}

private func extractLinkURLString(from userInfo: [AnyHashable: Any]) -> String? {
  // 协议固定：只解析 data 内的 url
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

/// 实现通知协议
extension AppDelegate: UNUserNotificationCenterDelegate {
  /// 收到通知时调用（app在前台的时候）
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    printNotification(notification)
    let content: UNNotificationContent = notification.request.content

    // 收到任意通知都同步一次服务消息（即使当前通知不展示）
    Task {
      _ = await syncServiceMessagesIfNeeded(reason: "willPresent", userInfo: content.userInfo)
    }

    // 如果是alert通知，直接放行
    // TODO: 未来还需要判断消息类型！先等服务端同事开发
    if let aps = content.userInfo["aps"] as? [String: Any],
       aps["alert"] != nil
    {
      Task { @MainActor in
        let currentRoute = AppNavigationModel.shared.last()
        let isInVehicleLivePage: Bool
        if case .vehicleLive = currentRoute {
          isInVehicleLivePage = true
        } else {
          isInVehicleLivePage = false
        }

        // 直播页面不显示抓拍通知(抓拍通知为)
        if isInVehicleLivePage {
          completionHandler([])
        } else {
          completionHandler([.banner, .list, .badge, .sound])
        }
      }
      return
    }

    completionHandler([])
  }

  /// 用户点击通知时
  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("📦 userInfo = \(userInfo)")

    let title = response.notification.request.content.title
    let body = response.notification.request.content.body
    print("📝 title = \(title)")
    print("📝 body = \(body)")

    if let urlString = extractLinkURLString(from: userInfo) {
      Task { @MainActor in
        AppStateStore.shared.cachePendingLink(urlString: urlString)
      }
    }
    completionHandler()
  }
}
