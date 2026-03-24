import Foundation

struct MessageResult: Decodable {
  let items: [MessageModel]
  let windowEndUpdateTime: Int?
}

final class MessageAPI {
  static let shared = MessageAPI()

  let client: APIClient

  private init(client: APIClient = APIClient()) {
    self.client = client
  }

  /// 只需要updateTime去同步数据就行了
  func userMessageList(_ updateTime: Int? = nil) async -> MessageResult? {
    return await client.postRequest(
      "/v4/u/user/msg/list", AnyParams(["updateTime": updateTime ?? 0]), true, false
    )
  }

  /// 标记消息为已读
  /// - Parameter msgIds: 消息 ID 数组
  /// - Returns: 空响应
  func read(msgIds: [String]) async -> Empty? {
    // Step 1. 组装消息已读请求参数
    let payload = AnyParams(["msgIds": msgIds])
    // Step 2. 发起消息已读请求并解码返回
    return await client.postRequest(
      "/v4/u/user/msg/read", payload, true, false
    )
  }

  func userReadAll() async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/msg/readAll", Empty(), true, true
    )
  }

  func userDelete(id: String) async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/msg/delete", AnyParams(["id": id]), true, true
    )
  }

  func userDeletePart(ids: [String]) async -> Empty? {
    return await client.postRequest(
      "/v4/u/user/msg/deletePart", AnyParams(["msgIds": ids]), true, true
    )
  }

  // 不需要这个
  // func userUnreadCount(payload: Empty = Empty()) async throws -> MessageUnreadCountData? {
  //   // Step 1. 组装用户未读数量请求参数
  //   // Step 2. 发起用户未读数量请求并解码返回
  //   try await client.request(
  //     .Post, "/v4/u/user/msg/unreadCount", payload
  //   )
  // }

  // func userRead(id: String) async throws -> Empty? {
  //   return try await client.request(
  //     .Post, "/v4/u/user/msg/read", AnyParams(["id": id])
  //   )
  // }
}

struct MessageUnreadCountData: Decodable {
  let all: Int?
  let drive: Int?
  let event: Int?
  let campaign: Int?
  let system: Int?
  let count: Int?
  let unreadCount: Int?

  private enum CodingKeys: String, CodingKey {
    case all
    case drive
    case event
    case campaign
    case system
    case count
    case unreadCount
  }

  init(from decoder: Decoder) throws {
    if let container = try? decoder.singleValueContainer(),
       let value = try? container.decode(Int.self)
    {
      all = value
      drive = nil
      event = nil
      campaign = nil
      system = nil
      count = value
      unreadCount = value
      return
    }
    let container = try decoder.container(keyedBy: CodingKeys.self)
    all = try? container.decodeIfPresent(Int.self, forKey: .all)
    drive = try? container.decodeIfPresent(Int.self, forKey: .drive)
    event = try? container.decodeIfPresent(Int.self, forKey: .event)
    campaign = try? container.decodeIfPresent(Int.self, forKey: .campaign)
    system = try? container.decodeIfPresent(Int.self, forKey: .system)
    count = try? container.decodeIfPresent(Int.self, forKey: .count)
    unreadCount = try? container.decodeIfPresent(Int.self, forKey: .unreadCount)
  }
}
