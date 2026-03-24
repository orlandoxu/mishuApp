import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppNavigationModel: ObservableObject {
  static let shared = AppNavigationModel()

  @Published var root: NavigationRoot {
    didSet {
      path.removeAll()
    }
  }

  @Published var path: [NavigationPathItem] = []
  private var isShowingWifiDisconnectPrompt = false

  private init() {
    // 非首次启动，根据登录态决定去首页还是登录页
    if SelfStore.shared.isLoggedIn {
      root = .mainTab(.recorder)
    } else {
      root = .login
    }
  }

  func push(_ route: NavigationRoute) {
    path.push(NavigationPathItem(route: route))
  }

  func pop() {
    path.pop()
  }

  /// 处理系统导航栈（如侧滑返回）对 path 的写入。
  /// Wi-Fi 直播页侧滑退出时，先放行退出，再提示是否断开 Wi-Fi。
  func handleSystemPathUpdate(_ newPath: [NavigationPathItem]) {
    let shouldPromptDisconnect = shouldPromptWifiDisconnectAfterGesturePop(newPath: newPath)
    path = newPath
    if shouldPromptDisconnect {
      promptWifiDisconnectAfterGesturePop()
    }
  }

  func replaceTop(with route: NavigationRoute) {
    if path.isEmpty {
      push(route)
    } else {
      path[path.count - 1] = NavigationPathItem(route: route)
    }
  }

  func popToRoot() {
    path.popToRoot()
  }

  func popTo(_ route: NavigationRoute) {
    guard let lastIndex = path.lastIndex(where: { $0.route == route }) else { return }
    path.removeSubrange((lastIndex + 1)...)
  }

  func last() -> NavigationRoute? {
    path.last?.route
  }

  private func shouldPromptWifiDisconnectAfterGesturePop(newPath: [NavigationPathItem]) -> Bool {
    guard newPath.count < path.count else { return false }
    guard let top = path.last else { return false }
    guard case let .vehicleLive(_, entryMode) = top.route else { return false }
    guard entryMode == .wifi else { return false }
    guard WifiStore.shared.isCurrentWifiAppManaged else { return false }
    return isShowingWifiDisconnectPrompt == false
  }

  private func promptWifiDisconnectAfterGesturePop() {
    guard let presenter = Self.topPresentedViewController() else { return }
    isShowingWifiDisconnectPrompt = true

    let alert = UIAlertController(
      title: "提示",
      message: "已退出WIFI预览，是否断开设备WIFI连接？",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "保持连接", style: .cancel) { [weak self] _ in
      self?.isShowingWifiDisconnectPrompt = false
    })
    alert.addAction(UIAlertAction(title: "断开", style: .destructive) { [weak self] _ in
      _ = WifiStore.shared.disconnectCurrentAppManagedWifiIfNeeded()
      self?.isShowingWifiDisconnectPrompt = false
    })
    presenter.present(alert, animated: true)
  }

  private static func topPresentedViewController(base: UIViewController? = nil) -> UIViewController? {
    let root = base ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?.rootViewController

    guard let root else { return nil }
    if let nav = root as? UINavigationController {
      return topPresentedViewController(base: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topPresentedViewController(base: tab.selectedViewController)
    }
    if let presented = root.presentedViewController {
      return topPresentedViewController(base: presented)
    }
    return root
  }
}

enum NavigationRoot: Hashable {
  // case start
  case login
  case mainTab(MainTab)
}

enum NavigationRoute: Hashable {
  case manualBind
  case qrCodeBind
  case web(url: String, title: String?, hideNav: Bool = false, notice: String? = nil)
  case bindStep1
  case bindStep2
  case bindStep3
  case bindStep4
  case homeDetail(id: String)
  case tripDetail(id: String)
  case wifiBind
  case wifiDirect(imei: String)
  case vehicleLive(deviceId: String, entryMode: VehicleLiveEntryMode = .cellular)
  case vehicleDetailCurrent
  case vehicleDetail(imei: String)
  case equipment
  case carBrandSelection(source: CarSelectionSource = .binding)
  case carSeriesSelection(brandId: Int, brandName: String, source: CarSelectionSource = .binding)
  case userInfoEdit
  case nicknameEdit
  case passwordEdit
  case meSetting
  case weChatService
  case cloudBenefits(imei: String)
  case activeLanding(imei: String, entry: ActiveLandingEntry)
  case cloudPlan(imei: String)
  case cloudAlbum(imei: String)
  case localAlbum(imei: String)
  case vehicleSettings(imei: String)
  case settingSubPage(title: String, items: [TemplateItem])
  case settingSelection(title: String, imei: String, itemC: String, options: [RadioPayload.Item], selectedValue: String?, source: String)
  // 下面两个页面，其实没有必要，目前主要是因为模板设计有问题，导致先通过写死的方案来实现。后续需要纳入到模板的协议里面来。
  case settingGps(imei: String)
  case settingVoiceCommand
  case messageRecorderMessageList(deviceId: String, title: String)
  case vehicleInfo(imei: String)
  case vehicleEditNickname(imei: String)
  case vehicleEditLicensePlate(imei: String)
  case vehicleEditVin(imei: String)
  case vehicleEditMileage(imei: String)
  case vehicleEditFuel(imei: String)
  case cloudAlbumDetail(type: CloudAlbumType, imei: String)
  case cloudAlbumAssetDetail(asset: AlbumAsset)
  case orderList
  case cashier(package: PackageItem, imei: String) // 支付页面
  case paymentSuccess // 支付成功页面
  case tCardReplay(imei: String)
}

enum VehicleLiveEntryMode: String, Hashable {
  case cellular
  case wifi
}

enum CarSelectionSource: Hashable {
  case binding
  case vehicleInfo(imei: String)
}

enum ActiveLandingEntry: Hashable {
  case cloudService
  case vehicleLive
}

extension NavigationRoute {
  init?(path: String, params: [RouteParam]) {
    let paramsDict = Dictionary(uniqueKeysWithValues: params.map { ($0.key, $0.value) })

    switch path {
    case "/equipment/manual_bind":
      self = .manualBind
    case "/equipment/qrcode_bind":
      self = .qrCodeBind
    case "/equipment/bind_step1":
      self = .bindStep1
    case "/equipment/bind_step2":
      self = .bindStep2
    case "/webview":
      guard let url = paramsDict["url"] else { return nil }
      self = .web(url: url, title: paramsDict["title"], hideNav: paramsDict["hideNav"] == "true", notice: paramsDict["notice"] ?? nil)
    case "/home/detail":
      guard let id = paramsDict["id"] else { return nil }
      self = .homeDetail(id: id)
    case "/trip/detail":
      guard let id = paramsDict["id"] else { return nil }
      self = .tripDetail(id: id)
    case "/equipment/wifi_bind":
      self = .wifiBind
    case "/equipment/wifi_direct":
      let deviceId = paramsDict["deviceId"] ?? paramsDict["imei"] ?? ""
      guard deviceId.isEmpty == false else { return nil }
      self = .wifiDirect(imei: deviceId)
    case "/equipment/vehicle_live":
      guard let deviceId = paramsDict["deviceId"] else { return nil }
      let modeRaw = (paramsDict["entryMode"] ?? paramsDict["mode"] ?? paramsDict["liveMode"] ?? "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
      let entryMode: VehicleLiveEntryMode
      if modeRaw == "wifi" || modeRaw == "wifi_direct" {
        entryMode = .wifi
      } else {
        entryMode = .cellular
      }
      self = .vehicleLive(deviceId: deviceId, entryMode: entryMode)
    case "/equipment/list":
      self = .equipment
    case "/me/setting", "/me/me_setting":
      self = .meSetting
    case "/me/service":
      self = .weChatService
    case "/me/order":
      self = .orderList
    case "/equipment/tcard":
      guard let deviceId = paramsDict["deviceId"] else { return nil }
      self = .tCardReplay(imei: deviceId)
    default:
      return nil
    }
  }

  /// 辅助方法：构建对应的 View
  @ViewBuilder @MainActor
  func view() -> some View {
    switch self {
    case .manualBind:
      ManualBindView()
    case .qrCodeBind:
      // 如果需要传递参数，可以从 model.path 中获取，或者在枚举中携带
      QRCodeBinding()
    case let .web(url, title, hideNav, notice):
      WebContainerView(urlString: url, title: title, showNavigationBar: !hideNav, notice: notice)
    case .bindStep1:
      CarInfoStep1View()
    case .bindStep2:
      CarInfoStep2View()
    case .bindStep3:
      CarInfoStep3View()
    case .bindStep4:
      CarInfoStep4View()
    case let .homeDetail(id):
      RouteStubViewCopy(path: "/home/detail", params: [RouteParam(key: "id", value: id)])
    case let .tripDetail(id):
      RouteStubViewCopy(path: "/trip/detail", params: [RouteParam(key: "id", value: id)])
    case let .wifiBind:
      WifiBindingView()
    case let .wifiDirect(imei):
      WifiDirectView(imei: imei)
    case let .vehicleLive(deviceId, entryMode):
      VehicleLiveView(deviceId: deviceId, entryMode: entryMode)
    case .vehicleDetailCurrent:
      VehicleDetailView(imei: nil)
    case let .vehicleDetail(imei):
      VehicleDetailView(imei: imei)
    case .equipment:
      VehicleListView()
    case let .carBrandSelection(source):
      CarBrandSelectionView(source: source)
    case let .carSeriesSelection(brandId, brandName, source):
      CarSeriesSelectionView(brandId: brandId, brandName: brandName, source: source)
    case .userInfoEdit:
      UserInfoEditView()
    case .nicknameEdit:
      NicknameEditView()
    case .passwordEdit:
      PasswordEditView()
    case .meSetting:
      MeSettingView()
    case .weChatService:
      WeChatServiceView()
    case let .cloudAlbum(imei):
      CloudAlbumView(imei: imei)
    case let .localAlbum(imei):
      LocalAlbumView(imei: imei)
    case let .vehicleSettings(imei):
      VehicleSettingsView(imei: imei)
    case let .vehicleInfo(imei):
      VehicleInfoView(imei: imei)
    case let .vehicleEditNickname(imei):
      VehicleEditNicknameView(imei: imei)
    case let .vehicleEditLicensePlate(imei):
      VehicleEditLicensePlateView(imei: imei)
    case let .vehicleEditVin(imei):
      VehicleEditVinView(imei: imei)
    case let .vehicleEditMileage(imei):
      VehicleEditMileageView(imei: imei)
    case let .vehicleEditFuel(imei):
      VehicleEditFuelView(imei: imei)
    // TODO: 还需要想想为啥会有俩
    case let .settingSubPage(title, items):
      VehicleSettingsSubPageView(title: title, items: items)
    case let .settingSelection(title, imei, itemC, options, selectedValue, source):
      SettingSelectionView(title: title, imei: imei, itemC: itemC, options: options, selectedValue: selectedValue, source: source)
    case let .settingGps(imei):
      SettingGpsDetailView(imei: imei)
    case .settingVoiceCommand:
      SettingVoiceCommandView()
    case let .messageRecorderMessageList(deviceId, title):
      VehicleMessageList(deviceId: deviceId, title: title)
    case let .cloudAlbumDetail(type, imei):
      AlbumListView(type: type, imei: imei)
    case let .cloudAlbumAssetDetail(asset):
      AssetDetailView(asset: asset)
    case let .cloudBenefits(imei):
      let _ = VehiclesStore.shared.cloudImei = imei
      CloudBenefitsView()
    case let .activeLanding(imei, entry):
      ActiveLandingView(imei: imei, entry: entry)
    case let .cloudPlan(imei):
      CloudPlanView(imei: imei)
    case .orderList:
      OrderListView()
    case let .cashier(package, imei):
      CashierView(package: package, imei: imei)
    case .paymentSuccess:
      PaymentSuccessView()
    case let .tCardReplay(imei):
      TCardReplayView(imei: imei)
    }
  }
}

struct NavigationPathItem: Hashable {
  let id: UUID
  let route: NavigationRoute

  init(id: UUID = UUID(), route: NavigationRoute) {
    self.id = id
    self.route = route
  }
}

private extension Array where Element == NavigationPathItem {
  mutating func push(_ item: Element) {
    append(item)
  }

  mutating func pop() {
    if !isEmpty {
      removeLast()
    }
  }

  mutating func popToRoot() {
    removeAll()
  }
}

/// 复制一份 RouteStubView 以避免访问权限问题
struct RouteStubViewCopy: View {
  let path: String
  let params: [RouteParam]

  var body: some View {
    List {
      Section {
        Text(path)
      }
      if !params.isEmpty {
        Section {
          ForEach(Array(params.enumerated()), id: \.offset) { _, item in
            HStack {
              Text(item.key)
              Spacer()
              Text(item.value)
                .foregroundColor(.secondary)
            }
          }
        }
      }
    }
    .navigationTitle("占位页")
  }
}
