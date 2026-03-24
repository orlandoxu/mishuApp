

extension VehiclesStore {
  var currCloudVehicle: VehicleModel? {
    guard let imei = cloudImei, imei.isEmpty == false else { return nil }
    return hashVehicles[imei]
  }
}
