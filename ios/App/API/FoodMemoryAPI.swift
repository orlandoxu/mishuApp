import Foundation

struct FoodMemoryDTO: Codable, Identifiable {
  let id: String
  let name: String
  let category: String
  let pricePerPerson: Int
  let visitedAt: Int64
  let rating: Int
  let features: [String]
  let signatureDishes: [String]
  let avoidDishes: [String]
  let review: String
  let photos: [String]
  let lat: Double
  let lng: Double
  let address: String
}

struct FoodMemoryListDTO: Codable {
  let items: [FoodMemoryDTO]
  let total: Int
  let page: Int
  let pageSize: Int
}

struct FoodMemoryMonthCountDTO: Codable {
  let month: String
  let count: Int
}

struct FoodMemoryMonthListDTO: Codable {
  let items: [FoodMemoryMonthCountDTO]
}

struct FoodMemoryCategoryListDTO: Codable {
  let items: [String]
}

final class FoodMemoryAPI {
  static let shared = FoodMemoryAPI()
  private let client: APIClient

  init(client: APIClient = APIClient()) {
    self.client = client
  }

  func list(category: String? = nil, month: String? = nil, page: Int = 1, pageSize: Int = 100) async -> FoodMemoryListDTO? {
    struct ListBody: Encodable {
      let category: String
      let month: String
      let page: Int
      let pageSize: Int
    }

    let result: FoodMemoryListDTO? = await client.postRequest(
      "/food-memory/list",
      ListBody(category: category ?? "", month: month ?? "", page: page, pageSize: pageSize),
      true,
      false
    )
    return result
  }

  func categories() async -> [String]? {
    let result: FoodMemoryCategoryListDTO? = await client.getRequest("/food-memory/categories", Empty(), true, false)
    return result?.items
  }

  func months() async -> [FoodMemoryMonthCountDTO]? {
    let result: FoodMemoryMonthListDTO? = await client.getRequest("/food-memory/months", Empty(), true, false)
    return result?.items
  }

  struct UpsertPayload: Encodable {
    let name: String
    let category: String
    let pricePerPerson: Int
    let visitedAt: Int64
    let rating: Int
    let features: [String]
    let signatureDishes: [String]
    let avoidDishes: [String]
    let review: String
    let photos: [String]
    let lat: Double
    let lng: Double
    let address: String
  }

  struct UpdatePayload: Encodable {
    let id: String
    let name: String
    let category: String
    let pricePerPerson: Int
    let visitedAt: Int64
    let rating: Int
    let features: [String]
    let signatureDishes: [String]
    let avoidDishes: [String]
    let review: String
    let photos: [String]
    let lat: Double
    let lng: Double
    let address: String
  }

  func create(payload: UpsertPayload) async -> FoodMemoryDTO? {
    await client.postRequest("/food-memory/create", payload, true, true)
  }

  func update(payload: UpdatePayload) async -> FoodMemoryDTO? {
    await client.postRequest("/food-memory/update", payload, true, true)
  }

  func delete(id: String) async -> Bool {
    let result: Empty? = await client.postRequest("/food-memory/delete", AnyParams(["id": id]), true, true)
    return result != nil
  }
}
