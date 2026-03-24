import Foundation

/// 定义3种绑定方式
enum BindingType {
  case manual
  case qrCode
  case wifi
}

@MainActor
class BindingStore: ObservableObject, Identifiable {
  static let shared = BindingStore()

  let id = UUID()

  static func == (lhs: BindingStore, rhs: BindingStore) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  /// 绑定方式
  @Published var bindingType: BindingType = .manual

  // Step 0: Input
  @Published var imeiText: String = ""
  @Published var snText: String = ""

  // Step 1: License
  @Published var licensePlate: String = ""
  @Published var province: String = "川"

  /// Step 2: VIN
  @Published var vinText: String = ""

  @Published var vinImg: String = ""

  // Step 3: Car Model
  @Published var carBrandName: String = "" // For display
  @Published var carSeriesName: String = "" // For display
  @Published var seriesId: Int = 0

  // Step 4: OBD / Vehicle Condition
  @Published var totalMiles: String = ""
  @Published var powerType: Int = 2 // Default to Fuel (2)? 1-Electric, 2-Fuel, 3-Hybrid. 0-Not set.
  @Published var engineAutoStart: Int = 0 // 0-No, 1-Yes

  // State
  @Published var isChecking: Bool = false
  @Published var isObdDevice: Int = 0 // From checkBindStatus
  @Published var chipId: String = ""
  @Published var obdSn: String = ""
  @Published var appPlatform: String = "iOS"
  @Published var plateRegion: String = ""
  @Published var needVinPhoto: Bool = false

  /// 绑定的步骤
  @Published var allSteps: [Int] = []
  @Published var currentStep: Int = 1

  /// 每次绑定之前，都要先reset一下
  func resetStore(bindingType: BindingType = .manual) {
    self.bindingType = bindingType
    imeiText = ""
    snText = ""
    licensePlate = ""
    province = "川"
    vinText = ""
    vinImg = ""
    carBrandName = ""
    carSeriesName = ""
    seriesId = 0
    totalMiles = ""
    powerType = 2
    engineAutoStart = 0
    isChecking = false
    isObdDevice = 0
    chipId = ""
    obdSn = ""
    appPlatform = "iOS"
    plateRegion = ""
    needVinPhoto = false
    allSteps = [1, 2, 3, 4]
    currentStep = 1
  }

  /// Logic
  var canSubmitManual: Bool {
    let imei = imeiText.trimmingCharacters(in: .whitespacesAndNewlines)
    let sn = snText.trimmingCharacters(in: .whitespacesAndNewlines)
    return imei.count == 15 && sn.count == 15
  }

  var fullLicense: String {
    if licensePlate.isEmpty { return "" }
    return province + licensePlate.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func checkBindStatus() async -> Bool {
    if isChecking { return false }
    isChecking = true
    defer { isChecking = false }

    let imei = imeiText.trimmingCharacters(in: .whitespacesAndNewlines)
    let sn = snText.trimmingCharacters(in: .whitespacesAndNewlines)

    let result = await UserAPI.shared.canBindVehicle(imei: imei, sn: sn)
    // TODO: 先不检查canBind，后台接口有问题，需要等他们修改
    // if let data = result, data.canBind {
    if let data = result {
      applyCanBindVehicleData(data)

      if isObdDevice == 1 && bindingType != .wifi {
        await ToastCenter.shared.show("OBD设备，请使用Wifi绑定")
        return false
      }

      return true
    }

    return false
  }

  func applyCanBindVehicleData(_ data: CanBindVehicleData) {
    if !data.imei.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      imeiText = data.imei
    }
    if !data.sn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      snText = data.sn
    }
    isObdDevice = data.isObdDevice
    plateRegion = data.plateRegion
    needVinPhoto = data.needVinPhoto
    updateSteps()
    currentStep = 1

    applyPredictCarInfo(data.predictCarInfo)
  }

  var totalStepCount: Int {
    let count = allSteps.count
    return count > 0 ? count : 1
  }

  func updateCurrentStep(for stepNumber: Int) {
    guard let index = allSteps.firstIndex(of: stepNumber) else {
      currentStep = 1
      return
    }
    currentStep = index + 1
  }

  func recommendedNextStepRoute() -> NavigationRoute {
    let firstStep = allSteps.first ?? 1
    return enterStep(firstStep)
  }

  func nextStepNumber(after stepNumber: Int) -> Int? {
    guard let index = allSteps.firstIndex(of: stepNumber) else { return nil }
    let nextIndex = index + 1
    guard nextIndex < allSteps.count else { return nil }
    return allSteps[nextIndex]
  }

  func enterStep(_ stepNumber: Int) -> NavigationRoute {
    updateCurrentStep(for: stepNumber)
    return route(for: stepNumber)
  }

  func route(for stepNumber: Int) -> NavigationRoute {
    switch stepNumber {
    case 1:
      return .bindStep1
    case 2:
      return .bindStep2
    case 3:
      return .bindStep3
    case 4:
      return .bindStep4
    default:
      return .bindStep1
    }
  }

  private func updateSteps() {
    if isObdDevice == 1 || needVinPhoto {
      allSteps = [1, 2, 3, 4]
    } else {
      allSteps = [1, 3]
    }
  }

  private func applyPredictCarInfo(_ info: CanBindVehiclePredictCarInfo?) {
    guard let info else { return }

    let predictedLicense = info.carLicense.trimmingCharacters(in: .whitespacesAndNewlines)
    if !predictedLicense.isEmpty {
      if predictedLicense.count >= 2 {
        province = String(predictedLicense.prefix(1))
        licensePlate = String(predictedLicense.dropFirst())
      } else {
        licensePlate = predictedLicense
      }
    }

    let predictedVin = info.vin.trimmingCharacters(in: .whitespacesAndNewlines)
    if !predictedVin.isEmpty {
      vinText = predictedVin
    }

    let predictedVinImgUrl = info.vinImgUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    if !predictedVinImgUrl.isEmpty {
      vinImg = predictedVinImgUrl
    }

    if info.carSeriesId > 0 {
      seriesId = info.carSeriesId
    }

    let predictedBrand = info.carBrand.trimmingCharacters(in: .whitespacesAndNewlines)
    if !predictedBrand.isEmpty {
      carBrandName = predictedBrand
    }

    let predictedSeries = info.carModel.trimmingCharacters(in: .whitespacesAndNewlines)
    if !predictedSeries.isEmpty {
      carSeriesName = predictedSeries
    }

    if info.powerType > 0 {
      powerType = info.powerType
    }
    engineAutoStart = info.engineAutoStart

    if info.totalMiles > 0 {
      totalMiles = String(format: "%.0f", info.totalMiles)
    }
  }

  func validateVin() async -> Bool {
    if isChecking { return false }
    isChecking = true
    defer { isChecking = false }

    let vin = vinText.trimmingCharacters(in: .whitespacesAndNewlines)
    let result = await UserAPI.shared.isValidVin(vin)
    return result?.isValidVin == true
  }

  func submitBinding() async -> Bool {
    if isChecking { return false }
    isChecking = true
    defer { isChecking = false }

    let license = fullLicense.trimmingCharacters(in: .whitespacesAndNewlines)
    if license.isEmpty {
      ToastCenter.shared.show("请输入车牌号")
      return false
    }

    let payload = UserBindVehiclePayload(
      imei: imeiText.trimmingCharacters(in: .whitespacesAndNewlines),
      sn: snText.trimmingCharacters(in: .whitespacesAndNewlines),
      appPlatform: appPlatform,
      carLicense: license, // DONE-AI: 绑定流程不允许跳过车牌号输入
      vin: vinText.trimmingCharacters(in: .whitespacesAndNewlines),
      vinImg: vinImg,
      seriesId: seriesId,
      totalMiles: Float(totalMiles) ?? 0.0,
      engineAutoStart: engineAutoStart,
      powerType: powerType,
      isObdDevice: isObdDevice,
      chipId: chipId,
      obdSn: obdSn
    )

    let result = await UserAPI.shared.bindVehicle(payload: payload)
    return result != nil
  }
}
