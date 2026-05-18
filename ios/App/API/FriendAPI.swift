import Foundation

struct FriendInteractionDTO: Codable {
  let id: String
  let date: String
  let type: String
  let desc: String
}

struct FriendDTO: Codable {
  let id: String
  let name: String
  let shortName: String
  let age: Int
  let gender: String
  let role: String
  let avatarText: String
  let isStarred: Bool
  let starredAt: String?
  let tags: [String]
  let birthday: String?
  let relationship: String?
  let preferences: [String]
  let resources: [String]
  let insight: String
  let interactions: [FriendInteractionDTO]
}

struct FriendListDTO: Codable {
  let items: [FriendDTO]
  let total: Int
  let page: Int
  let pageSize: Int
}

struct FriendInteractionListDTO: Codable {
  let items: [FriendInteractionDTO]
}

final class FriendAPI {
  static let shared = FriendAPI()
  private let client: APIClient

  init(client: APIClient = APIClient()) {
    self.client = client
  }

  func list(keyword: String? = nil, starredOnly: Bool = false, page: Int = 1, pageSize: Int = 100) async -> FriendListDTO? {
    struct ListBody: Encodable {
      let keyword: String
      let starredOnly: Bool
      let page: Int
      let pageSize: Int
    }

    let result: FriendListDTO? = await client.postRequest(
      "/friend/list",
      ListBody(keyword: keyword ?? "", starredOnly: starredOnly, page: page, pageSize: pageSize),
      true,
      false
    )
    return result
  }

  func delete(friendId: String) async -> Bool {
    let result: Empty? = await client.postRequest(
      "/friend/delete",
      AnyParams(["friendId": friendId]),
      true,
      true
    )
    return result != nil
  }

  func listInteractions(friendId: String) async -> [FriendInteractionDTO]? {
    let result: FriendInteractionListDTO? = await client.postRequest(
      "/friend/interactions/list",
      AnyParams(["friendId": friendId]),
      true,
      false
    )
    return result?.items
  }

  func deleteInteraction(interactionId: String) async -> Bool {
    let result: Empty? = await client.postRequest(
      "/friend/interactions/delete",
      AnyParams(["interactionId": interactionId]),
      true,
      true
    )
    return result != nil
  }
}
