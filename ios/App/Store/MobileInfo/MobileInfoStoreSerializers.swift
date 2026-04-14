import Foundation

@MainActor
extension AppStateStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    [
      "pendingLinkURLString": pendingLinkURLString ?? "",
      "bootstrapFinished": bootstrapFinished,
      "rootViewReady": rootViewReady,
      "userInfoRefreshed": userInfoRefreshed,
      "messageSynced": messageSynced,
      "canJumpPendingLink": canJumpPendingLink,
    ]
  }
}

@MainActor
extension SelfStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    let userState: [String: Any]
    if let selfUser {
      userState = [
        "userId": selfUser.userId,
        "mobile": selfUser.mobile,
        "nickname": selfUser.nickname,
        "preferredLanguage": selfUser.preferredLanguage,
        "avgSpeed": selfUser.avgSpeed,
        "totalMiles": selfUser.totalMiles,
        "totalTimeUsing": selfUser.totalTimeUsing,
        "isTester": selfUser.isTester,
        "isSetPassword": selfUser.isSetPassword,
      ]
    } else {
      userState = [:]
    }

    return [
      "isLoggedIn": isLoggedIn,
      "tokenExists": token?.isEmpty == false,
      "isLoading": isLoading,
      "errorMessage": errorMessage ?? "",
      "user": userState,
    ]
  }
}

@MainActor
extension MessageStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    let unreadCount = allMessages.reduce(into: 0) { count, message in
      if message.status == 1 {
        count += 1
      }
    }

    let unreadDotCount = allMessages.reduce(into: 0) { count, message in
      if shouldShowUnreadDot(for: message) {
        count += 1
      }
    }

    let typeCount = Dictionary(grouping: allMessages, by: \.msgType).mapValues(\.count)

    // 只上报最新10条消息，避免appState体积过大。
    let latestMessages = allMessages
      .sorted {
        if $0.updateAt == $1.updateAt {
          return $0.createAt > $1.createAt
        }
        return $0.updateAt > $1.updateAt
      }
      .prefix(10)

    let latestMessagesSnapshot = latestMessages.map { message in
      [
        "id": message.id,
        "userId": message.userId,
        "title": message.title,
        "msgType": message.msgType,
        "subType": message.subType,
        "status": message.status,
        "coverUrl": message.coverUrl,
        "mediaUrl": message.mediaUrl,
        "schema": message.schema,
        "createAt": message.createAt,
        "updateAt": message.updateAt,
        "mediaStatus": message.mediaStatus,
        "imei": message.imei,
      ] as [String: Any]
    }

    return [
      "isSyncing": isSyncing,
      "errorMessage": errorMessage ?? "",
      "totalCount": allMessages.count,
      "unreadCount": unreadCount,
      "unreadDotCount": unreadDotCount,
      "unreadRecorderDeviceIds": Array(unreadRecorderDeviceIds()).sorted(),
      "typeCount": typeCount,
      "latestMessagesLimit": 10,
      "latestMessages": latestMessagesSnapshot,
    ]
  }
}

@MainActor
extension BindingStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    [
      "bindingType": bindingType.mobileInfoValue,
      "imeiText": imeiText,
      "snText": snText,
      "licensePlate": licensePlate,
      "province": province,
      "fullLicense": fullLicense,
      "vinText": vinText,
      "vinImg": vinImg,
      "carBrandName": carBrandName,
      "carSeriesName": carSeriesName,
      "seriesId": seriesId,
      "totalMiles": totalMiles,
      "powerType": powerType,
      "engineAutoStart": engineAutoStart,
      "isChecking": isChecking,
      "isObdDevice": isObdDevice,
      "chipId": chipId,
      "obdSn": obdSn,
      "appPlatform": appPlatform,
      "plateRegion": plateRegion,
      "needVinPhoto": needVinPhoto,
      "allSteps": allSteps,
      "currentStep": currentStep,
      "totalStepCount": totalStepCount,
      "canSubmitManual": canSubmitManual,
    ]
  }
}

@MainActor
extension VehiclesStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    let vehicleStateList: [[String: Any]] = vehicles.map { vehicle in
      [
        "imei": vehicle.imei,
        "sn": vehicle.sn,
        "wid": vehicle.wid,
        "nickname": vehicle.nickname,
        "versionType": vehicle.versionType,
        "activeStatus": vehicle.activeStatus,
        "activeTime": vehicle.activeTime,
        "bindTime": vehicle.bindTime,
        "canUsed": vehicle.canUsed,
        "onlineStatus": vehicle.onlineStatus,
        "onlineStatusText": vehicle.onlineStatusText,
        "offlineReason": vehicle.offlineReason,
        "deviceExpireTime": vehicle.deviceExpireTime,
        "did": vehicle.did,
        "xcLocalSlat": vehicle.xcLocalSlat,
        "gps": serializeGPSModel(vehicle.gps),
        "realtime": serializeRealtimeModel(vehicle.realtime),
        "tripListCount": vehicle.tripList.count,
        "hasTripStats": vehicle.tripStats != nil,
        "travelReportCount": vehicle.travelReport?.count ?? 0,
      ]
    }

    let latestGPSState = latestGPSData.mapValues { gps in
      [
        "imei": gps.imei,
        "latitude": gps.latitude,
        "longitude": gps.longitude,
        "speed": gps.speed,
        "direction": gps.direction,
        "timestamp": gps.timestamp,
      ] as [String: Any]
    }

    return [
      "isLoading": isLoading,
      "errorMessage": errorMessage ?? "",
      "vehicleCount": vehicles.count,
      "vehicles": vehicleStateList,
      "hashVehiclesCount": hashVehicles.count,
      "vehicleDetailImei": vehicleDetailImei ?? "",
      "liveImei": liveImei ?? "",
      "deviceOnlineStatus": deviceOnlineStatus,
      "latestGPSData": latestGPSState,
      "vehicleDetailTripsState": [
        "pageByImei": vehicleDetailTripsState.pageByImei,
        "hasMoreByImei": vehicleDetailTripsState.hasMoreByImei,
        "fetchingImeiSet": Array(vehicleDetailTripsState.fetchingImeiSet).sorted(),
      ],
    ]
  }

  private func serializeGPSModel(_ gps: GPSModel?) -> [String: Any] {
    guard let gps else { return [:] }
    return [
      "lat": gps.lat,
      "lon": gps.lon,
      "speed": gps.speed,
      "direct": gps.direct,
      "time": gps.time,
    ]
  }

  private func serializeRealtimeModel(_ realtime: VehicleRealtimeModel?) -> [String: Any] {
    guard let realtime else { return [:] }
    return [
      "accuracy": realtime.accuracy,
      "authTravelManage": realtime.authTravelManage,
      "generateTravelReport": realtime.generateTravelReport,
      "cloudVideo": realtime.cloudVideo,
      "lastStatusTime": realtime.lastStatusTime,
      "policeStatus": realtime.policeStatus,
      "policeStatusString": realtime.policeStatusString,
      "positionType": realtime.positionType,
      "status": realtime.status,
      "statusChangeTime": realtime.statusChangeTime,
      "tcard": realtime.tcard,
      "voltage": realtime.voltage,
    ]
  }
}

@MainActor
extension WebSocketStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    [
      "status": status.mobileInfoValue,
      "isNetworkReachable": isNetworkReachable,
      "isAuthenticated": isAuthenticated,
      "notice": notice ?? "",
      "lastConnectedAt": Int64(lastConnectedAt?.timeIntervalSince1970 ?? 0),
      "lastMessageAt": Int64(lastMessageAt?.timeIntervalSince1970 ?? 0),
    ]
  }
}

@MainActor
extension TemplateStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    let templateState = templates.map { template in
      [
        "c": template.c ?? "",
        "cmd": template.cmd ?? "",
        "item": template.item ?? "",
        "type": template.type,
        "icon": template.icon ?? "",
        "source": template.source ?? "",
        "show": template.show ?? -1,
        "describe": template.describe ?? "",
      ] as [String: Any]
    }

    let settingState = settings.mapValues { item in
      [
        "c": item.c ?? "",
        "v": item.v ?? "",
        "s": item.s ?? "",
        "l": item.l ?? [],
        "r": item.r ?? "",
      ] as [String: Any]
    }

    let reasonState = reasons.map { reason in
      [
        "r": reason.r ?? "",
        "e": reason.e ?? "",
        "msg": reason.msg,
        "type": reason.type,
        "appPath": reason.appPath ?? "",
        "miniPath": reason.miniPath ?? "",
        "params": reason.params ?? [:],
      ] as [String: Any]
    }

    let errorState = errors.map { error in
      [
        "r": error.r ?? "",
        "e": error.e ?? "",
        "msg": error.msg,
        "type": error.type,
        "appPath": error.appPath ?? "",
        "miniPath": error.miniPath ?? "",
        "params": error.params ?? [:],
      ] as [String: Any]
    }

    return [
      "currentImei": currentImei ?? "",
      "isLoading": isLoading,
      "errorMessage": errorMessage ?? "",
      "templateCount": templates.count,
      "templates": templateState,
      "settingCount": settings.count,
      "settings": settingState,
      "reasonCount": reasons.count,
      "reasons": reasonState,
      "errorCount": errors.count,
      "errors": errorState,
    ]
  }
}

@MainActor
extension WifiStore: MobileInfoStateSerializable {
  func serializeForMobileInfo() -> [String: Any] {
    let currentDeviceInfo: [String: Any]
    if let deviceInfo {
      currentDeviceInfo = [
        "imei": deviceInfo.imei ?? "",
        "sn": deviceInfo.sn ?? "",
        "chipId": deviceInfo.chipId ?? "",
        "obdSn": deviceInfo.obdSn ?? "",
        "isObdDevice": deviceInfo.isObdDevice ?? false,
      ]
    } else {
      currentDeviceInfo = [:]
    }

    return [
      "currentSSID": currentSSID ?? "",
      "targetWifiPrefix": targetWifiPrefix,
      "isTargetWifiConnected": isTargetWifiConnected,
      "deviceInfo": currentDeviceInfo,
    ]
  }
}

private extension BindingType {
  var mobileInfoValue: String {
    switch self {
    case .manual:
      return "manual"
    case .qrCode:
      return "qrCode"
    case .wifi:
      return "wifi"
    }
  }
}

private extension WebsocketStatus {
  var mobileInfoValue: String {
    switch self {
    case .idle:
      return "idle"
    case .connecting:
      return "connecting"
    case .connected:
      return "connected"
    case .disconnected:
      return "disconnected"
    case let .reconnecting(attempt):
      return "reconnecting(\(attempt))"
    case .suspended:
      return "suspended"
    case let .failed(message):
      return "failed(\(message))"
    }
  }
}
