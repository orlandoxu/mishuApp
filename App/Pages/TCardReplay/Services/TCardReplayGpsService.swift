import Foundation

/// T 卡回放轨迹点（用于地图和时间轴联动）。
struct TCardReplayGpsPoint: Equatable {
  let timeMs: Int64
  let latitude: Double
  let longitude: Double
  let direction: Double
}

/// 按“设备 + 日期”拉取历史 GPS 点，并转换成回放地图可用模型。
actor TCardReplayGpsService {
  nonisolated static let shared = TCardReplayGpsService()

  enum ServiceError: LocalizedError {
    case missingLoginInfo
    case initializeFailed
    case requestFailed(String)

    var errorDescription: String? {
      switch self {
      case .missingLoginInfo:
        return "缺少轨迹鉴权信息"
      case .initializeFailed:
        return "轨迹SDK初始化失败"
      case let .requestFailed(message):
        return message.isEmpty ? "轨迹请求失败" : message
      }
    }
  }

  private struct AuthSnapshot: Equatable {
    let userId: String
    let mobile: String
    let email: String
    let accessTokenXC: String
    let clientId: String
    let clientSecret: String
    let host: String
  }

  private var initializedAuth: AuthSnapshot?

  /// 拉取某一天的历史轨迹点（`dayStartMs` 为当天 00:00:00 毫秒时间戳）。
  func fetchHistoryPoints(did: String, dayStartMs: Int64) async throws -> [TCardReplayGpsPoint] {
    guard did.isEmpty == false else { return [] }
    try await ensureNetworkContextReady()

    let startSec = Int(dayStartMs / 1000)
    let endSec = Int((dayStartMs + 86_399_000) / 1000)
    let pageSize = 500
    let maxPages = 20

    var page = 1
    var merged: [TCardReplayGpsPoint] = []

    while page <= maxPages {
      let response = try await requestHistoryPage(
        did: did,
        page: page,
        pageSize: pageSize,
        startTimeSec: startSec,
        endTimeSec: endSec
      )
      let rows = response.listArray as? [GpsGetHistoryDateList] ?? []
      if rows.isEmpty { break }

      merged.append(contentsOf: rows.compactMap(parseGpsPoint))

      let total = Int(response.total)
      if total > 0, merged.count >= total { break }
      if rows.count < pageSize { break }

      page += 1
    }

    return merged.sorted(by: { $0.timeMs < $1.timeMs })
  }

  /// 初始化 NetLib 的鉴权上下文（同一账号重复调用会自动复用）。
  private func ensureNetworkContextReady() async throws {
    let snapshot = try await MainActor.run { () -> AuthSnapshot in
      guard
        let user = SelfStore.shared.selfUser,
        let info = user.userInfoXC
      else {
        throw ServiceError.missingLoginInfo
      }

      return AuthSnapshot(
        userId: user.userId,
        mobile: user.mobile,
        email: user.email,
        accessTokenXC: info.accessTokenXC,
        clientId: info.clientId,
        clientSecret: info.clientSecret,
        host: info.iotgw
      )
    }

    if initializedAuth == snapshot { return }

    let ok = await MainActor.run {
      XCNetworkTool.initialize(withClientID: snapshot.clientId, clientSecretKey: snapshot.clientSecret)
    }
    guard ok else { throw ServiceError.initializeFailed }

    await MainActor.run {
      XCNetworkTool.showLog(false)
      XCNetworkTool.hostAddressSet(snapshot.host)
      XCNetworkTool.tokenSet(snapshot.accessTokenXC, refreshToken: snapshot.accessTokenXC)
      XCNetworkTool.userInfoSet(snapshot.mobile, email: snapshot.email, userid: snapshot.userId)
      XCNetworkTool.setNeedLocal(false)
    }

    initializedAuth = snapshot
  }

  /// 请求某一页历史 GPS 数据。
  private func requestHistoryPage(
    did: String,
    page: Int,
    pageSize: Int,
    startTimeSec: Int,
    endTimeSec: Int
  ) async throws -> GpsGetHistoryDateResp {
    try await withCheckedThrowingContinuation { continuation in
      XCNetworkTool.xcGpsGetHistoryDate(
        withDid: did,
        sDid: nil,
        page: page,
        pageSize: pageSize,
        startTime: startTimeSec,
        endTime: endTimeSec
      ) { response, error in
        if let error, error.isEmpty == false {
          continuation.resume(throwing: ServiceError.requestFailed(error))
          return
        }
        guard let response else {
          continuation.resume(throwing: ServiceError.requestFailed("轨迹返回为空"))
          return
        }
        continuation.resume(returning: response)
      }
    }
  }

  /// 解析服务端轨迹点，自动处理时间单位和经纬度字段优先级。
  private func parseGpsPoint(_ model: GpsGetHistoryDateList) -> TCardReplayGpsPoint? {
    guard model.hasLnglat, let lnglat = model.lnglat else { return nil }

    let longitude = parseCoordinate(
      preferred: lnglat.glng,
      fallback: lnglat.lng
    )
    let latitude = parseCoordinate(
      preferred: lnglat.glat,
      fallback: lnglat.lat
    )
    guard isValidCoordinate(latitude: latitude, longitude: longitude) else { return nil }

    let timeMs = normalizeTimestampMs(Int64(model.time) ?? 0)
    guard timeMs > 0 else { return nil }

    return TCardReplayGpsPoint(
      timeMs: timeMs,
      latitude: latitude,
      longitude: longitude,
      direction: Double(model.drct) ?? 0
    )
  }

  /// 时间戳统一转毫秒（兼容秒/毫秒两种格式）。
  private func normalizeTimestampMs(_ value: Int64) -> Int64 {
    if value <= 0 { return 0 }
    if value > 1_500_000_000_000 { return value }
    if value > 1_500_000_000 { return value * 1000 }
    return value * 1000
  }

  /// 优先使用主字段，缺失时回退到备用字段。
  private func parseCoordinate(preferred: String, fallback: String) -> Double {
    if let preferredValue = Double(preferred), preferredValue != 0 {
      return preferredValue
    }
    return Double(fallback) ?? 0
  }

  /// 基础经纬度校验，避免异常点污染地图。
  private func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
    if latitude == 0 || longitude == 0 { return false }
    if latitude < -90 || latitude > 90 { return false }
    if longitude < -180 || longitude > 180 { return false }
    return true
  }
}
