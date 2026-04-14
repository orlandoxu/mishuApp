import Foundation

struct GPSModel: Decodable {
  let direct: Int
  let lat: Int
  let lon: Int
  let speed: Int
  let time: Int64

  var latitude: Double {
    Double(lat) / 1_000_000
  }

  var longitude: Double {
    Double(lon) / 1_000_000
  }

  private enum CodingKeys: String, CodingKey {
    case direct
    case lat
    case lon
    case speed
    case time
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    direct = container.safeDecodeInt(.direct, 0)
    lat = container.safeDecodeInt(.lat, 0)
    lon = container.safeDecodeInt(.lon, 0)
    speed = container.safeDecodeInt(.speed, 0)
    time = container.safeDecodeInt64(.time, 0)
  }
}
