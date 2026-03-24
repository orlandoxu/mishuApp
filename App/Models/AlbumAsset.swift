import Foundation

struct AlbumAsset: Decodable, Hashable {
  let id: String
  let taskId: String
  let url: String
  let urlThumb: String
  let camera: Int
  let createTime: Int64
  let pos: [Double]
  let poses: String // 轨迹地址 22358293_113540914_0,22358107_113540799_0 使用逗号作为分割，经纬度除以六位，转换结果为：（22.358293,113.540914），最后的0目前没有用上
  let type: Int
  let mtype: Int
  let mobile: String
  let imei: String
  let location: String
  let uploadSpeed: Int

  private enum CodingKeys: String, CodingKey {
    case id
    case taskId
    case url
    case urlThumb
    case camera
    case createTime
    case pos
    case poses
    case type
    case mtype
    case mobile
    case imei
    case location
    case uploadSpeed
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = container.safeDecodeString(.id, "")
    taskId = container.safeDecodeString(.taskId, "")

    url = container.safeDecodeString(.url, "")
    urlThumb = container.safeDecodeString(.urlThumb, "")

    camera = container.safeDecodeInt(.camera, 0)
    createTime = container.safeDecodeInt64(.createTime, 0)

    if let value = try? container.decodeIfPresent([Double].self, forKey: .pos) {
      pos = value
    } else if let value = try? container.decodeIfPresent([Int].self, forKey: .pos) {
      pos = value.map { Double($0) }
    } else {
      pos = []
    }

    poses = container.safeDecodeString(.poses, "")
    type = container.safeDecodeInt(.type, 0)
    mtype = container.safeDecodeInt(.mtype, 0)
    mobile = container.safeDecodeString(.mobile, "")
    imei = container.safeDecodeString(.imei, "")
    location = container.safeDecodeString(.location, "")
    uploadSpeed = container.safeDecodeInt(.uploadSpeed, 0)
  }
}

extension AlbumAsset {
  var parsedPoses: [CLLocationCoordinate2D] {
    if poses.isEmpty { return [] }
    return poses.components(separatedBy: ",").compactMap { item -> CLLocationCoordinate2D? in
      let parts = item.components(separatedBy: "_")
      guard parts.count >= 2,
            let latInt = Double(parts[0]),
            let lonInt = Double(parts[1])
      else { return nil }
      return CLLocationCoordinate2D(latitude: latInt / 1_000_000, longitude: lonInt / 1_000_000)
    }
  }
}
