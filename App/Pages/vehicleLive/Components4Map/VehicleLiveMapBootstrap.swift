import AMapFoundationKit
import MAMapKit

/// 车辆直播地图的高德 SDK 引导初始化（隐私合规 + Key 配置），保证只初始化一次
enum VehicleLiveMapBootstrap {
  private static var didSetup = false

  static func setupIfNeeded() {
    // Step 1. 防止重复初始化
    if didSetup { return }
    didSetup = true

    // Step 2. 隐私合规（必须在初始化地图前设置）
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)

    // Step 3. 设置 Key
    AMapServices.shared().apiKey = AppConst.gaoDeKey
    AMapServices.shared().enableHTTPS = true
  }
}
