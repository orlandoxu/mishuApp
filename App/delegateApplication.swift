import Foundation
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate {
  @objc var window: UIWindow?

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    AppLogService.shared.setup()
    LKLog("application didFinishLaunching", type: "app", label: "info")

    UmengService.setup(
      appKey: AppConst.umengAppKey,
      channel: AppConst.umengChannel,
      logEnabled: AppConst.umengLogEnabled
    )

    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func application(
    _: UIApplication,
    supportedInterfaceOrientationsFor _: UIWindow?
  ) -> UIInterfaceOrientationMask {
    OrientationManager.shared.currentMask
  }

  func application(
    _: UIApplication,
    open url: URL,
    options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    WeChatPayCallbackHandler.handleIncomingURL(url, source: "AppDelegate.openURL")
    return false
  }

  func application(
    _: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL {
      WeChatPayCallbackHandler.handleIncomingURL(url, source: "AppDelegate.continue")
    }
    return false
  }
}
