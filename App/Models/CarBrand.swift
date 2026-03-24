import Foundation

/// 不要乱改，这个数据结构没问题
/// 你看看我给你日志
/// {"brandId":117,"name":"AC Schnitzer X6","seriesId":2098},{"brandId":117,"name":"AC Schnitzer GR SUPRA","seriesId":5875}
struct CarSeriesModel: Decodable {
  let seriesId: Int
  let name: String
}

/// 这个数据结构不能遍了，必须跟后台保持一致，后台就是这样的
struct CarBrandModel: Decodable {
  let brandId: Int // 这个就是pk
  let brandName: String
  let brandEname: String
  let brandImg: String
  let source: Int
}
