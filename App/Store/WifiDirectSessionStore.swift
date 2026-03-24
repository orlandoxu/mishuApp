import Foundation

struct WifiDirectSession: Equatable {
  let imei: String
  let did: String
  let slat: String?
  let lSign: String?
  let spec: Int
  let wakeupMs: Int
  let classCode: String
  let ipaddr: String?
  let port: Int
  let discoveredAt: Date
}

/// Wi-Fi 直连会话缓存：承载 AP discover 结果与连接前置参数。
@MainActor
final class WifiDirectSessionStore: ObservableObject {
  static let shared = WifiDirectSessionStore()

  private enum DocLog {
    static func info(_ message: String) {
      #if DEBUG
        print("[WifiDoc][Discover] \(message)")
      #endif
    }
  }

  @Published private(set) var activeSession: WifiDirectSession?

  private let apManager = XCAVSDKWifiAPManager()
  private var sessionByDid: [String: WifiDirectSession] = [:]
  private var sessionByImei: [String: WifiDirectSession] = [:]

  private init() {}

  func reset() {
    activeSession = nil
    sessionByDid.removeAll()
    sessionByImei.removeAll()
  }

  func session(forDid did: String) -> WifiDirectSession? {
    let key = normalize(did)
    guard !key.isEmpty else { return nil }
    return sessionByDid[key]
  }

  func session(forImei imei: String) -> WifiDirectSession? {
    let key = normalize(imei)
    guard !key.isEmpty else { return nil }
    return sessionByImei[key]
  }

  /// 确保某设备存在可用直连会话；优先复用已 discover 结果，其次用 fallback 数据兜底。
  @discardableResult
  func ensureSessionForImei(
    _ imei: String,
    fallbackDid: String?,
    fallbackSlat: String?
  ) -> Bool {
    let imeiKey = normalize(imei)
    guard !imeiKey.isEmpty else { return false }
    if sessionByImei[imeiKey] != nil { return true }

    let did = normalize(fallbackDid ?? "")
    guard !did.isEmpty else { return false }
    let slat = normalize(fallbackSlat ?? "")
    let session = WifiDirectSession(
      imei: imeiKey,
      did: did,
      slat: slat.isEmpty ? nil : slat,
      lSign: slat.isEmpty ? nil : slat,
      spec: 0,
      wakeupMs: 0,
      classCode: "IPAV",
      ipaddr: nil,
      port: 20190,
      discoveredAt: Date()
    )
    store(session)
    return true
  }

  /// 按文档流程执行 AP discover，拿到 DiscoverModel 后建立本地会话。
  @discardableResult
  func prepareSessionByDiscover(
    imei: String,
    classCode: String = "IPAV",
    port: Int = 20190,
    timeoutMS: Int = 1500
  ) async -> Bool {
    DocLog.info("Step 1 Begin: AP 模式发现 imei=\(imei), classCode=\(classCode), port=\(port), timeoutMS=\(timeoutMS)")
    let imeiKey = normalize(imei)
    guard !imeiKey.isEmpty else { return false }

    let ips = buildCandidateIPs()
    DocLog.info("Step 1 Data: ipCandidates=\(ips)")
    guard !ips.isEmpty else { return false }

    for (index, ip) in ips.enumerated() {
      DocLog.info("Step 2 Begin: 串行扫描 index=\(index), ip=\(ip)")
      let discovered = await discoverAdv(
        ipaddr: ip,
        classCode: classCode,
        port: port,
        timeoutMS: timeoutMS
      )
      DocLog.info("Step 2 End: index=\(index), ip=\(ip), discoveredCount=\(discovered.count)")
      guard let first = discovered.first else { continue }

      let did = normalize(first.did)
      guard !did.isEmpty else { continue }

      let lSignRaw = normalize(first.lSign)
      let slat = lSignRaw.isEmpty ? nil : lSignRaw
      let parsed = parseModelConfig(from: first, classCode: classCode)
      DocLog.info("Step 3 Data: did=\(did), lSignLength=\(lSignRaw.count), ipaddr=\(normalize(first.ipaddr)), lisport=\(first.lisport), spec=\(parsed.spec), wakeupMs=\(parsed.wakeupMs)")
      let session = WifiDirectSession(
        imei: imeiKey,
        did: did,
        slat: slat,
        lSign: lSignRaw.isEmpty ? nil : lSignRaw,
        spec: parsed.spec,
        wakeupMs: parsed.wakeupMs,
        classCode: classCode,
        ipaddr: normalize(first.ipaddr).isEmpty ? nil : normalize(first.ipaddr),
        port: first.lisport > 0 ? Int(first.lisport) : port,
        discoveredAt: Date()
      )
      store(session)
      DocLog.info("Step 3 End: 建立会话成功 imei=\(imeiKey), did=\(did)")
      DocLog.info("Step 1 End: AP 发现成功")
      return true
    }

    DocLog.info("Step 1 End: AP 发现失败，未找到设备")
    return false
  }

  private func store(_ session: WifiDirectSession) {
    let didKey = normalize(session.did)
    let imeiKey = normalize(session.imei)
    sessionByDid[didKey] = session
    sessionByImei[imeiKey] = session
    activeSession = session
  }

  private func discoverAdv(
    ipaddr: String,
    classCode: String,
    port: Int,
    timeoutMS: Int
  ) async -> [DiscoverModel] {
    await withCheckedContinuation { continuation in
      apManager.discoverAdvSync(
        withIpaddr: ipaddr,
        did: nil,
        classCode: classCode,
        port: port,
        addIp: "192.168.42.255",
        timeoutMS: timeoutMS
      ) { response, _ in
        continuation.resume(returning: response)
      }
    }
  }

  private func buildCandidateIPs() -> [String] {
    var list: [String] = ["255.255.255.255", "192.168.42.255"]
    let localIP = normalize(UserGetLocalIPAddr())
    if !localIP.isEmpty {
      list.append(localIP)
      if localIP.hasPrefix("192") || localIP.hasPrefix("172") {
        let segments = localIP.split(separator: ".")
        if segments.count == 4 {
          let subnetBroadcast = "\(segments[0]).\(segments[1]).\(segments[2]).255"
          list.append(subnetBroadcast)
        }
      }
    }

    var dedup: [String] = []
    var visited: Set<String> = []
    for item in list {
      let key = normalize(item)
      if key.isEmpty || visited.contains(key) { continue }
      visited.insert(key)
      dedup.append(key)
    }
    return dedup
  }

  private func parseModelConfig(from model: DiscoverModel, classCode: String) -> (spec: Int, wakeupMs: Int) {
    guard let proto = model.protoBin, !proto.isEmpty else {
      return (spec: 0, wakeupMs: 0)
    }

    guard let conf = try? SkillConf(data: proto) else {
      return (spec: 0, wakeupMs: 0)
    }

    let wakeup = max(0, Int(conf.base.wakeupTimems))
    let normalizedClassCode = normalize(classCode).uppercased()
    var spec: Int = 0
    let mconfList = conf.mconfArray as? [SkillMConf] ?? []

    if let exact = mconfList.first(where: { normalize($0.classCode_p).uppercased() == normalizedClassCode }),
       exact.hasConf
    {
      spec = max(0, Int(exact.conf.spec))
    } else if let fallback = mconfList.first(where: { $0.hasConf }) {
      spec = max(0, Int(fallback.conf.spec))
    }

    return (spec: spec, wakeupMs: wakeup)
  }

  private func normalize(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
  }
}
