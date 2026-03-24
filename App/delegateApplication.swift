import WechatOpenSDK

final class AppDelegate: NSObject, UIApplicationDelegate {
  @objc var window: UIWindow?
  lazy var wechatDelegate = WeChatOpenSDKDelegate()

  /// deviceToken存储的key
  private let deviceTokenKey = "mishu_ios_device_token"

  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    AppLogService.shared.setup()
    // AppCrashMonitor.shared.install()
    LKLog("application didFinishLaunching", type: "app", label: "info")

    print("[AppDelegate] didFinishLaunching")
    // 先注册wechat
    let appId = AppConst.wechatAppId
    let universalLink = AppConst.wechatUniversalLink
    let ok = WXApi.registerApp(appId, universalLink: universalLink)
    print("[AppDelegate] WXApi.registerApp ok=\(ok)")
    LKLog("wechat registered ok=\(ok)", type: "app", label: "info")

    // 在注册友盟
    UmengService.setup(
      appKey: AppConst.umengAppKey,
      channel: AppConst.umengChannel,
      logEnabled: AppConst.umengLogEnabled
    )

    // 注册远程通知以获取deviceToken
    NoticePermissionStore.shared.requestIfNeeded()

    // 推送通知相关的
    UNUserNotificationCenter.current().delegate = self
    print("[AppDelegate] set UNUserNotificationCenter delegate")

    return true
  }

  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    LKLog("did register remote notifications", type: "app", label: "info")
    print("[AppDelegate] didRegisterForRemoteNotifications")
    // 将deviceToken转换为字符串
    let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
    let token = tokenParts.joined()
    print("[AppDelegate] APNs deviceToken: \(token)")

    // 存储到NoticePermissionStore
    NoticePermissionStore.shared.setDeviceToken(token)

    // 通知SelfStore尝试发送deviceToken
    Task { @MainActor in
      await SelfStore.shared.uploadDeviceTokenIfNeeded()
    }
  }

  /// 注册失败时调用
  func application(
    _: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    LKLog("register remote notifications failed error=\(error.localizedDescription)", type: "app", label: "error")
  }

  /// 支持的界面方向
  func application(
    _: UIApplication,
    supportedInterfaceOrientationsFor _: UIWindow?
  ) -> UIInterfaceOrientationMask {
    OrientationManager.shared.currentMask
  }

  /// 处理打开URL
  func application(
    _: UIApplication,
    open url: URL,
    options _: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let handled = WXApi.handleOpen(url, delegate: wechatDelegate)
    if !handled {
      WeChatPayCallbackHandler.handleIncomingURL(url, source: "AppDelegate.openURL")
    }
    return handled
  }

  func application(
    _: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let webpageURL = userActivity.webpageURL
    let handled = WXApi.handleOpenUniversalLink(userActivity, delegate: wechatDelegate)

    if let url = webpageURL {
      // Step 1. 解析微信回调
      WeChatPayCallbackHandler.handleIncomingURL(url, source: "AppDelegate.continue")

      // Step 2. 解析其他回调
      // TODO: 这儿后面再支持，这儿是要支持h5跳转
      // Task { @MainActor in
      //   AppStateStore.shared.cachePendingLink(urlString: url.absoluteString)
      // }
    }
    return handled
  }
}
