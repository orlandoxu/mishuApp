import Foundation

enum CloudAlbumFilter: String, CaseIterable {
  case all = "全部"
  case photo = "只看照片"
  case video = "只看视频"

  var icon: String {
    switch self {
    case .all: return "square.grid.2x2"
    case .photo: return "photo"
    case .video: return "video"
    }
  }

  var typeValues: [Int] {
    switch self {
    case .all: return [] // 空数组代表全部，或者需要根据业务逻辑传所有类型
    case .photo: return [1]
    case .video: return [2]
    }
  }
}

enum CloudAlbumType: String, CaseIterable {
  case local
  case parking
  case deviceSnapshot
  case remoteSnapshot
  case collision
  case sos
  case plate

  var title: String {
    switch self {
    case .local: return "本地相册"
    case .parking: return "停车报警"
    case .deviceSnapshot: return "设备抓拍"
    case .remoteSnapshot: return "远程抓拍"
    case .collision: return "行车碰撞"
    case .sos: return "紧急视频"
    case .plate: return "抄牌提醒"
    }
  }

  var icon: String {
    switch self {
    case .local: return "icon_album_local"
    case .parking: return "icon_album_park"
    case .deviceSnapshot: return "icon_album_snap"
    case .remoteSnapshot: return "icon_album_snap_remote"
    case .collision: return "icon_album_crash"
    case .sos: return "icon_album_sos"
    case .plate: return "icon_album_police"
    }
  }

  func getCount(from data: AlbumData) -> Int {
    switch self {
    case .local: return 0
    case .parking: return (data.parkPhoto?.count ?? 0) + (data.parkVideo?.count ?? 0)
    // 设备抓拍
    case .deviceSnapshot: return (data.voicePhoto?.count ?? 0) + (data.voiceVideo?.count ?? 0)
    // 远程抓拍
    case .remoteSnapshot: return (data.realtimePhoto?.count ?? 0) + (data.realtimeVideo?.count ?? 0)
    case .collision: return (data.lockPhoto?.count ?? 0) + (data.lockVideo?.count ?? 0)
    case .sos: return (data.sosPhoto?.count ?? 0) + (data.sosVideo?.count ?? 0)
    case .plate: return 0
    }
  }

  var albumTypeIds: [Int] {
    getAlbumTypeIds(filter: .all)
  }

  func getAlbumTypeIds(filter: CloudAlbumFilter) -> [Int] {
    let allIds: [Int]
    switch self {
    case .local: return []
    // 停车报警
    case .parking: allIds = [9, 10, 11, 12, 17, 18, 47, 48]
    // 设备抓拍
    case .deviceSnapshot: allIds = [3, 4]
    // 远程抓拍
    case .remoteSnapshot: allIds = [7, 8, 31, 32] // 语音抓拍(3,4) + 实时(7,8) + CRM(31,32)
    // 碰撞报警
    case .collision: allIds = [5, 6, 15, 16, 45, 46, 5010]
    // SOS 报警
    case .sos: allIds = [13, 14]
    // 发现交警
    case .plate: return [19, 20]
    }

    // 根据文档区分图片和视频 ID
    // 简单分类 (偶数/特定ID是视频? 不一定，需要硬编码)
    // 根据文档:
    // 图片: 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 31, 45, 47
    // 视频: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 32, 46, 48, 52, 54, 56, 34

    let photoIds = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 31, 45, 47]
    let videoIds = [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 32, 46, 48, 52, 54, 56, 34]

    switch filter {
    case .all:
      return allIds
    case .photo:
      return allIds.filter { photoIds.contains($0) }
    case .video:
      return allIds.filter { videoIds.contains($0) }
    }
  }

  /// 获取所有云相册类型的 ID 集合
  static var allCloudIds: [Int] {
    var ids: [Int] = []
    for type in CloudAlbumType.allCases {
      if type != .local {
        ids.append(contentsOf: type.albumTypeIds)
      }
    }
    return Array(Set(ids)) // 去重
  }

  /// 根据资源类型 ID 获取对应的相册标题
  static func title(for typeId: Int) -> String {
    for type in CloudAlbumType.allCases {
      if type.albumTypeIds.contains(typeId) {
        return type.title
      }
    }
    // 特殊处理一些可能未包含在预定义分类中的 ID，或者返回默认值
    if [19, 20].contains(typeId) { return "抄牌提醒" } // 虽然 CloudAlbumType 包含了 plate，但这里双重检查
    if [3, 4].contains(typeId) { return "设备抓拍" }

    // 如果找不到，返回未知或者根据文档推断
    return "云相册资源"
  }
}
