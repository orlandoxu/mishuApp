import Foundation

struct FoodMemoryItem: Identifiable, Hashable {
  let id: String
  var name: String
  var cuisine: String
  var pricePerPerson: Int
  var visitedAtMs: Int64
  var rating: Int
  var features: [String]
  var signatureDishes: [String]
  var avoidDishes: [String]
  var review: String
  var photos: [String]
  var lat: Double
  var lng: Double
  var address: String

  var lastVisitedText: String {
    Self.dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(visitedAtMs) / 1000))
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter
  }()
}

extension FoodMemoryItem {
  init(dto: FoodMemoryDTO) {
    id = dto.id
    name = dto.name
    cuisine = dto.category
    pricePerPerson = dto.pricePerPerson
    visitedAtMs = dto.visitedAt
    rating = dto.rating
    features = dto.features
    signatureDishes = dto.signatureDishes
    avoidDishes = dto.avoidDishes
    review = dto.review
    photos = dto.photos
    lat = dto.lat
    lng = dto.lng
    address = dto.address
  }
}

extension FoodMemoryAPI.UpdatePayload {
  init(item: FoodMemoryItem) {
    self.init(
      id: item.id,
      name: item.name,
      category: item.cuisine,
      pricePerPerson: item.pricePerPerson,
      visitedAt: item.visitedAtMs,
      rating: item.rating,
      features: item.features,
      signatureDishes: item.signatureDishes,
      avoidDishes: item.avoidDishes,
      review: item.review,
      photos: item.photos,
      lat: item.lat,
      lng: item.lng,
      address: item.address
    )
  }
}
