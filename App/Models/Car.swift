import Foundation

/// 目前车辆模型，在后端没有PK，业务逻辑的时候，要考虑这部分怎么办
struct CarModel: Decodable {
  // vin相关的字段
  let vin: String // 车架号
  let vinSource: Int // vin获取方法 1表示不可修改
  let vinImgUrl: String

  let engineAutoStart: Int // 自动启动 0: 否 1: 是
  let name: String // 车名

  // car相关的
  let carSeriesId: Int
  let carIcon: String // 车辆图标
  let carLicense: String // 车牌号
  let carModel: String // 大众这种
  let carType: String // 小汽车 这种字符串

  // 品牌
  let brandId: Int
  let brandImg: String
  let brandName: String // 品牌名称
  let brandEname: String // 这个是什么？
  let markImgUrl: String // 车模图片

  let powerType: Int // 动力类型

  let licenseUrl: String // 车牌图片
  let source: Int
  let tank: Int // 油箱容量
  let totalMiles: Double // 总里程
  let createTime: String

  private enum CodingKeys: String, CodingKey {
    case vin
    case vinSource
    case vinImgUrl
    case engineAutoStart
    case name
    case carSeriesId
    case carIcon
    case carLicense
    case carModel
    case carType
    case brandId
    case brandImg
    case brandName
    case brandEname
    case markImgUrl
    case powerType
    case licenseUrl
    case source
    case tank
    case totalMiles
    case createTime
  }

  init(from decoder: Decoder) throws {
    let container: KeyedDecodingContainer<CarModel.CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
    carSeriesId = container.safeDecodeInt(.carSeriesId, -1)
    if carSeriesId < 0 {
      throw DecodingError.dataCorruptedError(
        forKey: .carSeriesId,
        in: container,
        debugDescription: "id is empty"
      )
    }

    vin = container.safeDecodeString(.vin, "")
    vinSource = container.safeDecodeInt(.vinSource, 0)
    vinImgUrl = container.safeDecodeString(.vinImgUrl, "")
    engineAutoStart = container.safeDecodeInt(.engineAutoStart, 0)
    name = container.safeDecodeString(.name, "")
    carIcon = container.safeDecodeString(.carIcon, "")
    carLicense = container.safeDecodeString(.carLicense, "")
    carModel = container.safeDecodeString(.carModel, "")
    carType = container.safeDecodeString(.carType, "")
    brandId = container.safeDecodeInt(.brandId, 0)
    brandImg = container.safeDecodeString(.brandImg, "")
    brandName = container.safeDecodeString(.brandName, "")
    brandEname = container.safeDecodeString(.brandEname, "")
    markImgUrl = container.safeDecodeString(.markImgUrl, "")
    powerType = container.safeDecodeInt(.powerType, 0)
    licenseUrl = container.safeDecodeString(.licenseUrl, "")
    source = container.safeDecodeInt(.source, 0)
    tank = container.safeDecodeInt(.tank, 0)
    totalMiles = container.safeDecodeDouble(.totalMiles, 0)
    createTime = container.safeDecodeString(.createTime, "")
  }
}
