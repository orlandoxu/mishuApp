import Foundation

@MainActor
final class ActiveLandingViewModel: ObservableObject {
  let imei: String

  @Published var isActivating: Bool = false

  init(imei: String) {
    self.imei = imei
  }

  func activateDevice() async -> Bool {
    if isActivating { return false }
    isActivating = true
    defer { isActivating = false }

    await VehicleAPI.shared.activeDevice(imei: imei)

    await VehiclesStore.shared.refresh()

    if let errorMessage = VehiclesStore.shared.errorMessage, errorMessage.isEmpty == false {
      ToastCenter.shared.show("设备列表刷新失败，请稍后重试")
      return false
    }

    guard let refreshedVehicle = VehiclesStore.shared.hashVehicles[imei] else {
      ToastCenter.shared.show("设备信息刷新失败，请稍后重试")
      return false
    }

    guard refreshedVehicle.activeStatus == 2 else {
      ToastCenter.shared.show("设备激活状态未更新，请稍后重试")
      return false
    }

    return true
  }
}
