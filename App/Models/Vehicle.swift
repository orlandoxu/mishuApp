import Foundation
import SwiftUI
import UIKit

struct WifiModel: Decodable {
  let enableWayStr: String
  let SSID: String
  let wifiPwd: String
}

struct VehicleModel: Decodable {
  let imei: String
  let sn: String
  let wid: String
  let nickname: String
  let versionType: String

  let activeStatus: Int // 1试用中 2生效 3已到期 4强制生效中
  let activeTime: String
  let bindTime: String
  let deviceImageUrl: String
  let activeType: Int

  let cameraTemplate: String
  let canUsed: Bool
  let customer: String
  let defaultCamera: String
  let warrantyPeriod: Int
  let expireTime: String
  let iccid: String
  let logoUrl: String
  let offlineReason: String
  var onlineStatus: Int
  let preferredLanguage: String
  let status: Int
  let thumbnail: String
  let deviceExpireTime: String
  let watermarkUrl: String
  /// 直播
  var did: String
  var xcLocalSlat: String

  // 复合字段
  let wifi: WifiModel?
  let car: CarModel?
  var gps: GPSModel?
  let obd: OBDModel?
  let obdStatus: OBDStatusModel?
  var realtime: VehicleRealtimeModel?
  let sim: SimModel?
  let ability: AbilityModel?

  /// 需要后期其他接口补充的字段
  /// 行程报告不从车辆列表解码；后续由独立接口拉取并合并
  var travelReport: [TripData]? = nil

  var statusInfo: OBDDeviceStatusData? = nil
  var tripList: [TripData] = []
  var tripStats: TripStatisticalData? = nil

  var cloudBenefitResources: [DeviceResource] = []

  // 暂时没用到先不解析（后台也没传过来）
  // let qrcode: VehicleQRCodeModel
  // let onlineCount: Int
  // let deviceState: Int

  var canConnect: Bool {
    onlineStatus == 1 || onlineStatus == 2 || onlineStatus == 7
  }

  var activeStatusText: String {
    activeStatus == 1 ? "试用中" : activeStatus == 2 ? "生效中" : activeStatus == 3 ? "已到期" : "生效中"
  }

  var bindAt: Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.date(from: bindTime) ?? Date(timeIntervalSince1970: 0)
  }

  /// 计算属性
  var onlineStatusText: String {
    if onlineStatus == 1 { return "点火在线" }
    else if onlineStatus == 2 { return "震动感知" } // 震动感知中
    else if onlineStatus == 3 { return "关机" }
    else if onlineStatus == 4 { return "熄火离线" }
    else if onlineStatus == 5 { return "离线" }
    else if onlineStatus == 6 { return "低电关闭" }
    else if onlineStatus == 7 { return "缩时录影" } // 缩时录影
    else if onlineStatus == 8 { return "保护电瓶关机" }
    else if onlineStatus == 9 { return "低功耗哨兵模式" } // 哨兵模式
    return "离线"
  }

  var onlineStatusShortText: String {
    if onlineStatus == 1 { return "在线" }
    else if onlineStatus == 2 { return "监控" }
    else if onlineStatus == 3 { return "关机" }
    else if onlineStatus == 4 { return "离线" }
    else if onlineStatus == 5 { return "离线" }
    else if onlineStatus == 6 { return "关机" }
    else if onlineStatus == 7 { return "缩时" }
    else if onlineStatus == 8 { return "关机" }
    else if onlineStatus == 9 { return "哨兵" }
    return "离线"
  }

  /// 是否在4G页面显示是否开启抄牌
  private var isPoliceDetecting: Bool {
    let text = realtime?.policeStatusString.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if text.isEmpty { return false }
    if text.contains("未开启") { return false }
    if text.contains("侦测") || text.contains("检测") { return true }
    if text.contains("开启") || text.contains("已开启") { return true }
    return false
  }

  /// 4G页面，用什么icon来显示状态
  var liveStatusIconName: String {
    if isPoliceDetecting { return "icon_status_parking" }
    if onlineStatus == 1 { return "icon_status_online" }
    if onlineStatus == 2 { return "icon_status_parking" }
    if onlineStatus == 3 { return "icon_status_poweroff" }
    if onlineStatus == 7 { return "icon_status_timelapse" }
    if onlineStatus == 6 { return "icon_status_poweroff" }
    if onlineStatus == 8 { return "icon_status_poweroff" }
    if onlineStatus == 9 { return "icon_status_sentinel" }
    return "icon_status_offline"
  }

  /// 在4G页面，状态的描述
  var liveStatusDescription: String {
    if isPoliceDetecting { return "抄牌识别侦测中" }
    if onlineStatus == 2 { return "震动感知模式" }
    if onlineStatus == 1 { return "设备在线" }
    if onlineStatus == 3 { return "设备已关机" }
    if onlineStatus == 7 { return "缩时录影中" }
    if onlineStatus == 6 { return "设备已低电关机" }
    if onlineStatus == 8 { return "设备已护电关机" }
    return "设备离线"
  }

  var liveStatusColorUi: UIColor {
    if liveStatusIconName == "icon_status_online" { return UIColor(Color(hex: "0x11C06A")) }
    if liveStatusIconName == "icon_status_parking" { return ThemeColor.brand500Ui }
    if liveStatusIconName == "icon_status_timelapse" { return ThemeColor.brand500Ui }
    if liveStatusIconName == "icon_status_sentinel" { return UIColor(Color(hex: "0xF68733")) }
    return UIColor(Color(hex: "0x999999"))
  }

  var isSnapshotAvailable: Bool {
    if onlineStatus == 1 { return true }
    if onlineStatus == 2 { return true }
    if onlineStatus == 7 { return true }
    return false
  }

  var statusDotColor: Color {
    // onlineStatus == 0 ? Color.gray.opacity(0.5) : Color.green
    if onlineStatus == 1 { return Color.green }
    else if onlineStatus == 2 { return Color.yellow }
    else if onlineStatus == 3 { return Color.gray.opacity(0.5) }
    else if onlineStatus == 4 { return Color.gray.opacity(0.5) }
    else if onlineStatus == 5 { return Color.gray.opacity(0.5) }
    else if onlineStatus == 6 { return Color.gray.opacity(0.5) }
    else if onlineStatus == 7 { return Color.yellow }
    else if onlineStatus == 8 { return Color.gray.opacity(0.5) }
    return Color.gray.opacity(0.5)
  }

  // var bindTimeTs: Int {
  //   // 把 数据结构返回一下
  //   return
  // }

  private enum CodingKeys: String, CodingKey {
    case id
    case imei
    case sn
    case wid
    case nickname
    case versionType
    case activeStatus
    case activeTime
    case bindTime
    case deviceImageUrl
    case activeType
    case cameraTemplate
    case canUsed
    case customer
    case defaultCamera
    case warrantyPeriod
    case expireTime
    case iccid
    case logoUrl
    case offlineReason
    // case onlineCount
    case onlineStatus
    case preferredLanguage
    case status
    case thumbnail
    case deviceExpireTime
    // case deviceState
    case watermarkUrl
    case did
    case xcLocalSlat
    case wifi
    case car
    case gps
    case obd
    case obdStatus
    case realtime
    case sim
    case ability
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let idFallback = container.safeDecodeString(.id, "")
    let decodedImei = container.safeDecodeString(.imei, idFallback)
    imei = decodedImei.isEmpty ? idFallback : decodedImei

    sn = container.safeDecodeString(.sn, "")
    wid = container.safeDecodeString(.wid, "")
    nickname = container.safeDecodeString(.nickname, "")
    versionType = container.safeDecodeString(.versionType, "")

    activeStatus = container.safeDecodeInt(.activeStatus, 0)
    activeTime = container.safeDecodeString(.activeTime, "")
    bindTime = container.safeDecodeString(.bindTime, "")
    deviceImageUrl = container.safeDecodeString(.deviceImageUrl, "")

    activeType = container.safeDecodeInt(.activeType, 0)

    cameraTemplate = container.safeDecodeString(.cameraTemplate, "")
    canUsed = container.safeDecodeBool(.canUsed, false)
    customer = container.safeDecodeString(.customer, "")
    defaultCamera = container.safeDecodeString(.defaultCamera, "")
    warrantyPeriod = container.safeDecodeInt(.warrantyPeriod, 0)
    expireTime = container.safeDecodeString(.expireTime, "")
    iccid = container.safeDecodeString(.iccid, "")
    logoUrl = container.safeDecodeString(.logoUrl, "")
    offlineReason = container.safeDecodeString(.offlineReason, "")
    // onlineCount = container.safeDecodeInt(.onlineCount, 0)
    onlineStatus = container.safeDecodeInt(.onlineStatus, 0)
    preferredLanguage = container.safeDecodeString(.preferredLanguage, "")
    status = container.safeDecodeInt(.status, 0)
    thumbnail = container.safeDecodeString(.thumbnail, "")
    deviceExpireTime = container.safeDecodeString(.deviceExpireTime, "")
    // deviceState = container.safeDecodeInt(.deviceState, 0)
    watermarkUrl = container.safeDecodeString(.watermarkUrl, "")
    did = container.safeDecodeString(.did, "")
    xcLocalSlat = container.safeDecodeString(.xcLocalSlat, "")
    // did = "PP601A00160EE1B927"
    // xcLocalSlat = "wlX3P6SXXF3lxrDxoOumYg=="
    wifi = try? container.decodeIfPresent(WifiModel.self, forKey: .wifi) ?? nil
    car = (try? container.decodeIfPresent(CarModel.self, forKey: .car)) ?? nil
    gps = try? container.decodeIfPresent(GPSModel.self, forKey: .gps)
    obd = try? container.decodeIfPresent(OBDModel.self, forKey: .obd)
    obdStatus = try? container.decodeIfPresent(OBDStatusModel.self, forKey: .obdStatus) ?? nil
    realtime =
      (try? container.decodeIfPresent(VehicleRealtimeModel.self, forKey: .realtime)) ?? VehicleRealtimeModel()
    sim = (try? container.decodeIfPresent(SimModel.self, forKey: .sim)) ?? nil
    ability = (try? container.decodeIfPresent(AbilityModel.self, forKey: .ability)) ?? nil

    // 后面是需要后期补充的字段
    // travelReport = nil
  }
}

struct VehicleRealtimeModel: Decodable {
  let accuracy: Int
  let authIntelligentTransport: Int
  let authRemoteService: Int
  let authTrafficImprove: Int
  let authTravelManage: Int // 0: 未设置 1: 支持 2: 不支持
  let generateTravelReport: Int
  let cloudVideo: Int
  let frontResolution: String
  let fullResolution: String
  let incarResolution: String
  let lastStatusTime: Int64
  let policeStatus: Int
  let policeStatusString: String
  let positionType: Int
  let rearResolution: String
  let rightResolution: String
  let status: Int
  let statusChangeTime: Int64
  var tcard: Bool
  let voltage: Int

  private enum CodingKeys: String, CodingKey {
    case accuracy
    case authIntelligentTransport
    case authRemoteService
    case authTrafficImprove
    case authTravelManage
    case generateTravelReport
    case cloudVideo
    case frontResolution
    case fullResolution
    case incarResolution
    case lastStatusTime
    case policeStatus
    case policeStatusString
    case positionType
    case rearResolution
    case rightResolution
    case status
    case statusChangeTime
    case tcard
    case voltage
  }

  init(
    accuracy: Int = 0,
    authIntelligentTransport: Int = 0,
    authRemoteService: Int = 0,
    authTrafficImprove: Int = 0,
    authTravelManage: Int = 0,
    generateTravelReport: Int = 0,
    cloudVideo: Int = 0,
    frontResolution: String = "",
    fullResolution: String = "",
    incarResolution: String = "",
    lastStatusTime: Int64 = 0,
    policeStatus: Int = 0,
    policeStatusString: String = "",
    positionType: Int = 0,
    rearResolution: String = "",
    rightResolution: String = "",
    status: Int = 0,
    statusChangeTime: Int64 = 0,
    tcard: Bool = false,
    voltage: Int = 0
  ) {
    self.accuracy = accuracy
    self.authIntelligentTransport = authIntelligentTransport
    self.authRemoteService = authRemoteService
    self.authTrafficImprove = authTrafficImprove
    self.authTravelManage = authTravelManage
    self.generateTravelReport = generateTravelReport
    self.cloudVideo = cloudVideo
    self.frontResolution = frontResolution
    self.fullResolution = fullResolution
    self.incarResolution = incarResolution
    self.lastStatusTime = lastStatusTime
    self.policeStatus = policeStatus
    self.policeStatusString = policeStatusString
    self.positionType = positionType
    self.rearResolution = rearResolution
    self.rightResolution = rightResolution
    self.status = status
    self.statusChangeTime = statusChangeTime
    self.tcard = tcard
    self.voltage = voltage
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    accuracy = container.safeDecodeInt(.accuracy, 0)
    authIntelligentTransport = container.safeDecodeInt(.authIntelligentTransport, 0)
    authRemoteService = container.safeDecodeInt(.authRemoteService, 0)
    authTrafficImprove = container.safeDecodeInt(.authTrafficImprove, 0)
    authTravelManage = container.safeDecodeInt(.authTravelManage, 0)
    generateTravelReport = container.safeDecodeInt(.generateTravelReport, 0)
    cloudVideo = container.safeDecodeInt(.cloudVideo, 0)
    frontResolution = container.safeDecodeString(.frontResolution, "")
    fullResolution = container.safeDecodeString(.fullResolution, "")
    incarResolution = container.safeDecodeString(.incarResolution, "")
    lastStatusTime = container.safeDecodeInt64(.lastStatusTime, 0)
    policeStatus = container.safeDecodeInt(.policeStatus, 0)
    policeStatusString = container.safeDecodeString(.policeStatusString, "")
    positionType = container.safeDecodeInt(.positionType, 0)
    rearResolution = container.safeDecodeString(.rearResolution, "")
    rightResolution = container.safeDecodeString(.rightResolution, "")
    status = container.safeDecodeInt(.status, 0)
    statusChangeTime = container.safeDecodeInt64(.statusChangeTime, 0)
    tcard = container.safeDecodeBool(.tcard, false)
    voltage = container.safeDecodeInt(.voltage, 0)
  }
}

struct AbilityModel: Decodable {
  let gps: Int
  let live: Int
  let real: Int
  let sos: Int
  let preview: Int
  let cloud: Int
  let voice: Int
  let voiceCapture: Int
  let voiceCommand: Int
  let hotPoint: Int
  let travelReport: Int
  let travelReplay: Int
  let front: Int
  let rear: Int
  let incar: Int
  let right: Int
  let full: Int
  let travelAccident: Int
  let dormancyAccident: Int
  let parkReport: Int
  let trafficPolice: Int
  let navigate: Int
  let playTCard: Int
  let playTCardV2: Int
  let tCardAttach: Int
  let remoteTCard: Int
  let remoteTCardAcc: Int
  let remoteSetting: Int
  let reduceRecord: Int
  let reduceImage: Int
  let reduceVideo: Int
  let reduceLive: Int
  let toReduceRecord: Int
  let ledBulb: Int
  let edog: Int
  let streamNum: Int
  let cameraCut: Int
  let simInModel: Int
  let simOutModel: Int
  let obd: Int
  let obdEnabled: Int
  let authService: Int
  let authServiceV3: Int
  let supportIntelligentTransport: Int
  let supportTravelManage: Int
  let supportTrafficImprove: Int
  let supportRemoteService: Int
  let authSetting: Int
  let deviceMosaic: Int
  let eaglePhoto: Int
  let reportException: Int
  let sensitiveAccon: Int
  let cutframeLD: Int
  let cutframeMG: Int
  let cutframeSR: Int
  let cutframeTX: Int
  let cutframeWJ: Int
  let cutframeYK: Int
  let status: Int

  private enum CodingKeys: String, CodingKey {
    case gps
    case live
    case real
    case sos = "SOS"
    case preview
    case cloud
    case voice
    case voiceCapture
    case voiceCommand
    case hotPoint
    case travelReport
    case travelReplay
    case front
    case rear
    case incar
    case right
    case full
    case travelAccident
    case dormancyAccident
    case parkReport
    case trafficPolice
    case navigate
    case playTCard
    case playTCardV2
    case tCardAttach
    case remoteTCard
    case remoteTCardAcc
    case remoteSetting
    case reduceRecord
    case reduceImage
    case reduceVideo
    case reduceLive
    case toReduceRecord
    case ledBulb
    case edog
    case streamNum
    case cameraCut
    case simInModel
    case simOutModel
    case obd = "OBD"
    case obdEnabled
    case authService
    case authServiceV3
    case supportIntelligentTransport
    case supportTravelManage
    case supportTrafficImprove
    case supportRemoteService
    case authSetting
    case deviceMosaic
    case eaglePhoto
    case reportException
    case sensitiveAccon
    case cutframeLD
    case cutframeMG
    case cutframeSR
    case cutframeTX
    case cutframeWJ
    case cutframeYK
    case status
  }

  init(
    gps: Int = 0,
    live: Int = 0,
    real: Int = 0,
    sos: Int = 0,
    preview: Int = 0,
    cloud: Int = 0,
    voice: Int = 0,
    voiceCapture: Int = 0,
    voiceCommand: Int = 0,
    hotPoint: Int = 0,
    travelReport: Int = 0,
    travelReplay: Int = 0,
    front: Int = 0,
    rear: Int = 0,
    incar: Int = 0,
    right: Int = 0,
    full: Int = 0,
    travelAccident: Int = 0,
    dormancyAccident: Int = 0,
    parkReport: Int = 0,
    trafficPolice: Int = 0,
    navigate: Int = 0,
    playTCard: Int = 0,
    playTCardV2: Int = 0,
    tCardAttach: Int = 0,
    remoteTCard: Int = 0,
    remoteTCardAcc: Int = 0,
    remoteSetting: Int = 0,
    reduceRecord: Int = 0,
    reduceImage: Int = 0,
    reduceVideo: Int = 0,
    reduceLive: Int = 0,
    toReduceRecord: Int = 0,
    ledBulb: Int = 0,
    edog: Int = 0,
    streamNum: Int = 0,
    cameraCut: Int = 0,
    simInModel: Int = 0,
    simOutModel: Int = 0,
    obd: Int = 0,
    obdEnabled: Int = 0,
    authService: Int = 0,
    authServiceV3: Int = 0,
    supportIntelligentTransport: Int = 0,
    supportTravelManage: Int = 0,
    supportTrafficImprove: Int = 0,
    supportRemoteService: Int = 0,
    authSetting: Int = 0,
    deviceMosaic: Int = 0,
    eaglePhoto: Int = 0,
    reportException: Int = 0,
    sensitiveAccon: Int = 0,
    cutframeLD: Int = 0,
    cutframeMG: Int = 0,
    cutframeSR: Int = 0,
    cutframeTX: Int = 0,
    cutframeWJ: Int = 0,
    cutframeYK: Int = 0,
    status: Int = 0
  ) {
    self.gps = gps
    self.live = live
    self.real = real
    self.sos = sos
    self.preview = preview
    self.cloud = cloud
    self.voice = voice
    self.voiceCapture = voiceCapture
    self.voiceCommand = voiceCommand
    self.hotPoint = hotPoint
    self.travelReport = travelReport
    self.travelReplay = travelReplay
    self.front = front
    self.rear = rear
    self.incar = incar
    self.right = right
    self.full = full
    self.travelAccident = travelAccident
    self.dormancyAccident = dormancyAccident
    self.parkReport = parkReport
    self.trafficPolice = trafficPolice
    self.navigate = navigate
    self.playTCard = playTCard
    self.playTCardV2 = playTCardV2
    self.tCardAttach = tCardAttach
    self.remoteTCard = remoteTCard
    self.remoteTCardAcc = remoteTCardAcc
    self.remoteSetting = remoteSetting
    self.reduceRecord = reduceRecord
    self.reduceImage = reduceImage
    self.reduceVideo = reduceVideo
    self.reduceLive = reduceLive
    self.toReduceRecord = toReduceRecord
    self.ledBulb = ledBulb
    self.edog = edog
    self.streamNum = streamNum
    self.cameraCut = cameraCut
    self.simInModel = simInModel
    self.simOutModel = simOutModel
    self.obd = obd
    self.obdEnabled = obdEnabled
    self.authService = authService
    self.authServiceV3 = authServiceV3
    self.supportIntelligentTransport = supportIntelligentTransport
    self.supportTravelManage = supportTravelManage
    self.supportTrafficImprove = supportTrafficImprove
    self.supportRemoteService = supportRemoteService
    self.authSetting = authSetting
    self.deviceMosaic = deviceMosaic
    self.eaglePhoto = eaglePhoto
    self.reportException = reportException
    self.sensitiveAccon = sensitiveAccon
    self.cutframeLD = cutframeLD
    self.cutframeMG = cutframeMG
    self.cutframeSR = cutframeSR
    self.cutframeTX = cutframeTX
    self.cutframeWJ = cutframeWJ
    self.cutframeYK = cutframeYK
    self.status = status
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    gps = container.safeDecodeInt(.gps, 0)
    live = container.safeDecodeInt(.live, 0)
    real = container.safeDecodeInt(.real, 0)
    sos = container.safeDecodeInt(.sos, 0)
    preview = container.safeDecodeInt(.preview, 0)
    cloud = container.safeDecodeInt(.cloud, 0)
    voice = container.safeDecodeInt(.voice, 0)
    voiceCapture = container.safeDecodeInt(.voiceCapture, 0)
    voiceCommand = container.safeDecodeInt(.voiceCommand, 0)
    hotPoint = container.safeDecodeInt(.hotPoint, 0)
    travelReport = container.safeDecodeInt(.travelReport, 0)
    travelReplay = container.safeDecodeInt(.travelReplay, 0)
    front = container.safeDecodeInt(.front, 0)
    rear = container.safeDecodeInt(.rear, 0)
    incar = container.safeDecodeInt(.incar, 0)
    right = container.safeDecodeInt(.right, 0)
    full = container.safeDecodeInt(.full, 0)
    travelAccident = container.safeDecodeInt(.travelAccident, 0)
    dormancyAccident = container.safeDecodeInt(.dormancyAccident, 0)
    parkReport = container.safeDecodeInt(.parkReport, 0)
    trafficPolice = container.safeDecodeInt(.trafficPolice, 0)
    navigate = container.safeDecodeInt(.navigate, 0)
    playTCard = container.safeDecodeInt(.playTCard, 0)
    playTCardV2 = container.safeDecodeInt(.playTCardV2, 0)
    tCardAttach = container.safeDecodeInt(.tCardAttach, 0)
    remoteTCard = container.safeDecodeInt(.remoteTCard, 0)
    remoteTCardAcc = container.safeDecodeInt(.remoteTCardAcc, 0)
    remoteSetting = container.safeDecodeInt(.remoteSetting, 0)
    reduceRecord = container.safeDecodeInt(.reduceRecord, 0)
    reduceImage = container.safeDecodeInt(.reduceImage, 0)
    reduceVideo = container.safeDecodeInt(.reduceVideo, 0)
    reduceLive = container.safeDecodeInt(.reduceLive, 0)
    toReduceRecord = container.safeDecodeInt(.toReduceRecord, 0)
    ledBulb = container.safeDecodeInt(.ledBulb, 0)
    edog = container.safeDecodeInt(.edog, 0)
    streamNum = container.safeDecodeInt(.streamNum, 0)
    cameraCut = container.safeDecodeInt(.cameraCut, 0)
    simInModel = container.safeDecodeInt(.simInModel, 0)
    simOutModel = container.safeDecodeInt(.simOutModel, 0)
    obd = container.safeDecodeInt(.obd, 0)
    obdEnabled = container.safeDecodeInt(.obdEnabled, 0)
    authService = container.safeDecodeInt(.authService, 0)
    authServiceV3 = container.safeDecodeInt(.authServiceV3, 0)
    supportIntelligentTransport = container.safeDecodeInt(.supportIntelligentTransport, 0)
    supportTravelManage = container.safeDecodeInt(.supportTravelManage, 0)
    supportTrafficImprove = container.safeDecodeInt(.supportTrafficImprove, 0)
    supportRemoteService = container.safeDecodeInt(.supportRemoteService, 0)
    authSetting = container.safeDecodeInt(.authSetting, 0)
    deviceMosaic = container.safeDecodeInt(.deviceMosaic, 0)
    eaglePhoto = container.safeDecodeInt(.eaglePhoto, 0)
    reportException = container.safeDecodeInt(.reportException, 0)
    sensitiveAccon = container.safeDecodeInt(.sensitiveAccon, 0)
    cutframeLD = container.safeDecodeInt(.cutframeLD, 0)
    cutframeMG = container.safeDecodeInt(.cutframeMG, 0)
    cutframeSR = container.safeDecodeInt(.cutframeSR, 0)
    cutframeTX = container.safeDecodeInt(.cutframeTX, 0)
    cutframeWJ = container.safeDecodeInt(.cutframeWJ, 0)
    cutframeYK = container.safeDecodeInt(.cutframeYK, 0)
    status = container.safeDecodeInt(.status, 0)
  }
}

// "activeStatus": 2,
// "activeTime": "2023-08-02 15:00:13",
// "activeType": 3,
// "cameraTemplate": "",
// "canUsed": true,
// "customer": "autocloud",
// "defaultCamera": "",
// "expireTime": "2026-08-02 15:00:13",
// "iccid": "89860619130000686708",
// "id": "869497051442562",
// "logoUrl": "http://resdoc.spreadwin.com/logo/TuYunHuLian.png",
// "nickname": "",
// "offlineReason": "",
// "onlineCount": 0,
// "onlineStatus": 4,
// "preferredLanguage": "zh-CN",
// "sn": "901453675202562",
// "thumbnail": "",
// "versionType": "M601",
// "warrantyPeriod": 0,
// "watermarkUrl": "http://resdoc.spreadwin.com/logo/xiaojingWaterMark.png",
// "wid": "xiaojing",
// "car": {
//     "brandEname": "",
//     "brandId": 0,
//     "brandImg": "",
//     "brandName": "途观L新能源",
//     "carIcon": "http://ty-obj-test.spreadwin.com/carBrand/1207.png",
//     "carLicense": "京DF2562",
//     "carModel": "大众",
//     "carType": "小汽车",
//     "createTime": "",
//     "engineAutoStart": 0,
//     "id": "0",
//     "licenseUrl": "",
//     "powerType": 0,
//     "source": 0,
//     "tank": 0,
//     "totalMiles": 0,
//     "vin": "",
//     "vinImgUrl": ""
// },
// "gps": {
//     "direct": 0,
//     "lat": 30_538_165,
//     "lon": 104_057_693,
//     "speed": 0,
//     "time": "2024-01-18 11:28:49"
// },
// "obd": {
//   "alert": 0,
//     "alertInfo": [],
//     "commandId": "",
//     "door": 0,
//     "drive": 0,
//     "fuel": {
//       "averageFuel": 0,
//         "instantFuel": 0,
//         "remainFuel": -1,
//         "remainingFuel": 0,
//         "remainingMileage": -1,
//         "totalFuel": 0
//     },
//     "light": 0,
//     "lock": 0,
//     "source": "",
//     "tirePressure": "",
//     "window": 0
// },
// "obd_status": {
//   "averageFuelUsage": 0,
//     "maxInstantFuel": 0,
//     "maxRpm": -1,
//     "obdSn": "",
//     "obdUpdateTime": "",
//     "obdVersion": "",
//     "obdVoltage": -1,
//     "oilLife": -1,
//     "remainFuel": -1,
//     "remainMileage": -1,
//     "status": 4,
//     "tCard": true,
//     "temperature": -1,
//     "totalMiles": 0,
//     "voltage": 1401,
//     "voltageUpdateTime": "2024-01-18 11:28:49"
// },
// "qrcode": {
//   "customer": "autocloud",
//     "customerName": "autocloud",
//     "nonceLostTime": "2026-02-09 16:07:22",
//     "rawUrl": "http://weixin.qq.com/q/02Rt4v1NDTePi1GWl9NFcz",
//     "url": "http://ty-obj-test.spreadwin.cn/qr/20260202/869497051442562ebtcb.jpeg"
// },
// "realtime": {
//   "accuracy": 100,
//     "authIntelligentTransport": 1,
//     "authRemoteService": 1,
//     "authTrafficImprove": 1,
//     "authTravelManage": 1,
//     "cloudVideo": 0,
//     "frontResolution": "HD",
//     "fullResolution": "HD",
//     "incarResolution": "HD",
//     "lastStatusTime": 1_705_548_529_634,
//     "policeStatus": 257,
//     "policeStatusString": "抄牌识别:未开启",
//     "positionType": 2,
//     "rearResolution": "HD",
//     "rightResolution": "HD",
//     "status": 4,
//     "statusChangeTime": 1_705_546_394_238,
//     "tcard": true,
//     "voltage": 1401
// },
// "sim": {
//   "cardType": 0,
//     "flowSettleDay": "",
//     "iccId": "",
//     "isXjCard": false,
//     "thirdUrl": "",
//     "thirdUrlTitle": "",
//     "totalFlow": 0,
//     "unusedFlow": 0,
//     "usedFlow": 0
// }
