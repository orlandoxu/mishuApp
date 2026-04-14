import Foundation
import UIKit

@MainActor
protocol MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any]
}

@MainActor
enum MobileInfoStateReportBuilder {
  static func buildMobileInfoPayload() -> [String: Any] {
    [
      "mobilePlatform": "iOS",
      "mobileOs": UIDevice.current.systemVersion,
      "appState": buildAppStateJSONString(),
    ]
  }

  static func buildAppStateJSONString() -> String {
    let appStateTree: [String: Any] = [
      "reportVersion": 1,
      "generatedAt": Int64(Date().timeIntervalSince1970),
      "application": buildApplicationSnapshot(),
      "stores": buildStoreSnapshot(),
      "plugins": buildPluginSnapshot(),
    ]

    guard JSONSerialization.isValidJSONObject(appStateTree),
          let data = try? JSONSerialization.data(withJSONObject: appStateTree, options: [.sortedKeys]),
          let text = String(data: data, encoding: .utf8)
    else {
      return "{}"
    }

    return text
  }

  private static func buildApplicationSnapshot() -> [String: Any] {
    let info = Bundle.main.infoDictionary ?? [:]
    let appVersion = info["CFBundleShortVersionString"] as? String ?? ""
    let buildVersion = info["CFBundleVersion"] as? String ?? ""
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    let locale = Locale.preferredLanguages.first ?? Locale.current.identifier

    return [
      "bundleId": bundleId,
      "appVersion": appVersion,
      "buildVersion": buildVersion,
      "locale": locale,
      "timeZone": TimeZone.current.identifier,
      "applicationState": UIApplication.shared.applicationState.mobileInfoValue,
    ]
  }

  private static func buildStoreSnapshot() -> [String: Any] {
    [
      "appStateStore": AppStateStore.shared.serializeForMobileInfo(),
      "selfStore": SelfStore.shared.serializeForMobileInfo(),
      "messageStore": MessageStore.shared.serializeForMobileInfo(),
      "bindingStore": BindingStore.shared.serializeForMobileInfo(),
      "vehiclesStore": VehiclesStore.shared.serializeForMobileInfo(),
      "webSocketStore": WebSocketStore.shared.serializeForMobileInfo(),
      "templateStore": TemplateStore.shared.serializeForMobileInfo(),
      "wifiStore": WifiStore.shared.serializeForMobileInfo(),
    ]
  }

  private static func buildPluginSnapshot() -> [String: Any] {
    [
      "permissions": MobileInfoPermissionPlugin.snapshot(),
      "liveUserLocation": MobileInfoLiveUserLocationPlugin.snapshot(),
    ]
  }
}

private extension UIApplication.State {
  var mobileInfoValue: String {
    switch self {
    case .active:
      return "active"
    case .inactive:
      return "inactive"
    case .background:
      return "background"
    @unknown default:
      return "unknown"
    }
  }
}
