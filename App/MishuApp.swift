import Kingfisher
import SwiftUI
import UIKit

@main
struct MishuApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @AppStorage("mishu_first_start") private var isFirstStart: Bool = true
  @AppStorage(AppConst.environmentKey) private var environmentRaw: String = AppEnvironment.testing.rawValue
  @AppStorage(AppConst.environmentUserSelectedKey) private var environmentUserSelected: Bool = false

  init() {
    print("BundleID:", Bundle.main.bundleIdentifier ?? "")
    // TODO: 开发阶段，这个先不要删除
    // UserDefaults.standard.set("zmBiNeSRj5uM36pb", forKey: "mishu_auth_token")
    let appearance = UINavigationBarAppearance()

    // 将导航栏设置为"完全不透明"
    // 作用：
    // 1. 关闭系统默认的毛玻璃效果
    // 2. 防止页面内容滚动到导航栏下面
    // 3. 避免出现顶部背景穿透（黑边 / 透明条）
    appearance.configureWithOpaqueBackground()

    // 设置导航栏背景颜色
    // 这里强制为白色：
    // - 在浅色模式下正常
    // - 在深色模式下也会保持白色（不会自动变黑）
    appearance.backgroundColor = .white

    // 设置「普通标题」文字颜色
    // 比如 push 到子页面时显示在中间的标题
    // 不设置的话，系统可能在深色模式下用白字
    appearance.titleTextAttributes = [
      .foregroundColor: UIColor.black,
    ]

    // 设置「大标题」文字颜色（largeTitle 模式）
    // 常见于列表页向下滚动前的大号标题
    appearance.largeTitleTextAttributes = [
      .foregroundColor: UIColor.black,
    ]

    // 应用到导航栏的"标准状态"
    // 包括：
    // - 普通页面
    // - 子页面 push 之后的状态
    UINavigationBar.appearance().standardAppearance = appearance

    // 应用到"滚动到顶部"的状态（大标题展开时）
    // 如果不设置这一行：
    // - iOS 15+ 常见问题：顶部突然变透明或变黑
    UINavigationBar.appearance().scrollEdgeAppearance = appearance

    // 网络层，通过磁盘缓存数据
    ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
    ImageCache.default.diskStorage.config.sizeLimit = 300 * 1024 * 1024
    ImageCache.default.diskStorage.config.expiration = .days(14)
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Color.white.ignoresSafeArea()

        AppNavigationStack()
          .ignoresSafeArea()

        if currentEnvironment == .testing {
          DevCornerTag()
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
      }
      .onOpenURL { url in
        WeChatPayCallbackHandler.handleIncomingURL(url, source: "SwiftUI.onOpenURL")
      }
      .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
        WeChatPayCallbackHandler.handleUserActivity(userActivity, source: "SwiftUI.onContinueUserActivity")
      }
      // 触发用户授权网络
      .taskOnce {
        isFirstStart = false
        _ = await UserAPI.shared.ping()
      }
      .taskOnce {
        await MainActor.run {
          AppStateStore.shared.markBootstrapFinished()
        }
      }
      .preferredColorScheme(.light)
    }
  }

  private var currentEnvironment: AppEnvironment {
    if !environmentUserSelected { return .testing }
    return AppEnvironment(rawValue: environmentRaw) ?? .testing
  }
}

private struct DevCornerTag: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          LinearGradient(
            colors: [Color(hex: "0xF0F2F5"), Color(hex: "0xDDE2E8")],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .overlay(
          Rectangle()
            .stroke(Color.white.opacity(0.92), lineWidth: 1)
        )
        .frame(width: 168, height: 24)

      Text("D  E  V")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(Color(hex: "0xB5B5B5"))
        .tracking(1.2)
    }
    .rotationEffect(.degrees(45))
    .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
    .opacity(0.6)
    .offset(x: 40, y: 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
  }
}
