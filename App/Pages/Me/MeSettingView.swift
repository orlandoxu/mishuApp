import Kingfisher
import SwiftUI

struct MeSettingView: View {
  private enum SettingAlertType: Identifiable {
    case deleteAccountFirst
    case deleteAccountSecond
    case clearCache
    case switchEnvironment

    var id: Int {
      switch self {
      case .deleteAccountFirst:
        return 1
      case .deleteAccountSecond:
        return 2
      case .clearCache:
        return 3
      case .switchEnvironment:
        return 4
      }
    }
  }

  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @StateObject private var selfStore: SelfStore = .shared
  @State private var cacheSize: String = "0.00M"
  @State private var showLogoutAlert = false
  @State private var activeAlert: SettingAlertType?
  @State private var logoTapTimestamps: [Date] = []
  @State private var showEnvironmentPicker = false
  @State private var pendingEnvironment: AppEnvironment?
  @State private var isUploadingLog: Bool = false
  @AppStorage(AppConst.environmentKey) private var currentEnvironmentRaw: String = AppEnvironment.testing.rawValue

  var body: some View {
    VStack(spacing: 0) {
      NavHeader(title: "App设置")

      ScrollView {
        VStack(spacing: 24) {
          // Logo & Version
          VStack(spacing: 8) {
            Image("AppLogo") // Standard AppIcon asset name often works, or use a specific logo asset
              .resizable()
              .scaledToFit()
              .frame(width: 80, height: 80)
              .cornerRadius(16)
              .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
              .onTapGesture {
                handleLogoTap()
              }

            Text("路刻")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(Color(hex: "0x111111"))

            Text("版本: V\(appVersion)")
              .font(.system(size: 14))
              .foregroundColor(Color(hex: "0x999999"))
          }
          .padding(.top, 20)

          VStack(spacing: 12) {
            // Group 1: Permissions
            MeMenuCard {
              SettingRow(icon: "icon_settings_permission", title: "系统权限") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                  UIApplication.shared.open(url)
                }
              }
            }

            // Group 2: Language, Update, Cache
            MeMenuCard {
              // 下个版本在做这个
              // SettingRow(icon: "icon_settings_language", title: "语言选择", rightText: "简体中文") {
              //   // Language selection
              // }
              MeMenuDivider()
              SettingRow(icon: "icon_settings_update", title: "检查新版本") {
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id6759820233") {
                  UIApplication.shared.open(url)
                }
              }
              MeMenuDivider()
              SettingRow(icon: "icon_settings_clear", title: "清理缓存", rightText: cacheSize) {
                activeAlert = .clearCache
              }
            }

            // Group 3: Logs, WeChat
            MeMenuCard {
              SettingRow(icon: "icon_settings_upgrade", title: "上传日志") {
                uploadLogs()
              }
              .disabled(isUploadingLog)
              MeMenuDivider()
              SettingRow(icon: "icon_settings_wechat", title: "官方客服微信") {
                appNavigation.push(.weChatService)
              }
            }

            // Group 4: Agreements
            MeMenuCard {
              SettingRow(icon: "icon_settings_protocol", title: "用户服务协议") {
                appNavigation.push(.web(url: AppConst.userAgreementUrl, title: "用户服务协议"))
              }
              MeMenuDivider()
              SettingRow(icon: "icon_settings_privacy", title: "隐私协议") {
                appNavigation.push(.web(url: AppConst.privacyPolicyUrl, title: "隐私协议"))
              }
            }
          }
          .padding(.horizontal, 16)

          // Footer: Logout / Delete Account
          VStack(spacing: 8) {
            Button {
              print("[MeSetting] 点击了注销账号按钮")
              activeAlert = .deleteAccountFirst
              print("[MeSetting] activeAlert 已设置为 deleteAccountFirst")
            } label: {
              Text("注销账号")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "0x666666"))
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("注销后，您的所有数据将被永久删除且无法恢复，请谨慎操作。")
              .font(.system(size: 12))
              .foregroundColor(Color(hex: "0x999999"))
              .lineLimit(nil)
              .multilineTextAlignment(.leading)
              .padding(.horizontal, 24)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.top, 10)
          .padding(.bottom, 40)

          Spacer().frame(height: 60)
        }
        .background(Color(hex: "0xF8F8F8").ignoresSafeArea())
      }
    }
    .navigationBarHidden(true)
    .ignoresSafeArea()
    // .background(Color.white.ignoresSafeArea())
    .onAppear {
      calculateCacheSize()
    }
    .onChange(of: activeAlert) { newValue in
      print("[MeSetting] activeAlert 变化: \(String(describing: newValue))")
    }
    .alert(item: $activeAlert) { alert in
      switch alert {
      case .deleteAccountFirst:
        Alert(
          title: Text("确认注销"),
          message: Text("注销后，您的所有数据将被永久删除且无法恢复，请谨慎操作。"),
          primaryButton: .destructive(Text("确认注销")) {
            activeAlert = .deleteAccountSecond
          },
          secondaryButton: .cancel(Text("取消"))
        )
      case .deleteAccountSecond:
        Alert(
          title: Text("再次确认"),
          message: Text("您确定要注销账号吗？此操作不可撤销。"),
          primaryButton: .destructive(Text("确定注销")) {
            deleteAccount()
          },
          secondaryButton: .cancel(Text("再想想"))
        )
      case .clearCache:
        Alert(
          title: Text("请确认"),
          message: Text("确定清除所有缓存吗？"),
          primaryButton: .destructive(Text("确定")) {
            clearCache()
          },
          secondaryButton: .cancel(Text("取消"))
        )
      case .switchEnvironment:
        Alert(
          title: Text("切换环境"),
          message: Text("切换到\(pendingEnvironment?.title ?? "目标环境")后，将清除缓存并退出登录。是否继续？"),
          primaryButton: .destructive(Text("继续")) {
            Task {
              await switchEnvironmentAndResetSession()
            }
          },
          secondaryButton: .cancel(Text("取消")) {
            pendingEnvironment = nil
          }
        )
      }
    }
    .actionSheet(isPresented: $showEnvironmentPicker) {
      ActionSheet(
        title: Text("选择运行环境"),
        message: Text("当前环境：\(currentEnvironment.title)"),
        buttons: [
          .default(Text(AppEnvironment.testing.title)) {
            requestEnvironmentSwitch(.testing)
          },
          .default(Text(AppEnvironment.production.title)) {
            requestEnvironmentSwitch(.production)
          },
          .cancel(Text("取消")),
        ]
      )
    }
    .overlay(
      Group {
        if isUploadingLog {
          ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            ProgressView("日志上传中...")
              .padding()
              .background(Color.white)
              .cornerRadius(8)
          }
        }
      }
    )
  }

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
  }

  private func calculateCacheSize() {
    ImageCache.default.calculateDiskStorageSize { result in
      DispatchQueue.main.async {
        switch result {
        case let .success(size):
          let mb = Double(size) / 1024 / 1024
          self.cacheSize = String(format: "%.2fM", mb)
        case .failure:
          self.cacheSize = "0.00M"
        }
      }
    }
  }

  private func clearCache() {
    ImageCache.default.clearDiskCache {
      DispatchQueue.main.async {
        self.cacheSize = "0.00M"
        ToastCenter.shared.show("缓存已清理")
      }
    }
  }

  private func handleLogoTap() {
    let now = Date()
    logoTapTimestamps.append(now)
    logoTapTimestamps = logoTapTimestamps.filter { now.timeIntervalSince($0) <= 1.8 }
    if logoTapTimestamps.count >= 5 {
      logoTapTimestamps.removeAll()
      showEnvironmentPicker = true
    }
  }

  private var currentEnvironment: AppEnvironment {
    AppEnvironment(rawValue: currentEnvironmentRaw) ?? .testing
  }

  private func requestEnvironmentSwitch(_ environment: AppEnvironment) {
    if environment == currentEnvironment {
      ToastCenter.shared.show("当前已是\(environment.title)")
      return
    }
    pendingEnvironment = environment
    activeAlert = .switchEnvironment
  }

  @MainActor
  private func switchEnvironmentAndResetSession() async {
    guard let target = pendingEnvironment else { return }

    AppConst.setEnvironment(target)
    currentEnvironmentRaw = target.rawValue
    UserDefaults.standard.removeObject(forKey: "tuyun_base_url_override")
    URLCache.shared.removeAllCachedResponses()
    if let cookies = HTTPCookieStorage.shared.cookies {
      for cookie in cookies {
        HTTPCookieStorage.shared.deleteCookie(cookie)
      }
    }

    ImageCache.default.clearMemoryCache()
    await clearImageDiskCache()

    await SelfStore.shared.logout(false)

    // 切换环境后同步清理业务缓存，避免旧环境残留数据
    VehiclesStore.shared.vehicles = []
    VehiclesStore.shared.deviceOnlineStatus = [:]
    VehiclesStore.shared.latestGPSData = [:]
    VehiclesStore.shared.vehicleDetailImei = nil
    VehiclesStore.shared.liveImei = nil
    VehiclesStore.shared.cloudImei = nil
    WifiStore.shared.reset()

    pendingEnvironment = nil
    appNavigation.root = .login
    ToastCenter.shared.show("已切换到\(target.title)")
  }

  private func clearImageDiskCache() async {
    await withCheckedContinuation { continuation in
      ImageCache.default.clearDiskCache {
        continuation.resume()
      }
    }
  }

  private func deleteAccount() {
    Task {
      // Step 1. 调用注销账号 API
      let result = await UserAPI.shared.deregister()

      // Step 2. 如果注销成功，清理本地数据并跳转登录页
      await SelfStore.shared.logout()
      await MainActor.run {
        appNavigation.root = .login
      }
    }
  }

  private var safeAreaTop: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
  }

  private func uploadLogs() {
    if isUploadingLog { return }
    isUploadingLog = true
    LKLog("tap upload logs", type: "user", label: "info")
    Task {
      let result = await AppLogService.shared.uploadCurrentLog(trigger: .manual)
      await MainActor.run {
        isUploadingLog = false
        if result.success {
          ToastCenter.shared.show("日志上传成功")
        } else {
          ToastCenter.shared.show(result.reason ?? "日志上传失败")
        }
      }
    }
  }
}

/// Local SettingRow to handle system icons
struct SettingRow: View {
  let icon: String
  let title: String
  var rightText: String? = nil
  var isSystemIcon: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        if isSystemIcon {
          Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundColor(Color(hex: "0x333333")) // Icon color
        } else {
          Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
        }

        Text(title)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        Spacer()

        if let rightText = rightText {
          Text(rightText)
            .font(.system(size: 14))
            .foregroundColor(Color(hex: "0x666666"))
        }

        Image("icon_more_arrow")
          .resizable()
          .scaledToFit()
          .frame(width: 12, height: 12)
          .foregroundColor(Color(hex: "0xCCCCCC"))
      }
      .padding(.horizontal, 16)
      .frame(height: 56)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
