import Foundation

/// 数据结构不用改了，数据结构我已经和后台对接好了
struct MessageModel: Codable {
  /// 后端定义的消息子类型
  enum SubType: Int, Codable, CaseIterable {
    case capture = 1 // 抓拍消息
    case travelReport = 2 // 行程报告消息
    case unbind = 3 // 解绑消息
    case complaint = 4 // 投诉消息
    case deviceException = 5 // 设备异常消息
    case resourceAlert = 6 // 资源异常消息
    case obdAlert = 7 // OBD异常消息
    case notEnoughTime = 8 // 云记录仪时间不足消息
    case trafficPolice = 9 // 发现交警消息(抄牌)
    case shakeAlarm = 10 // 震动报警消息
    case system = 11 // 系统消息
    case campaign = 12 // 活动消息
    case stealAlarm = 13 // 防盗模式消息
    case deviceShutDown = 14 // 设备关机消息
    case sos = 15 // 紧急消息
  }

  let id: String // mongo id
  let userId: String // 消息接收用户 id
  let title: String // 消息标题
  let msgType: String // 消息类型(系统 / 活动 / 记录仪)
  let subType: Int // 消息子类型
  let status: Int // 消息状态(1: 未读, 2: 已读)
  let coverUrl: String // 消息图片 url
  let mediaUrl: String // 消息媒体文件 url
  let schema: String // 消息跳转 schema
  let createAt: Int // 消息创建时间戳
  let updateAt: Int // 消息更新时间戳
  let mediaStatus: Int // 删除情况
  let imei: String // 设备 id

  // TODO: 未来这个init需要删除，因为只有序列化创建一种方式
  init(
    id: String,
    userId: String = "",
    title: String = "",
    msgType: String = "",
    subType: Int = 0,
    status: Int = 0,
    coverUrl: String = "",
    mediaUrl: String = "",
    schema: String = "",
    createAt: Int = 0,
    updateAt: Int = 0,
    mediaStatus: Int = 0,
    imei: String = ""
  ) {
    self.id = id
    self.userId = userId
    self.title = title
    self.msgType = msgType
    self.subType = subType
    self.status = status
    self.coverUrl = coverUrl
    self.mediaUrl = mediaUrl
    self.schema = schema.trimmingCharacters(in: .whitespacesAndNewlines)
    self.createAt = createAt
    self.updateAt = updateAt
    self.mediaStatus = mediaStatus
    self.imei = imei.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // DONE-AI: schema 仅用于路由跳转；媒体渲染由 MessageCell 根据 mediaUrl/coverUrl 决定
  enum MediaKind {
    case none
    case image
    case video
  }

  var mediaKind: MediaKind {
    let media = mediaUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    if !media.isEmpty {
      let pathExtension = URL(string: media)?.pathExtension.lowercased() ?? ""
      if ["mp4", "mov", "m4v"].contains(pathExtension) {
        return .video
      }
      return .image
    }
    if !coverUrl.isEmpty { return .image }
    return .none
  }

  var mediaThumbnailUrl: String {
    coverUrl.isEmpty ? mediaUrl : coverUrl
  }

  var typedSubType: SubType? {
    SubType(rawValue: subType)
  }

  func updatingStatus(_ newStatus: Int) -> MessageModel {
    MessageModel(
      id: id,
      userId: userId,
      title: title,
      msgType: msgType,
      subType: subType,
      status: newStatus,
      coverUrl: coverUrl,
      mediaUrl: mediaUrl,
      schema: schema,
      createAt: createAt,
      updateAt: updateAt,
      mediaStatus: mediaStatus,
      imei: imei
    )
  }

  private enum CodingKeys: String, CodingKey {
    case id, userId, msgType, title, subType, status, coverUrl, mediaUrl, schema, scheme, createAt, updateAt, mediaStatus, imei
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    userId = container.safeDecodeString(.userId, "")
    title = container.safeDecodeString(.title, "")
    msgType = container.safeDecodeString(.msgType, "")
    subType = container.safeDecodeInt(.subType, 0)
    status = container.safeDecodeInt(.status, 0)
    coverUrl = container.safeDecodeString(.coverUrl, "")
    mediaUrl = container.safeDecodeString(.mediaUrl, "")
    let rawSchema = container.safeDecodeString(.schema, "")
    let fallbackSchema = container.safeDecodeString(.scheme, "")
    let pickedSchema = rawSchema.isEmpty ? fallbackSchema : rawSchema
    schema = pickedSchema.trimmingCharacters(in: .whitespacesAndNewlines)
    createAt = container.safeDecodeInt(.createAt, 0)
    updateAt = container.safeDecodeInt(.updateAt, 0)
    mediaStatus = container.safeDecodeInt(.mediaStatus, 0)
    imei = container.safeDecodeString(.imei, "")
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(userId, forKey: .userId)
    try container.encode(title, forKey: .title)
    try container.encode(msgType, forKey: .msgType)
    try container.encode(subType, forKey: .subType)
    try container.encode(status, forKey: .status)
    try container.encode(coverUrl, forKey: .coverUrl)
    try container.encode(mediaUrl, forKey: .mediaUrl)
    try container.encode(schema, forKey: .schema)
    try container.encode(createAt, forKey: .createAt)
    try container.encode(updateAt, forKey: .updateAt)
    try container.encode(mediaStatus, forKey: .mediaStatus)
    try container.encode(imei, forKey: .imei)
  }
}
