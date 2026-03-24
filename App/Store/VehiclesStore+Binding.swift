import Foundation

extension VehiclesStore {
  func unbind(imei: String) async {
    let result = await UserAPI.shared.unbindVehicle(imei: imei)
    if result != nil {
      removeVehicle(imei: imei)
    } else {
      errorMessage = "解绑失败"
    }
  }
}
